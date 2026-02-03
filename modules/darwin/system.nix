{
  pkgs,
  lib,
  config,
  ...
}:

{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    # Nice list of options:
    # https://mynixos.com/nix-darwin/options
    environment.shells = [ pkgs.fish ];
    security.pam.services.sudo_local.touchIdAuth = true;

    system = {
      defaults = {

        NSGlobalDomain = {
          # Hide the menu bar
          _HIHideMenuBar = false;
          # Show all extensions
          AppleShowAllExtensions = true;
          # Always show all files
          AppleShowAllFiles = true;
          # Set dark mode based on theme configuration
          AppleInterfaceStyle = if config.theme.colorScheme.dark then "Dark" else "Light";

          # Disable animations for instant, snappy UI
          # Window animations
          NSWindowResizeTime = 0.001; # Nearly instant window resizing
          NSAutomaticWindowAnimationsEnabled = false; # Disable window open/close animations

          # Additional performance tweaks
          ApplePressAndHoldEnabled = false; # Disable press-and-hold character picker (faster typing)
        };

        # Reduce motion and disable transparency for performance
        # Using CustomSystemPreferences as universalaccess domain has write restrictions
        CustomSystemPreferences."com.apple.Accessibility" = {
          ReduceMotionEnabled = 1; # Reduce motion globally
          ReduceTransparencyEnabled = 1; # Disable transparency effects
        };

        # Displays have separate Spaces (improves performance, reduces glitching)
        # https://nikitabobko.github.io/AeroSpace/guide#a-note-on-displays-have-separate-spaces
        spaces.spans-displays = false; # Each display gets separate Spaces

        dock = {
          # Automatically show and hide the dock
          autohide = true;

          # Add translucency in dock for hidden applications
          showhidden = true;

          # Enable spring loading on all dock items
          enable-spring-load-actions-on-all-items = true;

          # Highlight hover effect in dock stack grid view
          mouse-over-hilite-stack = true;

          # Disable dock animation for instant response
          mineffect = "scale"; # Fastest minimize effect (scale is faster than genie/suck)
          orientation = "left";
          show-recents = false;
          tilesize = 44;

          # Disable dock animations
          launchanim = false; # Disable launch animations
          autohide-delay = 0.0; # Instant dock hide/show
          autohide-time-modifier = 0.0; # No animation delay
          expose-animation-duration = 0.0; # Instant Mission Control animations

          persistent-apps = [
            "/Applications/1Password.app"
            "${pkgs.wezterm}/Applications/WezTerm.app"
          ];
        };
      };
    };

    # Fix for: 'Error: HOME is set to "/var/root" but we expect "/var/empty"'
    home-manager.users.root.home.homeDirectory = lib.mkForce "/var/root";
  };
}
