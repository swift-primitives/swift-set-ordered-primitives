// exports.swift
// Re-export internal modules for consumers.
// Users import Set_Ordered_Primitives and get the ordered-set discipline:
// the base Set.Ordered type + conformances (this module), plus every capacity
// variant (Fixed / Static / Small). Per [MOD-005] the base-ops plural doubles
// as the package umbrella.

@_exported public import Set_Ordered_Primitive
@_exported public import Set_Ordered_Fixed_Primitives
@_exported public import Set_Ordered_Static_Primitives
@_exported public import Set_Ordered_Small_Primitives
