{
  config,
  lib,
  ...
}:
{
  options = {
    integrations = {
      dockerDesktop = {
        enable = lib.mkEnableOption {
          description = "Enable Docker Desktop WSL integration.";
          default = false;
        };
      };
    };
  };

  config = lib.mkIf config.integrations.dockerDesktop.enable {
    wsl.docker-desktop.enable = true;
  };
}
