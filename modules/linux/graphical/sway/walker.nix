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
  walkerPathPackages = [
    pkgs.bash          # Provides 'sh' shell
    pkgs.coreutils     # Basic utilities (ls, cat, etc.)
    pkgs.findutils      # find command
    pkgs.xdg-utils      # xdg-open for websearch provider
  ];

  # Build PATH string from packages and standard NixOS paths
  walkerPath = lib.makeBinPath walkerPathPackages + ":" + lib.concatStringsSep ":" [
    "/run/wrappers/bin"
    "/nix/var/nix/profiles/default/bin"
    "/home/${config.user}/.nix-profile/bin"
    "/run/current-system/sw/bin"
  ];
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
        };

        # TODO! Figure out the theme options
        # theme = {
        #   layout = "???";
        #   name = "???";
        # };
      };

      # Override walker systemd service to add PATH environment
      # Walker needs access to basic shell utilities (sh, etc.) to launch programs
      # Also needs xdg-utils for websearch provider
      systemd.user.services.walker = {
        Service = {
          # Add PATH to include:
          # - bash (provides 'sh' shell)
          # - coreutils (basic utilities: ls, cat, cp, mv, etc.)
          # - findutils (find command)
          # - xdg-utils (xdg-open for websearch provider)
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
