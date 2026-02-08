{ config, pkgs, lib, ... }:

with lib;

let
  # Determine terminal command
  # WezTerm is preferred if enabled, otherwise fall back to default
  terminalCmd = if config.wezterm.enable then
    "${pkgs.wezterm}/bin/wezterm start"
  else
    "${pkgs.alacritty}/bin/alacritty";

  # Walker is just a query interface over elephant providers
  # All execution (desktopapplications, runner, websearch, calc, files) happens in elephant
  # Walker only needs its own binary, which is already available via standard NixOS profile paths
  # Minimal PATH for walker - just standard system paths
  walkerPath = lib.concatStringsSep ":" [
    "/run/wrappers/bin"
    "/nix/var/nix/profiles/default/bin"
    "/home/${config.user}/.nix-profile/bin"
    "/run/current-system/sw/bin"
    "/etc/profiles/per-user/${config.user}/bin"  # User profile (where walker is installed)
  ];

  # Packages that elephant needs access to for launching programs
  # Elephant executes desktop applications, which typically use 'sh' shell
  # Note: elephant itself is installed via home-manager and is already available
  # in /etc/profiles/per-user/${config.user}/bin, which is included in elephantPath
  # These use pkgs from the system (with overlays applied via nixpkgs.overlays)
  elephantPathPackages = [
    pkgs.bash          # Provides 'sh' shell (required for desktop file execution)
    pkgs.coreutils     # Basic utilities (ls, cat, etc.)
    pkgs.findutils     # find command
    pkgs.xdg-utils     # xdg-open, xdg-desktop-menu, etc.
  ];

  # Build PATH string for elephant service
  # Since home-manager.useGlobalPkgs = true, pkgs here already has overlays applied
  elephantPath = lib.makeBinPath elephantPathPackages + ":" + lib.concatStringsSep ":" [
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
          # Close walker when clicking outside the main content area
          click_to_close = true;
          # Force keyboard focus to walker when it opens
          # This ensures the launcher receives keyboard input immediately
          force_keyboard_focus = true;
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
      # Walker is just a query interface - it communicates with elephant via IPC/socket
      # All actual execution (desktopapplications, runner, websearch, calc, files) happens in elephant
      # Walker only needs standard NixOS profile paths to find its own binary
      systemd.user.services.walker = {
        Service = {
          # Minimal PATH - just standard NixOS profile paths
          # Walker binary is installed via home-manager and available in user profile
          Environment = [
            "PATH=${walkerPath}"
          ];
        };
      };

      # Override elephant systemd service to add PATH environment
      # Elephant executes desktop applications via desktopapplications provider
      # Desktop files use 'sh' shell to execute commands, so elephant needs PATH
      # Since home-manager.useGlobalPkgs = true, pkgs here already has overlays applied
      systemd.user.services.elephant = {
        Service = {
          # Add PATH to include:
          # - bash (provides 'sh' shell - REQUIRED for desktop file execution)
          # - coreutils (basic utilities: ls, cat, cp, mv, etc.)
          # - findutils (find command)
          # - xdg-utils (xdg-open, xdg-desktop-menu, etc.)
          # - elephant (installed via home-manager, available in user profile)
          # - Standard NixOS profile paths
          Environment = [
            "PATH=${elephantPath}"
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
