{
  inputs,
}:

let
  system = "x86_64-linux";

  # Import abstract identity (the atom)
  identity = import ../../identities/zabronax;

  # Translation: Convert abstract identity to concrete user on this host
  # Direct mapping with host-specific details (homePath format, etc.)
  userConfig = {
    user = identity.commonName;
    email = identity.email;
    displayName = identity.displayName;
    # Host-specific: Linux/WSL uses /home/ prefix
    homePath = "/home/${identity.commonName}";
    # Host-specific: Windows username for WSL integration
    windowsUser = "larsg";
  };

in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  modules = [
    ../../modules/shared
    ../../modules/wsl
    inputs.wsl.nixosModules.wsl
    inputs.home-manager.nixosModules.home-manager

    # Theme configuration
    ../../themes/gruvbox

    # User configuration
    userConfig
    {
      # Configuration
      networking.hostName = "luna";

      # Theme variant
      theme.variant = "dark";

      # Integrations
      integrations.cursorIde.enable = true;
      integrations.dockerDesktop.enable = true;
      integrations.vscode = {
        enable = true;
        windowsBinPath = "/mnt/c/Users/${userConfig.windowsUser}/AppData/Local/Programs/Microsoft VS Code/bin";
      };

      # Development Toolchains
      toolchain.nix.enable = true;

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "25.05";
    }
  ];
}
