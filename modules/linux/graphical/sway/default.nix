{ config, pkgs, lib, ... }:

with lib;

let
  # Determine terminal command
  # WezTerm is preferred if enabled, otherwise fall back to default
  terminalCmd = if config.wezterm.enable then
    "${pkgs.wezterm}/bin/wezterm start"
  else
    "${pkgs.alacritty}/bin/alacritty";
  
  # Launcher command (walker)
  launcherCmd = if config.walker.enable then
    "${pkgs.walker}/bin/walker"
  else
    null;
  
  # Wallpaper path (if wallpaper is enabled)
  # Extract store path from source (derivation or path)
  sourceToPath = source: if lib.isDerivation source then source.outPath else source;
  wallpaperPath = if config.wallpaper.enable && config.wallpaper.path != null then
    "${sourceToPath config.wallpaper.source}/${config.wallpaper.path}"
  else
    null;
  
  # Script to initialize systemd integration for Sway
  # This ensures environment variables are imported before starting the target
  swaySystemdInit = pkgs.writeShellScriptBin "sway-systemd-init" ''
    systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK
    systemctl --user start sway-session.target
  '';
  
  # Import Sway configuration (pure function with binary dependencies)
  swayConfig = import ./sway.nix {
    inherit terminalCmd launcherCmd wallpaperPath;
    inherit pkgs;
    swaySystemdInitCmd = "${swaySystemdInit}/bin/sway-systemd-init";
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

    # Create systemd user target for Sway session
    # This target binds to graphical-session.target and allows systemd services
    # (like walker/elephant) to start automatically when Sway launches
    home-manager.users.${config.user} = {
      systemd.user.targets.sway-session = {
        Unit = {
          Description = "sway compositor session";
          Documentation = "man:systemd.special(7)";
          BindsTo = [ "graphical-session.target" ];
          Wants = [ "graphical-session-pre.target" ];
          After = [ "graphical-session-pre.target" ];
        };
      };
    };

    # Sway system configuration (fallback)
    # Sway loads configs in order: ~/.sway/config, ~/.config/sway/config, /etc/sway/config
    # User can create ~/.config/sway/config to override this system config
    environment.etc."sway/config".text = swayConfig;

    # Make the systemd init script and swaybg available in the environment
    environment.systemPackages = [ swaySystemdInit pkgs.swaybg ];

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
