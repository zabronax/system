# Default overlays file - collects all overlays
# Each overlay should be in its own subdirectory with a default.nix file
{ inputs, ... }:
[
  # Walker overlay - use latest version from source
  (import ./walker/default.nix { inherit inputs; })
]
