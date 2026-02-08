{ terminalCmd, launcherCmd ? null, swaySystemdInitCmd, ... }:
''
  # Systemd integration - activate graphical-session.target
  # This allows systemd user services (like walker/elephant) to start automatically
  # The script ensures environment variables are imported before starting the target
  exec ${swaySystemdInitCmd}
  # Stop sway-session.target when Sway shuts down
  exec swaymsg -t subscribe '["shutdown"]' && systemctl --user stop sway-session.target

  # Set terminal
  set $term ${terminalCmd}
  
  # Set launcher (if enabled)
  ${if launcherCmd != null then ''set $launcher ${launcherCmd}'' else ""}
  
  # Mod key (Windows/Super key)
  set $mod Mod4
  
  # Keyboard layout configuration (Wayland input handling)
  # Norwegian layout with nodeadkeys variant
  input * {
      xkb_layout "no"
      xkb_variant "nodeadkeys"
  }
  
  # Touchpad configuration
  input "type:touchpad" {
      scroll_method two_finger
      natural_scroll enabled
  }
  
  # Window decoration - hide title bars
  default_border none
  
  # Workspaces
  bindsym {
      $mod+1 workspace number 1
      $mod+2 workspace number 2
      $mod+3 workspace number 3
  }
  
  # Move focused container to workspace
  bindsym {
      $mod+Shift+1 move container to workspace number 1
      $mod+Shift+2 move container to workspace number 2
      $mod+Shift+3 move container to workspace number 3
  }
  
  # Essential keybindings
  bindsym {
      # Launch terminal (Mod+Enter)
      $mod+Return exec $term
      # Launch application launcher (Mod+D)
      ${if launcherCmd != null then ''$mod+d exec $launcher'' else ""}
      # Close focused window (Mod+Shift+Q)
      $mod+Shift+q kill
  }
''
