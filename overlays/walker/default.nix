# Walker overlay - use latest version from source
# Overrides nixpkgs walker with the latest version from the walker flake
{ inputs, ... }:
final: prev: {
  walker = inputs.walker.packages.${prev.stdenv.system}.walker;
}
