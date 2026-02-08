{ config, pkgs, lib, ... }:

with lib;

let
  # Determine terminal command
  # WezTerm is preferred if enabled, otherwise fall back to default
  terminalCmd = if config.wezterm.enable then
    "${pkgs.wezterm}/bin/wezterm start"
  else
    "${pkgs.alacritty}/bin/alacritty";
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
