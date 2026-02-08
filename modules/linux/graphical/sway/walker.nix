{ config, pkgs, lib, ... }:

with lib;

let
  # Determine terminal command
  # WezTerm is preferred if enabled, otherwise fall back to default
  terminalCmd = if config.wezterm.enable then
    "${pkgs.wezterm}/bin/wezterm start"
  else
    "${pkgs.alacritty}/bin/alacritty";

  # Packages that walker needs access to for launching programs
  # These use pkgs from the system (with overlays applied via nixpkgs.overlays)
  walkerPathPackages = [
    pkgs.bash          # Provides 'sh' shell
    pkgs.coreutils     # Basic utilities (ls, cat, etc.)
    pkgs.findutils      # find command
    pkgs.xdg-utils      # xdg-open for websearch provider
    pkgs.walker         # Walker itself (with overlay-applied version)
  ];

  # Build PATH string from packages and standard NixOS paths
  # Since home-manager.useGlobalPkgs = true, pkgs here already has overlays applied
  walkerPath = lib.makeBinPath walkerPathPackages + ":" + lib.concatStringsSep ":" [
    "/run/wrappers/bin"
    "/nix/var/nix/profiles/default/bin"
    "/home/${config.user}/.nix-profile/bin"
    "/run/current-system/sw/bin"
    "/etc/profiles/per-user/${config.user}/bin"  # User profile (where packages are installed)
  ];

  # Generate walker theme color definitions
  # Walker bundles its own default CSS, so we only provide color overrides
  # CSS cascading will apply our overrides on top of walker's defaults
  walkerThemeCss = import ./walker-theme.nix {
    colors = config.theme.colorScheme.colors;
  };
in

{
  options.walker = {
    enable = mkEnableOption "walker application launcher";
  };

  config = mkIf config.walker.enable {
    # Enable walker via home-manager
    home-manager.users.${config.user} = {
      services.walker = {
        enable = true;
        systemd.enable = true;

        # Transforms into a TOML file at ~/.config/walker/config.toml
        # For all options, see:
        # https://raw.githubusercontent.com/abenz1267/walker/refs/heads/master/resources/config.toml
        settings = {
          # Set terminal for runner provider's "run in terminal" action
          terminal = terminalCmd;
          # Use custom Ashes theme
          theme = "ashes";
        };
      };

      # Create custom theme for walker using CSS cascading
      # Walker bundles its own default CSS, so we only provide color overrides
      # CSS cascading will apply our overrides on top of walker's defaults
      # Walker themes are stored in ~/.config/walker/themes/<theme-name>/
      # Each theme needs its own subdirectory with a CSS file
      xdg.configFile."walker/themes/ashes/style.css" = {
        text = walkerThemeCss;
      };

      # Override walker systemd service to add PATH environment
      # Walker needs access to basic shell utilities (sh, etc.) to launch programs
      # Also needs xdg-utils for websearch provider and elephant backend
      # Since home-manager.useGlobalPkgs = true, pkgs here already has overlays applied
      systemd.user.services.walker = {
        Service = {
          # Add PATH to include:
          # - bash (provides 'sh' shell)
          # - coreutils (basic utilities: ls, cat, cp, mv, etc.)
          # - findutils (find command)
          # - xdg-utils (xdg-open for websearch provider)
          # - elephant (backend service, overlay-applied if needed)
          # - walker (overlay-applied version)
          # - Standard NixOS profile paths
          Environment = [
            "PATH=${walkerPath}"
          ];
        };
      };

      # Enable Elephant backend service (required for Walker)
      # Elephant provides the data/plugin infrastructure that Walker consumes
      programs.elephant = {
        enable = true;
        installService = true; # Creates systemd user service

        # Enable essential providers
        # See: https://walkerlauncher.com/docs/providers
        providers = [
          "providerlist"      # Provider switcher (required)
          "desktopapplications" # Desktop application launcher (essential)
          "files"             # File browser
          "runner"             # Command runner
          "websearch"          # Web search
          "menus"              # Custom menus
        ];

        # Elephant configuration
        settings = {
          # Add any elephant-specific settings here
          # Run `elephant generatedoc` to see available options
        };
      };
    };
  };
}
