import Set_Ordered_Primitives
import Set_Primitive
import Hash_Table_Primitives_Test_Support
import Buffer_Primitives_Test_Support
import Hash_Table_Primitive
import Hash_Indexed_Primitive
import Hash_Primitives
import Hash_Primitives_Standard_Library_Integration
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

// The column-keyed ordered-set suite: the ordered hashed column direct +
// Shared-wrapped, exercising the ORDER-FACING surface (positional reads, position
// lookup, order preservation) over the membership discipline.

private typealias HeapStorage<E: ~Copyable> =
    Storage<Memory.Allocator<Memory.Heap>.System>.Contiguous<E>

private typealias OrderedColumn<E: Hash.Key & ~Copyable> =
    Hash.Indexed<Buffer<HeapStorage<E>>.Linear>

private typealias MoveOrdered<E: Hash.Key & ~Copyable> = Set<OrderedColumn<E>>.Ordered
private typealias CoWOrdered<E: Hash.Key & SendableMetatype> = Set<Shared<E, OrderedColumn<E>>>.Ordered

// MARK: - [DS-024] + coherence (the Shared composite is this family's column)

@Suite
struct SetOrderedColumnLawTests {

    @Test
    func `the shared ordered-hashed column obeys the seam ledger laws`() {
        let violations = Seam.Ledger.violations(
            makeEmpty: { Shared(OrderedColumn<Int>(minimumCapacity: Index<Int>.Count(4))) },
            element: { $0 }
        )
        #expect(violations.isEmpty, "\(violations)")
    }

    @Test
    func `coherence holds through the ordered surface, direct column`() {
        var direct = MoveOrdered<Int>(minimumCapacity: 4)
        var i = 0
        while i < 16 {
            direct.insert(i &* 3)
            i += 1
        }
        _ = direct.remove(9)
        _ = direct.remove(0)
        let directViolations = direct.take().checkCoherence()
        #expect(directViolations.isEmpty, "\(directViolations)")
    }

    @Test
    func `coherence holds through the ordered surface, shared column`() {
        var shared = CoWOrdered<Int>(minimumCapacity: 4)
        var i = 0
        while i < 16 {
            shared.insert(i &* 5)
            i += 1
        }
        _ = shared.remove(25)
        _ = shared.remove(0)
        let sharedViolations = shared.take().withColumn { Hash.Coherence.violations($0) }
        #expect(sharedViolations.isEmpty, "\(sharedViolations)")
    }
}

extension Hash.Indexed<Buffer<HeapStorage<Int>>.Linear> {
    fileprivate borrowing func checkCoherence() -> [String] {
        Hash.Coherence.violations(self)
    }
}

// MARK: - Core membership (both columns)

@Suite(.serialized)
struct SetOrderedCoreTests {

    @Test
    func `insert, contains, duplicate hand-back, remove, counts`() {
        var s = MoveOrdered<Int>(minimumCapacity: 4)
        let isEmpty = s.isEmpty
        #expect(isEmpty)
        let first = s.insert(10)
        #expect(first == nil)
        let dup = s.insert(10)
        #expect(dup == 10)
        s.insert(20)
        s.insert(30)
        let has = s.contains(20), hasNot = s.contains(40)
        #expect(has)
        #expect(!hasNot)
        let removed = s.remove(20)
        #expect(removed == 20)
        let absent = s.remove(20)
        #expect(absent == nil)
        let n = s.count
        #expect(n == Index<Int>.Count(2))
    }

    @Test
    func `iteration is insertion-ordered across growth and removal`() {
        var s = MoveOrdered<Int>(minimumCapacity: 2)
        var i = 0
        while i < 12 {
            s.insert(i)
            i += 1
        }
        _ = s.remove(5)
        var seen: [Int] = []
        s.forEach { seen.append($0) }
        #expect(seen == [0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11])
    }

    @Test
    func `removeAll empties; reuse works; direct clone detaches`() {
        var s = MoveOrdered<Int>(minimumCapacity: 4)
        s.insert(1)
        s.insert(2)
        var c = s.clone()
        _ = c.remove(1)
        let mineHas = s.contains(1), theirsHas = c.contains(1)
        #expect(mineHas)
        #expect(!theirsHas)
        s.removeAll()
        let isEmpty = s.isEmpty
        #expect(isEmpty)
        s.insert(7)
        let has7 = s.contains(7)
        #expect(has7)
    }
}

// MARK: - The ORDER-FACING surface (positional reads + position lookup)

@Suite(.serialized)
struct SetOrderedOrderTests {

    @Test
    func `positional subscript reads insertion order, both columns`() {
        var s = MoveOrdered<Int>(minimumCapacity: 4)
        s.insert(10)
        s.insert(20)
        s.insert(30)
        let a = s[0], b = s[1], c = s[2]
        #expect(a == 10)
        #expect(b == 20)
        #expect(c == 30)

        var t = CoWOrdered<Int>(minimumCapacity: 4)
        t.insert(7)
        t.insert(8)
        let x = t[0], y = t[1]
        #expect(x == 7)
        #expect(y == 8)
    }

    @Test
    func `index(of:) returns the insertion position; nil for absent members`() {
        var s = MoveOrdered<Int>(minimumCapacity: 4)
        s.insert(10)
        s.insert(20)
        s.insert(30)
        let i10 = s.index(of: 10), i30 = s.index(of: 30), missing = s.index(of: 40)
        #expect(i10 == 0)
        #expect(i30 == 2)
        #expect(missing == nil)

        var t = CoWOrdered<Int>(minimumCapacity: 4)
        t.insert(5)
        t.insert(6)
        let i6 = t.index(of: 6), absent = t.index(of: 9)
        #expect(i6 == 1)
        #expect(absent == nil)
    }

    @Test
    func `removal shifts later members down; insertion order is preserved`() {
        var s = MoveOrdered<Int>(minimumCapacity: 4)
        s.insert(1)
        s.insert(2)
        s.insert(3)
        s.insert(4)
        _ = s.remove(2)
        let a = s[0], b = s[1], c = s[2]
        #expect(a == 1)
        #expect(b == 3)
        #expect(c == 4)
        let i4 = s.index(of: 4)
        #expect(i4 == 2)
    }

    @Test
    func `re-insertion goes to the end`() {
        var s = MoveOrdered<Int>(minimumCapacity: 4)
        s.insert(1)
        s.insert(2)
        s.insert(3)
        _ = s.remove(1)
        s.insert(1)
        var seen: [Int] = []
        s.forEach { seen.append($0) }
        #expect(seen == [2, 3, 1])
        let i1 = s.index(of: 1)
        #expect(i1 == 2)
    }

    @Test
    func `first and last track the insertion boundary; nil when empty`() {
        var s = MoveOrdered<Int>(minimumCapacity: 4)
        let emptyFirst = s.first, emptyLast = s.last
        #expect(emptyFirst == nil)
        #expect(emptyLast == nil)
        s.insert(10)
        s.insert(20)
        s.insert(30)
        let f = s.first, l = s.last
        #expect(f == 10)
        #expect(l == 30)
        _ = s.remove(10)
        let f2 = s.first
        #expect(f2 == 20)
        _ = s.remove(30)
        let l2 = s.last
        #expect(l2 == 20)
    }
}

// MARK: - CoW value semantics (the Shared composite column)

@Suite(.serialized)
struct SetOrderedCoWTests {

    @Test
    func `copies share until mutation; inserts detach through the box`() {
        var a = CoWOrdered<Int>(minimumCapacity: 4)
        a.insert(1)
        let b = a                                // S5: Set.Ordered is Copyable because S is
        a.insert(2)                              // withUnique(consuming:) detaches first
        let mine = a.count, theirs = b.count
        #expect(mine == Index<Int>.Count(2))
        #expect(theirs == Index<Int>.Count(1))
        let aHas2 = a.contains(2), bHas2 = b.contains(2)
        #expect(aHas2)
        #expect(!bHas2)
    }

    @Test
    func `ordered reads never detach; removal detaches; generic clone detaches`() {
        var a = CoWOrdered<Int>(minimumCapacity: 4)
        a.insert(1)
        a.insert(2)
        let b = a
        let pos = a.index(of: 2), head = a.first, tail = b.last, read = a[0]
        #expect(pos == 1)
        #expect(head == 1)
        #expect(tail == 2)
        #expect(read == 1)

        let removed = a.remove(1)
        #expect(removed == 1)
        let bStillHas = b.contains(1)
        #expect(bStillHas)

        var c = a.clone()
        c.insert(9)
        let aHas9 = a.contains(9), cHas9 = c.contains(9)
        #expect(!aHas9)
        #expect(cHas9)
    }

    @Test
    func `removeAll detaches to a fresh box; the sibling is untouched`() {
        var a = CoWOrdered<Int>(minimumCapacity: 4)
        a.insert(1)
        let b = a
        a.removeAll()
        let aEmpty = a.isEmpty, bHas = b.contains(1)
        #expect(aEmpty)
        #expect(bHas)
    }

    @Test
    func `equality and hashing are order-sensitive (the S5 carriers)`() {
        var a = CoWOrdered<Int>(minimumCapacity: 4)
        a.insert(1)
        a.insert(2)
        var b = CoWOrdered<Int>(minimumCapacity: 4)
        b.insert(1)
        b.insert(2)
        var c = CoWOrdered<Int>(minimumCapacity: 4)
        c.insert(2)
        c.insert(1)
        #expect(a == b)
        #expect(a != c)                          // same members, different insertion order
        let ha = a.hashValue, hb = b.hashValue
        #expect(ha == hb)
    }
}

// MARK: - Move-only members: positional surface + teardown oracles

@Suite(.serialized)
struct SetOrderedTeardownTests {

    @Test
    func `move-only members flow through and tear down exactly once`() {
        OrderedProbe.reset()
        do {
            var s = MoveOrdered<OrderedItem>(minimumCapacity: 4)
            s.insert(OrderedItem(1))
            s.insert(OrderedItem(2))
            let has = s.contains(OrderedItem(2))
            #expect(has)
            if let removed: OrderedItem = s.remove(OrderedItem(1)) {
                let id = removed.id
                #expect(id == 1)
            } else {
                Issue.record("expected the removed member")
            }
        }
        let all = OrderedProbe.destroyedSorted
        let twos = all.filter { $0 == 2 }.count
        #expect(twos == 2)                       // the live member + the contains() probe argument
    }

    @Test
    func `positional reads borrow move-only members in place`() {
        OrderedProbe.reset()
        do {
            var s = MoveOrdered<OrderedItem>(minimumCapacity: 4)
            s.insert(OrderedItem(7))
            s.insert(OrderedItem(8))
            let id0 = s[0].id, id1 = s[1].id
            #expect(id0 == 7)
            #expect(id1 == 8)
            let pos = s.index(of: OrderedItem(8))
            #expect(pos == 1)
        }
        let sevens = OrderedProbe.destroyedSorted.filter { $0 == 7 }.count
        #expect(sevens == 1)                     // the borrowing reads minted no copies
    }

    @Test
    func `the boxed move-only lane tears down via the box drain`() {
        OrderedProbe2.reset()
        do {
            var s = Set<Shared<OrderedItem2, OrderedColumn<OrderedItem2>>>.Ordered(minimumCapacity: 4)
            s.insert(OrderedItem2(7))
            s.insert(OrderedItem2(8))
            let n = s.count
            #expect(n == Index<OrderedItem2>.Count(2))
        }
        let all = OrderedProbe2.destroyedSorted
        #expect(all == [7, 8])
    }
}

private struct OrderedItem: ~Copyable {
    let id: Int
    init(_ id: Int) { self.id = id }
    deinit { OrderedProbe.recordDestroy(id) }
}

extension OrderedItem: Hash.`Protocol` {
    borrowing func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: borrowing OrderedItem, rhs: borrowing OrderedItem) -> Bool {
        lhs.id == rhs.id
    }
}

private enum OrderedProbe {
    nonisolated(unsafe) static var _destroyed: [Int] = []
    static func reset() { unsafe _destroyed = [] }
    static func recordDestroy(_ id: Int) { unsafe _destroyed.append(id) }
    static var destroyedSorted: [Int] { unsafe _destroyed.sorted() }
}

private struct OrderedItem2: ~Copyable {
    let id: Int
    init(_ id: Int) { self.id = id }
    deinit { OrderedProbe2.recordDestroy(id) }
}

extension OrderedItem2: Hash.`Protocol` {
    borrowing func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: borrowing OrderedItem2, rhs: borrowing OrderedItem2) -> Bool {
        lhs.id == rhs.id
    }
}

private enum OrderedProbe2 {
    nonisolated(unsafe) static var _destroyed: [Int] = []
    static func reset() { unsafe _destroyed = [] }
    static func recordDestroy(_ id: Int) { unsafe _destroyed.append(id) }
    static var destroyedSorted: [Int] { unsafe _destroyed.sorted() }
}

// MARK: - Sendable smoke

@Suite
struct SetOrderedSendableTests {

    @Test
    func `sendable composes through both columns`() {
        let a = MoveOrdered<Int>(minimumCapacity: 1)
        requireSendable(a)
        let b = CoWOrdered<Int>(minimumCapacity: 1)
        requireSendable(b)
        #expect(Bool(true))
    }
}

private func requireSendable<T: Sendable & ~Copyable>(_ value: borrowing T) {}
