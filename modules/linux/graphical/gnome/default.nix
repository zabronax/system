{ config, pkgs, lib, ... }:

with lib;

{
  config = mkIf (config.graphical.enable && config.graphical.environment == "gnome") {
    # Enable X11 windowing system (required for GNOME)
    services.xserver.enable = true;

    # Configure X11 video drivers
    # If NVIDIA hardware is configured, use NVIDIA driver for X11
    # This is X11-specific, so it belongs with GNOME configuration
    services.xserver.videoDrivers = mkIf (config.hardware.nvidia != null) [
      "nvidia"
    ];

    # Configure X11 keyboard layout
    # Hosts can override by setting graphical.xkb.layout/variant
    services.xserver.xkb = {
      layout = config.graphical.xkb.layout;
      variant = config.graphical.xkb.variant;
    };

    # Sync virtual console keymap with X11 keymap to avoid redundancy
    # This is X11-dependent, so it belongs with GNOME configuration
    console.useXkbConfig = true;

    # Enable the GNOME Desktop Environment.
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;
  };
}
