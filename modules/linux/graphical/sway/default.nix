{ config, pkgs, lib, ... }:

with lib;

let
  # Determine terminal command
  # WezTerm is preferred if enabled, otherwise fall back to default
  terminalCmd = if config.wezterm.enable then
    "${pkgs.wezterm}/bin/wezterm"
  else
    "${pkgs.alacritty}/bin/alacritty";
  
  # Determine Cursor command if enabled
  cursorCmd = if config.applications.cursor.enable then
    "${pkgs.code-cursor-fhs}/bin/code-cursor-fhs"
  else
    null;
in

{
  config = mkIf (config.graphical.enable && config.graphical.environment == "sway") {
    # Enable Sway (Wayland compositor and window manager)
    # Note: Sway does NOT require X11 - it is a Wayland compositor
    programs.sway.enable = true;

    # Minimal Sway configuration - just enough to launch terminal and editor
    # Sway config is written to ~/.config/sway/config via home-manager
    home-manager.users.${config.user} = {
      xdg.configFile."sway/config".text = ''
        # Set terminal
        set $term ${terminalCmd}
        
        # Mod key (Windows/Super key)
        set $mod Mod4
        
        # Keyboard layout configuration (Wayland input handling)
        # Norwegian layout with nodeadkeys variant
        input * xkb_layout "no"
        input * xkb_variant "nodeadkeys"
        
        # Touchpad configuration
        input "type:touchpad" {
            scroll_method two_finger
            natural_scroll enabled
        }
        
        # Essential keybindings only
        # Launch terminal (Mod+Enter)
        bindsym $mod+Return exec $term
        
        # Launch Cursor if enabled (Mod+Shift+C)
        ${lib.optionalString (cursorCmd != null) ''
          bindsym $mod+Shift+c exec ${cursorCmd}
        ''}
      '';
    };

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
