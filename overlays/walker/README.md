# Walker Overlay

## Why this patch exists

The walker package in nixpkgs is outdated (version 0.13.26) compared to the latest upstream release (2.14.1+). This overlay overrides the nixpkgs walker package to use the latest version directly from the walker flake source.

The newer version includes:
- Improved theme loading and CSS support
- Bug fixes and performance improvements
- New features and provider updates

## When can this be removed

This overlay can be removed when:
- nixpkgs updates walker to version 2.14.1 or later
- The upstream walker version stabilizes and is merged into nixpkgs

**Check periodically**: Monitor nixpkgs for walker package updates and test if the overlay is still necessary.

## References

- **Walker GitHub**: https://github.com/abenz1267/walker
- **Walker Flake**: https://github.com/abenz1267/walker/blob/master/flake.nix
- **Nixpkgs Walker Package**: https://search.nixos.org/packages?query=walker
- **Walker Documentation**: https://walkerlauncher.com/docs/
