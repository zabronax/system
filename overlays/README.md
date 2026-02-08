# Overlays

## What are overlays?

Overlays in Nix are a mechanism to modify or extend the nixpkgs package set without forking the entire repository. They allow you to:

- **Override packages**: Replace a package with a different version or variant
- **Add new packages**: Introduce packages not in nixpkgs
- **Modify package attributes**: Change build inputs, patches, or other attributes
- **Apply patches**: Fix bugs or add features without waiting for upstream merges

An overlay is a function that takes two arguments (`final` and `prev`) and returns an attribute set of package modifications. The `prev` argument represents the original nixpkgs, while `final` represents nixpkgs with all overlays applied. This allows overlays to depend on other overlay-modified packages.

## Why use overlays?

Overlays provide a clean, maintainable way to customize your NixOS or Home Manager configuration:
- **Isolation**: Each overlay is self-contained and documented
- **Transparency**: Easy to see what's being modified and why
- **Maintainability**: Can be removed when upstream catches up
- **Composability**: Multiple overlays can be combined

This directory contains nixpkgs overlays organized by package or purpose. Each overlay should be in its own subdirectory with a `default.nix` file that exports the overlay function.

## Structure

```
overlays/
  default.nix           # Collects all overlays
  <package-name>/
    default.nix         # Overlay function: final: prev: { ... }
    README.md           # Documentation: why, when to remove, references
```

## Adding a new overlay

1. Create a new subdirectory: `overlays/<package-name>/`
2. Create `default.nix` with the overlay function
3. Create `README.md` documenting:
   - **Why**: Why this patch/override exists
   - **When can it be removed**: Conditions for removal
   - **References**: Links to relevant issues, PRs, upstream sources
4. Add it to `overlays/default.nix`:

```nix
[
  # ... existing overlays ...
  (import ./<package-name>/default.nix { inherit inputs; })
]
```
