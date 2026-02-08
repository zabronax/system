{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf (!pkgs.stdenv.isDarwin) {
    # Set default locale to American English
    # Hosts can override this by setting i18n.defaultLocale directly
    i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  };
}
