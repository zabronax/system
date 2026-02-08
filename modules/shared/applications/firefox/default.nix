{
  config,
  pkgs,
  lib,
  ...
}:

let
  uiStyling = import ./ui-styling.nix {
    colorScheme = config.theme.colorScheme;
  };
in
{
  options.applications = {
    firefox = {
      enable = lib.mkEnableOption {
        description = "Enable Firefox.";
        default = false;
      };
    };
  };

  config = lib.mkIf config.applications.firefox.enable {
    home-manager.users.${config.user} = {
      programs.firefox = {
        enable = true;
        profiles.default = {
          # Enable userChrome.css support
          settings = {
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            # Use system colors based on theme
            "browser.display.use_system_colors" = true;
            # Set color scheme based on host's theme configuration
            "ui.systemUsesDarkTheme" = if config.theme.colorScheme.dark then 1 else 0;
          };

          # Apply colorScheme to Firefox UI via userChrome.css
          userChrome = uiStyling;
        };
      };
    };
  };
}
