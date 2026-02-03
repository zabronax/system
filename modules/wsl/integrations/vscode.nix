{
  config,
  lib,
  ...
}:
{
  options = {
    integrations = {
      vscode = {
        enable = lib.mkEnableOption {
          description = "Enable VS Code WSL integration.";
          default = false;
        };

        windowsBinPath = lib.mkOption {
          type = lib.types.str;
          description = "Full path to Windows VS Code binary directory (e.g., /mnt/c/Users/username/AppData/Local/Programs/Microsoft VS Code/bin).";
          default = "";
        };
      };
    };
  };

  config = lib.mkIf config.integrations.vscode.enable {
    # Enable the VS Code server for remote work
    programs.nix-ld.enable = true;

    # Add Windows side VS Code to PATH
    home-manager.users.${config.user}.home.sessionPath = lib.mkIf (
      config.integrations.vscode.windowsBinPath != ""
    ) [ config.integrations.vscode.windowsBinPath ];
  };
}
