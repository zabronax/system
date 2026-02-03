{
  config,
  lib,
  ...
}:
{
  options = {
    docker-desktop = {
      enable = lib.mkEnableOption {
        description = "Enable Docker Desktop WSL integration.";
        default = false;
      };
    };
  };

  config = lib.mkIf config.docker-desktop.enable {
    wsl.docker-desktop.enable = true;
  };
}
