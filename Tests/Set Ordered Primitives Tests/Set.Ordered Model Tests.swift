import Set_Ordered_Primitives
import Set_Primitive
import Hash_Table_Primitives_Test_Support
public import Buffer_Primitives_Test_Support
import Hash_Primitives
import Buffer_Primitive
import Buffer_Linear_Primitive
import Storage_Primitive
import Storage_Contiguous_Primitives
import Memory_Heap_Primitives
import Memory_Allocator_Primitive
import Shared_Primitive
import Index_Primitives
import Tagged_Primitives_Standard_Library_Integration
import Ordinal_Primitives_Standard_Library_Integration
import Testing

// The W3 ordered-set model suite (arc-2): the set streams PLUS the order-facing
// door — `index(of:)` is audited against the model position for every live
// member, every op, and order is re-proven after every removal (backward-shift,
// not tombstones: the GOAL's order-preservation oracle). Both columns; the
// Shared lane is the sibling fleet with refcounted censused members
// (end-of-scope multiset exactness). Shape constraint: B10.

private typealias HeapStorage<E: ~Copyable> =
    Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>

private typealias OrderedColumn<E: Hash.Key & ~Copyable> =
    Hash.Indexed<Buffer<HeapStorage<E>>.Linear>

private typealias MoveOrdered<E: Hash.Key & ~Copyable> = Set<OrderedColumn<E>>.Ordered
private typealias CoWOrdered<E: Hash.Key & SendableMetatype> = Set<Shared<E, OrderedColumn<E>>>.Ordered

// MARK: - Fixtures (the hoisted move-only element + the refcounted fleet member)

extension Model.Element.Tracked: @retroactive Hash.`Protocol` {
    public borrowing func hash(into hasher: inout Hasher) {
        hasher.combine(group)
    }

    public static func == (lhs: borrowing Model.Element.Tracked, rhs: borrowing Model.Element.Tracked) -> Bool {
        lhs.id == rhs.id
    }
}

private final class Member {
    let id: Int
    let group: Int
    let serial: Int
    private let census: Model.Census

    init(id: Int, group: Int, census: Model.Census) {
        self.id = id
        self.group = group
        self.census = census
        self.serial = census.mint()
    }

    deinit {
        census.record(death: serial)
    }
}

extension Member: Hash.`Protocol` {
    borrowing func hash(into hasher: inout Hasher) {
        hasher.combine(group)
    }

    static func == (lhs: borrowing Member, rhs: borrowing Member) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - The reference model: insertion-ordered membership

private struct Reference {
    var members: [(id: Int, group: Int)] = []
    var ids: Swift.Set<Int> = []
    var graveyard: [(id: Int, group: Int)] = []

    mutating func append(id: Int, group: Int) {
        members.append((id, group))
        ids.insert(id)
    }

    mutating func remove(at index: Int) {
        let member = members.remove(at: index)
        ids.remove(member.id)
        retire(member)
    }

    mutating func removeAll() {
        for member in members.prefix(4) { retire(member) }
        members.removeAll()
        ids.removeAll()
    }

    private mutating func retire(_ member: (id: Int, group: Int)) {
        graveyard.append(member)
        if graveyard.count > 8 {
            graveyard.removeFirst(graveyard.count - 8)
        }
    }
}

// MARK: - The direct move-only stream (order + position doors)

private struct DirectStream: ~Copyable {
    var set: MoveOrdered<Model.Element.Tracked>
    var model = Reference()
    var rng: Model.Random
    var verdict: Model.Verdict
    var nextID = 0
    let collisionDivisor = 4
    let census: Model.Census

    init(seed: UInt64, census: Model.Census) {
        var rng = Model.Random(seed: seed)
        self.set = MoveOrdered<Model.Element.Tracked>(
            minimumCapacity: Index<Model.Element.Tracked>.Count(UInt(rng.below(17)))
        )
        self.rng = rng
        self.verdict = Model.Verdict(seed: seed)
        self.census = census
    }

    mutating func freshID() -> (id: Int, group: Int) {
        let minted = (nextID, nextID / collisionDivisor)
        nextID += 1
        return minted
    }

    func probe(_ member: (id: Int, group: Int)) -> Model.Element.Tracked {
        Model.Element.Tracked(id: member.id, group: member.group, census: census)
    }

    mutating func insertFresh() {
        let minted = freshID()
        verdict.record("insert id=\(minted.id) g=\(minted.group)")
        if let rejected = set.insert(probe(minted)) {
            verdict.diverged(["insert of fresh id \(rejected.id) was rejected as a duplicate"])
        } else {
            model.append(id: minted.id, group: minted.group)
        }
    }

    mutating func insertDuplicate() {
        let pick = model.members[rng.below(model.members.count)]
        verdict.record("dup id=\(pick.id)")
        if let rejected = set.insert(probe(pick)) {
            if rejected.id != pick.id {
                verdict.diverged(["duplicate hand-back id \(rejected.id), expected \(pick.id)"])
            }
        } else {
            verdict.diverged(["duplicate id \(pick.id) was inserted as fresh"])
        }
    }

    mutating func removePresent() {
        let index = rng.below(model.members.count)
        let pick = model.members[index]
        verdict.record("remove id=\(pick.id) @\(index)")
        if let removed = set.remove(probe(pick)) {
            if removed.id != pick.id {
                verdict.diverged(["remove(id \(pick.id)) returned id \(removed.id)"])
            }
            model.remove(at: index)
        } else {
            verdict.diverged(["remove(id \(pick.id)) found nothing for a live member"])
        }
    }

    mutating func removeAbsent() {
        let minted = freshID()
        verdict.record("absent id=\(minted.id)")
        if let removed = set.remove(probe(minted)) {
            verdict.diverged(["remove of never-inserted id \(minted.id) returned id \(removed.id)"])
        }
    }

    mutating func containsHit() {
        let pick = model.members[rng.below(model.members.count)]
        verdict.record("has id=\(pick.id)")
        if !set.contains(probe(pick)) {
            verdict.diverged(["live id \(pick.id) is not contained"])
        }
    }

    mutating func indexHit() {
        let index = rng.below(model.members.count)
        let pick = model.members[index]
        verdict.record("idx id=\(pick.id) @\(index)")
        let position = set.index(of: probe(pick))
        if position != Index<Model.Element.Tracked>(Ordinal(UInt(index))) {
            verdict.diverged(["index(of: id \(pick.id)): \(String(describing: position)), model \(index)"])
        }
    }

    mutating func indexMiss() {
        let minted = freshID()
        verdict.record("idx-miss id=\(minted.id)")
        let position = set.index(of: probe(minted))
        if position != nil {
            verdict.diverged(["index(of:) resolved a never-inserted id \(minted.id): \(String(describing: position))"])
        }
    }

    mutating func walkOrder() {
        verdict.record("walk \(model.members.count)")
        var seen: [Int] = []
        set.forEach { (member: borrowing Model.Element.Tracked) in seen.append(member.id) }
        let expected = model.members.map { $0.id }
        if seen != expected {
            verdict.diverged(["forEach walked \(seen), model insertion order \(expected)"])
        }
    }

    mutating func wipe() {
        let keep = rng.chance(50)
        verdict.record("wipe keep=\(keep)")
        set.removeAll(keepingCapacity: keep)
        model.removeAll()
    }

    /// Order + the position door, every op: every member's `index(of:)` equals
    /// its model position (order preservation after every backward-shift removal).
    func audit() -> [String] {
        var findings: [String] = []
        if set.count != Index<Model.Element.Tracked>.Count(UInt(model.members.count)) {
            findings.append("count: set \(set.count), model \(model.members.count)")
        }
        var seen: [Int] = []
        set.forEach { (member: borrowing Model.Element.Tracked) in seen.append(member.id) }
        let expected = model.members.map { $0.id }
        if seen != expected {
            findings.append("order: set \(seen), model \(expected)")
        }
        for (offset, member) in model.members.enumerated() {
            let position = set.index(of: probe(member))
            if position != Index<Model.Element.Tracked>(Ordinal(UInt(offset))) {
                findings.append("index(of: id \(member.id)): \(String(describing: position)), model \(offset)")
            }
        }
        for retired in model.graveyard where !model.ids.contains(retired.id) {
            if set.contains(probe(retired)) {
                findings.append("retired id \(retired.id) is still reachable")
            }
        }
        return findings
    }

    mutating func step() {
        var branch = rng.below(100)
        if model.members.isEmpty, branch >= 30, branch < 92 { branch = 0 }

        switch branch {
        case 0..<30: insertFresh()
        case 30..<38: insertDuplicate()
        case 38..<58: removePresent()
        case 58..<62: removeAbsent()
        case 62..<72: containsHit()
        case 72..<82: indexHit()
        case 82..<86: indexMiss()
        case 86..<92: walkOrder()
        default: wipe()
        }
    }

    mutating func run() {
        let operations = Model.operations(default: 800)
        var op = 0
        while op < operations, verdict.isClean {
            step()
            if Model.shouldAudit(op: op, of: operations) {
                verdict.diverged(audit())
            }
            op += 1
        }
    }

    consuming func finish() -> Model.Verdict {
        verdict
    }
}

private func runDirectStream(seed: UInt64) -> Model.Verdict {
    let census = Model.Census()
    var stream = DirectStream(seed: seed, census: census)
    stream.run()
    var verdict = stream.finish()  // the set dies here

    if !census.isExact {
        verdict.findings.append(
            "teardown multiset broken: \(census.born.count) born vs \(census.died.count) died"
        )
    }
    return verdict
}

// MARK: - The Shared (CoW) sibling fleet

private struct FleetStream {
    var siblings: [CoWOrdered<Member>]
    var models: [Reference]
    var rng: Model.Random
    var verdict: Model.Verdict
    var nextID = 0
    let collisionDivisor = 4
    let census: Model.Census

    init(seed: UInt64, census: Model.Census) {
        var rng = Model.Random(seed: seed)
        self.siblings = [CoWOrdered<Member>(
            minimumCapacity: Index<Member>.Count(UInt(rng.below(9)))
        )]
        self.models = [Reference()]
        self.rng = rng
        self.verdict = Model.Verdict(seed: seed)
        self.census = census
    }

    mutating func freshID() -> (id: Int, group: Int) {
        let minted = (nextID, nextID / collisionDivisor)
        nextID += 1
        return minted
    }

    func probe(_ member: (id: Int, group: Int)) -> Member {
        Member(id: member.id, group: member.group, census: census)
    }

    mutating func fork() {
        let source = rng.below(siblings.count)
        verdict.record("fork ←\(source) (\(siblings.count + 1) siblings)")
        siblings.append(siblings[source])
        models.append(models[source])
    }

    mutating func drop() {
        let target = rng.below(siblings.count)
        verdict.record("drop \(target)")
        siblings.remove(at: target)
        models.remove(at: target)
    }

    mutating func insertFresh(into target: Int) {
        let minted = freshID()
        verdict.record("insert[\(target)] id=\(minted.id) g=\(minted.group)")
        if let rejected = siblings[target].insert(probe(minted)) {
            verdict.diverged(["insert of fresh id \(rejected.id) was rejected as a duplicate"])
        } else {
            models[target].append(id: minted.id, group: minted.group)
        }
    }

    mutating func removePresent(from target: Int) {
        let index = rng.below(models[target].members.count)
        let pick = models[target].members[index]
        verdict.record("remove[\(target)] id=\(pick.id) @\(index)")
        if let removed = siblings[target].remove(probe(pick)) {
            if removed.id != pick.id {
                verdict.diverged(["remove(id \(pick.id)) returned id \(removed.id)"])
            }
            models[target].remove(at: index)
        } else {
            verdict.diverged(["remove(id \(pick.id)) found nothing on sibling \(target)"])
        }
    }

    mutating func indexHit(on target: Int) {
        let index = rng.below(models[target].members.count)
        let pick = models[target].members[index]
        verdict.record("idx[\(target)] id=\(pick.id) @\(index)")
        let position = siblings[target].index(of: probe(pick))
        if position != Index<Member>(Ordinal(UInt(index))) {
            verdict.diverged(["index(of: id \(pick.id)) on sibling \(target): \(String(describing: position)), model \(index)"])
        }
    }

    mutating func containsHit(on target: Int) {
        let pick = models[target].members[rng.below(models[target].members.count)]
        verdict.record("has[\(target)] id=\(pick.id)")
        if !siblings[target].contains(probe(pick)) {
            verdict.diverged(["live id \(pick.id) is not contained on sibling \(target)"])
        }
    }

    mutating func walkOrder(on target: Int) {
        verdict.record("walk[\(target)] \(models[target].members.count)")
        var seen: [Int] = []
        siblings[target].forEach { (member: borrowing Member) in seen.append(member.id) }
        let expected = models[target].members.map { $0.id }
        if seen != expected {
            verdict.diverged(["forEach on sibling \(target) walked \(seen), model \(expected)"])
        }
    }

    mutating func wipe(_ target: Int) {
        let keep = rng.chance(50)
        verdict.record("wipe[\(target)] keep=\(keep)")
        siblings[target].removeAll(keepingCapacity: keep)
        models[target].removeAll()
    }

    func audit() -> [String] {
        var findings: [String] = []
        for (index, model) in models.enumerated() {
            if siblings[index].count != Index<Member>.Count(UInt(model.members.count)) {
                findings.append("sibling \(index) count \(siblings[index].count), model \(model.members.count)")
            }
            var seen: [Int] = []
            siblings[index].forEach { (member: borrowing Member) in seen.append(member.id) }
            let expected = model.members.map { $0.id }
            if seen != expected {
                findings.append("sibling \(index) order \(seen), model \(expected)")
            }
            for (offset, member) in model.members.enumerated() {
                let position = siblings[index].index(of: probe(member))
                if position != Index<Member>(Ordinal(UInt(offset))) {
                    findings.append("sibling \(index) index(of: id \(member.id)): \(String(describing: position)), model \(offset)")
                }
            }
        }
        return findings
    }

    mutating func step() {
        let target = rng.below(siblings.count)
        var branch = rng.below(100)
        if models[target].members.isEmpty, branch >= 16, branch < 92 { branch = 10 }

        switch branch {
        case 0..<10 where siblings.count < 4: fork()
        case 0..<10: insertFresh(into: target)
        case 10..<16: insertFresh(into: target)
        case 16..<26 where siblings.count > 1: drop()
        case 16..<26: insertFresh(into: target)
        case 26..<46: removePresent(from: target)
        case 46..<60: indexHit(on: target)
        case 60..<74: containsHit(on: target)
        case 74..<92: walkOrder(on: target)
        default: wipe(target)
        }
    }

    mutating func run() {
        let operations = Model.operations(default: 800)
        var op = 0
        while op < operations, verdict.isClean {
            step()
            if Model.shouldAudit(op: op, of: operations) {
                verdict.diverged(audit())
            }
            op += 1
        }
    }
}

private func runFleetStream(seed: UInt64) -> Model.Verdict {
    let census = Model.Census()
    var verdict: Model.Verdict
    do {
        var stream = FleetStream(seed: seed, census: census)
        stream.run()
        verdict = stream.verdict
    }  // every sibling dies here; refcounts fall to zero

    if !census.isExact {
        verdict.findings.append(
            "teardown multiset broken across the fleet: \(census.born.count) born vs \(census.died.count) died"
        )
    }
    return verdict
}

// MARK: - The suites

@Suite
struct `Set.Ordered Model` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Set.Ordered Model`.Integration {
    @Test(arguments: Model.seeds(default: [0x02DE_2ED1, 0x02DE_2ED2]))
    func `direct move-only stream: order, positions, and exact teardown`(seed: UInt64) {
        let verdict = runDirectStream(seed: seed)
        #expect(verdict.isClean, Comment(rawValue: verdict.report))
    }

    @Test(arguments: Model.seeds(default: [0x02DE_F1E1, 0x02DE_F1E2, 0x02DE_F1E3]))
    func `shared sibling fleet: order and positions hold per fork; refcounts end exact`(seed: UInt64) {
        let verdict = runFleetStream(seed: seed)
        #expect(verdict.isClean, Comment(rawValue: verdict.report))
    }
}

extension `Set.Ordered Model`.Unit {
    @Test
    func `index(of:) tracks the backward-shift: positions compact after removal`() {
        let census = Model.Census()
        var set = MoveOrdered<Model.Element.Tracked>(minimumCapacity: Index<Model.Element.Tracked>.Count(8))
        for id in 0..<6 {
            set.insert(Model.Element.Tracked(id: id, group: id / 2, census: census))
        }
        _ = set.remove(Model.Element.Tracked(id: 2, group: 1, census: census))
        // Members after the removal point shift down by exactly one.
        let expectations: [(id: Int, group: Int, position: UInt)] = [
            (0, 0, 0), (1, 0, 1), (3, 1, 2), (4, 2, 3), (5, 2, 4),
        ]
        for entry in expectations {
            let position = set.index(of: Model.Element.Tracked(id: entry.id, group: entry.group, census: census))
            #expect(position == Index<Model.Element.Tracked>(Ordinal(entry.position)))
        }
        let gone = set.index(of: Model.Element.Tracked(id: 2, group: 1, census: census))
        #expect(gone == nil)
    }
}

extension `Set.Ordered Model`.`Edge Case` {
    @Test
    func `a sibling's removal does not move the other sibling's positions`() {
        let census = Model.Census()
        var first = CoWOrdered<Member>(minimumCapacity: Index<Member>.Count(4))
        first.insert(Member(id: 1, group: 0, census: census))
        first.insert(Member(id: 2, group: 0, census: census))
        first.insert(Member(id: 3, group: 0, census: census))
        var second = first

        _ = second.remove(Member(id: 1, group: 0, census: census))

        let secondTwo = second.index(of: Member(id: 2, group: 0, census: census))
        #expect(secondTwo == Index<Member>(Ordinal(UInt(0))))
        let firstTwo = first.index(of: Member(id: 2, group: 0, census: census))
        #expect(firstTwo == Index<Member>(Ordinal(UInt(1))))
        let firstOne = first.index(of: Member(id: 1, group: 0, census: census))
        #expect(firstOne == Index<Member>(Ordinal(UInt(0))))
    }
}
