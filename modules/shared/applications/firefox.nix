{
  config,
  pkgs,
  lib,
  ...
}:

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
      };
    };
  };
}
