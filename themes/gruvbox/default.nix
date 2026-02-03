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
      type = lib.types.enum [
        "dark"
        "light"
      ];
      description = "Gruvbox theme variant";
      default = "dark";
    };
  };

  config = {
    theme = {
      colorScheme = {
        colors = if config.theme.variant == "dark" then colorscheme.dark else colorscheme.light;
        dark = config.theme.variant == "dark";
      };
    };
  };
}
