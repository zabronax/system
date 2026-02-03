{
  config,
  lib,
  ...
}:
{
  options = {
    windowsUser = lib.mkOption {
      type = lib.types.str;
      description = "Windows username for WSL integration (e.g., for VS Code paths).";
      default = "";
    };
  };

  config = {
    wsl = {
      enable = true;
      defaultUser = config.user;
      # Turn off if it breaks VPN
      wslConf.network.generateResolveConf = true;
      # Including Windows PATH will slow down other systems, filesystem cross talk
      interop.includePath = false;
      # Hack around fish not entered at boot
      wslConf.boot.command = "fish";
    };
  };
}
