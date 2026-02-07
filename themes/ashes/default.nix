{
  config,
  lib,
  pkgs,
  ...
}:
let
  colorscheme = import ./colorscheme.nix;
in
{
  imports = [ ../wallpaper ];

  options = {
    theme.variant = lib.mkOption {
      type = lib.types.enum [ "dark" ];
      description = "Ashes theme variant";
      default = "dark";
    };
  };

  config = {
    theme = {
      colorScheme = {
        colors = colorscheme.theme; # Ashes only has one variant
        dark = config.theme.variant == "dark";
      };
    };

    home-manager.users.${config.user} = {
      fonts.fontconfig = {
        defaultFonts = {
          monospace = [ "Monaspace Argon, Symbols Nerd Font" ];
        };
        enable = true;
      };
    };

    fonts.packages = with pkgs; [
      b612
      material-icons
      material-design-icons
      noto-fonts-color-emoji
      noto-fonts-monochrome-emoji
      cascadia-code
      monaspace
      nerd-fonts.symbols-only
    ];
  };
}
