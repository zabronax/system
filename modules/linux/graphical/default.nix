{ config, lib, ... }:

with lib;

{
  options.graphical = {
    enable = mkEnableOption "graphical environment";
    
    environment = mkOption {
      type = types.enum [ "gnome" ];
      description = "Desktop environment to use";
      default = "gnome";
    };
  };

  imports = [
    ./gnome.nix
  ];
}
