{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    alacritty = {
      enable = lib.mkEnableOption {
        description = "Enable Alacritty.";
        default = false;
      };
    };
  };

  config = lib.mkIf (config.gui.enable && config.alacritty.enable) {
    home-manager.users.${config.user} = {
      xsession.windowManager.i3.config.terminal = "alacritty";
      programs.rofi.terminal = "${pkgs.alacritty}/bin/alacritty";
      programs.alacritty = {
        enable = true;
        settings = {
          window = {
            dimensions = {
              columns = 85;
              lines = 30;
            };
            padding = {
              x = 20;
              y = 20;
            };
            opacity = 1.0;
          };
          scrolling.history = 10000;
          font = {
            size = 14.0;
          };
          key_bindings = [
            # Used for word completion in fish_user_key_bindings
            {
              key = "Return";
              mods = "Shift";
              chars = "\\x1F";
            }
            # Used for searching nixpkgs in fish_user_key_bindings
            {
              key = "N";
              mods = "Control|Shift";
              chars = "\\x11F";
            }
            {
              key = "H";
              mods = "Control|Shift";
              mode = "~Vi";
              action = "ToggleViMode";
            }
            {
              key = "Return";
              mode = "Vi";
              action = "ToggleViMode";
            }
            # Used to enable $ keybind in Vi mode
            {
              key = 5; # Scancode for key4
              mods = "Shift";
              mode = "Vi|~Search";
              action = "Last";
            }
          ];
          colors = {
            primary = {
              background = config.theme.colorScheme.colors.base00;
              foreground = config.theme.colorScheme.colors.base05;
            };
            cursor = {
              text = "#1d2021";
              cursor = config.theme.colorScheme.colors.base05;
            };
            normal = {
              black = "#1d2021";
              red = config.theme.colorScheme.colors.base08;
              green = config.theme.colorScheme.colors.base0B;
              yellow = config.theme.colorScheme.colors.base0A;
              blue = config.theme.colorScheme.colors.base0D;
              magenta = config.theme.colorScheme.colors.base0E;
              cyan = config.theme.colorScheme.colors.base0C;
              white = config.theme.colorScheme.colors.base05;
            };
            bright = {
              black = config.theme.colorScheme.colors.base03;
              red = config.theme.colorScheme.colors.base09;
              green = config.theme.colorScheme.colors.base01;
              yellow = config.theme.colorScheme.colors.base02;
              blue = config.theme.colorScheme.colors.base04;
              magenta = config.theme.colorScheme.colors.base06;
              cyan = config.theme.colorScheme.colors.base0F;
              white = config.theme.colorScheme.colors.base07;
            };
          };
          draw_bold_text_with_bright_colors = false;
        };
      };
    };
  };
}
