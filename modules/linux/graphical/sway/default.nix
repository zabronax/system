{ config, pkgs, lib, ... }:

with lib;

{
  config = mkIf (config.graphical.enable && config.graphical.environment == "sway") {
    # Enable Sway (Wayland compositor and window manager)
    # Note: Sway does NOT require X11 - it is a Wayland compositor
    programs.sway.enable = true;

    # Enable GDM display manager to launch Sway
    # GDM can launch Wayland sessions including Sway
    services.displayManager.gdm.enable = true;
    
    # Set Sway as the default session
    # This makes Sway the default option at the login screen
    services.displayManager.defaultSession = "sway";

    # NVIDIA-specific environment variables for Wayland
    # These may be needed for NVIDIA GPU compatibility with Sway
    # WLR_NO_HARDWARE_CURSORS=1 is a workaround for cursor issues
    environment.sessionVariables = mkIf (config.hardware.nvidia != null) {
      WLR_NO_HARDWARE_CURSORS = "1";
    };
  };
}
