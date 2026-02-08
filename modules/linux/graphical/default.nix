{ config, lib, ... }:

with lib;

{
  options.graphical = {
    enable = mkEnableOption "graphical environment";
    
    environment = mkOption {
      type = types.enum [ "gnome" "sway" ];
      description = ''
        Desktop environment or window manager to use.
        
        Note: Desktop environments are exclusive - only one can be active
        at a time. Multiple can be installed and selected at login, but
        only the configured one will be enabled in the system.
      '';
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
    ./gnome
    ./sway
  ];

  config = mkIf config.graphical.enable {
    # Validate that an environment is selected
    # This assertion ensures that if graphical is enabled, an environment must be chosen
    assertions = [
      {
        assertion = config.graphical.environment != null;
        message = "graphical.enable is true but no graphical.environment is set";
      }
    ];
  };
}
