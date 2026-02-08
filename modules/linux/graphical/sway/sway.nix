{ terminalCmd, ... }:
''
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
  
  # Window decoration - hide title bars
  default_border none
  
  # Workspaces
  # Switch to workspace
  bindsym $mod+1 workspace number 1
  bindsym $mod+2 workspace number 2
  bindsym $mod+3 workspace number 3
  
  # Move focused container to workspace
  bindsym $mod+Shift+1 move container to workspace number 1
  bindsym $mod+Shift+2 move container to workspace number 2
  bindsym $mod+Shift+3 move container to workspace number 3
  
  # Essential keybindings
  # Launch terminal (Mod+Enter)
  bindsym $mod+Return exec $term
  
  # Launch browser (Mod+B)
  # TODO: Dynamically determine browser based on configuration
  # (e.g., check programs.firefox.enable, programs.chromium.enable, etc.)
  bindsym $mod+b exec firefox
''
