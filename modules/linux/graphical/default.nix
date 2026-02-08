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

    xkb = {
      layout = mkOption {
        type = types.str;
        default = "no";
        description = "X11 keyboard layout (applies to all X11-based environments)";
        example = "no";
      };

      variant = mkOption {
        type = types.nullOr types.str;
        default = "nodeadkeys";
        description = "X11 keyboard variant";
        example = "nodeadkeys";
      };
    };
  };

  imports = [
    ./gnome.nix
  ];

  config = mkIf config.graphical.enable {
    # Enable X11 windowing system (required for graphical environments)
    services.xserver.enable = true;

    # Configure X11 keyboard layout
    # This applies to all X11-based desktop environments (GNOME, KDE, i3, etc.)
    # Hosts can override by setting graphical.xkb.layout/variant
    services.xserver.xkb = {
      layout = config.graphical.xkb.layout;
      variant = config.graphical.xkb.variant;
    };
  };
}
