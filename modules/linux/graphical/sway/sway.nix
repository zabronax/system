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
  
  # Essential keybindings
  # Launch terminal (Mod+Enter)
  bindsym $mod+Return exec $term
  
  # Launch browser (Mod+B)
  # TODO: Dynamically determine browser based on configuration
  # (e.g., check programs.firefox.enable, programs.chromium.enable, etc.)
  bindsym $mod+b exec firefox
''
