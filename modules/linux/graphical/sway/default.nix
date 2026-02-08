{ config, lib, ... }:

with lib;

{
  imports = [
    ./walker.nix
    ./sway.nix
  ];
}
