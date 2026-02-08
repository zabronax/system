{ config, pkgs, lib, ... }:

with lib;

let
  # Determine terminal command
  # WezTerm is preferred if enabled, otherwise fall back to default
  terminalCmd = if config.wezterm.enable then
    "${pkgs.wezterm}/bin/wezterm"
  else
    "${pkgs.alacritty}/bin/alacritty";
  
  # Launcher command (walker)
  launcherCmd = if config.walker.enable then
    "${pkgs.walker}/bin/walker"
  else
    null;
  
  # Import Sway configuration (pure function with binary dependencies)
  swayConfig = import ./sway.nix {
    inherit terminalCmd launcherCmd;
  };
in

{
  imports = [
    ./walker.nix
  ];

  config = mkIf (config.graphical.enable && config.graphical.environment == "sway") {
    # Enable Sway (Wayland compositor and window manager)
    # Note: Sway does NOT require X11 - it is a Wayland compositor
    programs.sway.enable = true;
    
    # Enable walker launcher by default
    walker.enable = mkDefault true;

    # Sway system configuration (fallback)
    # Sway loads configs in order: ~/.sway/config, ~/.config/sway/config, /etc/sway/config
    # User can create ~/.config/sway/config to override this system config
    environment.etc."sway/config".text = swayConfig;

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
