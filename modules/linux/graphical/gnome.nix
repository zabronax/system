{ config, pkgs, lib, ... }:

with lib;

{
  config = mkIf (config.graphical.enable && config.graphical.environment == "gnome") {
    # Enable the GNOME Desktop Environment.
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;
  };
}
