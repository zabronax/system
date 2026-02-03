{
  config,
  lib,
  ...
}:
{
  options = {
    cursor = {
      enable = lib.mkEnableOption {
        description = "Enable Cursor IDE WSL compatibility.";
        default = false;
      };
    };
  };

  config = lib.mkIf config.cursor.enable {
    # Necessary hack for getting Cursor IDE WSL side server install script to work.
    # This wraps /bin/sh and adds bash to extraBin to allow Cursor's WSL side server install script to work.
    wsl = {
      wrapBinSh = true;
      extraBin = [
        {
          name = "bash";
          src = config.wsl.binShExe;
        }
      ];
    };
  };
}
