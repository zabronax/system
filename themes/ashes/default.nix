{
  config,
  lib,
  ...
}:
let
  colorscheme = import ./colorscheme.nix;
in
{
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
  };
}
