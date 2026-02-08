{ terminalCmd, launcherCmd ? null, wallpaperPath ? null, pkgs, base00, base01, base02, base03, base05, base08, base0D, swaySystemdInitCmd, ... }:
''
  # Systemd integration - activate graphical-session.target
  # This allows systemd user services (like walker/elephant) to start automatically
  # The script ensures environment variables are imported before starting the target
  exec ${swaySystemdInitCmd}
  # Stop sway-session.target when Sway shuts down
  exec swaymsg -t subscribe '["shutdown"]' && systemctl --user stop sway-session.target

  # Set wallpaper (if configured)
  ${if wallpaperPath != null then ''exec ${pkgs.swaybg}/bin/swaybg -i "${wallpaperPath}"'' else ""}

  # Set terminal
  set $term ${terminalCmd}
  
  # Set launcher (if enabled)
  ${if launcherCmd != null then ''set $launcher ${launcherCmd}'' else ""}
  
  # Mod key (Windows/Super key)
  set $mod Mod4

  # Window colors using theme colorscheme
  # base00: Default Background
  # base01: Lighter Background
  # base02: Selection Background
  # base03: Comments/Invisibles
  # base05: Default Foreground
  # base08: Variables/Errors
  # base0D: Functions/Headings
  client.focused ${base0D} ${base00} ${base05}
  client.unfocused ${base01} ${base00} ${base03}
  client.focused_inactive ${base02} ${base00} ${base03}
  client.urgent ${base08} ${base00} ${base05}
  client.placeholder ${base01} ${base00} ${base03}
  client.background ${base00}
  
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
  
  # Gaps - breathing room between windows and screen edges
  gaps inner 8
  gaps outer 8
  
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
