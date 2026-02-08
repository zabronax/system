{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.applications = {
    cursor = {
      enable = lib.mkEnableOption {
        description = "Enable Cursor IDE (code-cursor-fhs). This is managed by home-manager, non-NixOS hosts might need more integrations.";
        default = false;
      };
    };
  };

  config = lib.mkIf (config.applications.cursor.enable) {
    home-manager.users.${config.user} = {
      home.packages = with pkgs; [
        code-cursor-fhs
      ];
    };
  };
}
