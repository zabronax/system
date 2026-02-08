{
  config,
  pkgs,
  lib,
  ...
}:

{
  options = {
    wezterm = {
      enable = lib.mkEnableOption {
        description = "Enable WezTerm.";
        default = false;
      };
    };
  };

  config = lib.mkIf config.wezterm.enable {
    home-manager.users.${config.user} = {
      programs.wezterm = {
        enable = true;
        extraConfig = ''
          local wezterm = require 'wezterm'
          local config = wezterm.config_builder()

          -- Font with fallback for Nerd Font symbols
          config.font = wezterm.font_with_fallback({
            'Monaspace Argon NF',
            'Symbols Nerd Font',
          })
          config.font_size = 12.0

          -- Gruvbox Dark color scheme using theme source
          config.colors = {
            background = '${config.theme.colorScheme.colors.base00}',
            foreground = '${config.theme.colorScheme.colors.base05}',
            cursor_bg = '${config.theme.colorScheme.colors.base05}',
            cursor_fg = '${config.theme.colorScheme.colors.base00}',
            ansi = {
              '${config.theme.colorScheme.colors.base00}', -- black
              '${config.theme.colorScheme.colors.base08}', -- red
              '${config.theme.colorScheme.colors.base0B}', -- green
              '${config.theme.colorScheme.colors.base0A}', -- yellow
              '${config.theme.colorScheme.colors.base0D}', -- blue
              '${config.theme.colorScheme.colors.base0E}', -- magenta
              '${config.theme.colorScheme.colors.base0C}', -- cyan
              '${config.theme.colorScheme.colors.base05}', -- white
            },
            brights = {
              '${config.theme.colorScheme.colors.base03}', -- bright black
              '${config.theme.colorScheme.colors.base09}', -- bright red
              '${config.theme.colorScheme.colors.base0B}', -- bright green
              '${config.theme.colorScheme.colors.base0A}', -- bright yellow
              '${config.theme.colorScheme.colors.base0D}', -- bright blue
              '${config.theme.colorScheme.colors.base0E}', -- bright magenta
              '${config.theme.colorScheme.colors.base0C}', -- bright cyan
              '${config.theme.colorScheme.colors.base07}', -- bright white
            },
          }

          -- Launch fish shell by default
          config.default_prog = { '${pkgs.fish}/bin/fish', '-l' }

          -- Disable tab bar (tiling window manager handles window management)
          config.enable_tab_bar = false

          -- Enable daemon mode for faster window opening
          config.daemon_options = {
            stdout = '${config.homePath}/.local/share/wezterm/stdout',
            stderr = '${config.homePath}/.local/share/wezterm/stderr',
            pid_file = '${config.homePath}/.local/share/wezterm/pid',
          }

          return config
        '';
      };

      # Keep WezTerm running in background for instant window opening (macOS only)
      # WezTerm's mux server handles fast window creation automatically
      launchd.agents.wezterm = lib.mkIf pkgs.stdenv.isDarwin {
        enable = true;
        config = {
          Label = "com.github.wez.wezterm";
          ProgramArguments = [
            "${pkgs.wezterm}/Applications/WezTerm.app/Contents/MacOS/wezterm"
            "gui"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          ProcessType = "Background";
        };
      };
    };
  };
}
