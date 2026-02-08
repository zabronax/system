{ config, pkgs, lib, ... }:

with lib;

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
        };

        # TODO! Figure out the theme options
        # theme = {
        #   layout = "???";
        #   name = "???";
        # };
      };
    };
  };
}
