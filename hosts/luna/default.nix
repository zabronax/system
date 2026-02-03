{
  inputs,
  overlays,
}:

let
  system = "x86_64-linux";

  # Import abstract identity (the atom)
  privateIdentity = import ../../identities/private;

  # Translation: Convert abstract identity to concrete user on this host
  # Direct mapping with host-specific details (homePath format, etc.)
  globals = {
    user = privateIdentity.username;
    gitName = privateIdentity.gitName;
    gitEmail = privateIdentity.gitEmail;
    # Host-specific: Linux/WSL uses /home/ prefix
    homePath = "/home/${privateIdentity.username}";
    # Host-specific: Windows username for WSL integration
    windowsUser = "larsg";
  };

in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  modules = [
    ../../modules/shared
    ../../modules/wsl
    globals
    inputs.wsl.nixosModules.wsl
    inputs.home-manager.nixosModules.home-manager
    {
      # Replace config with our directory, as it's sourced on every launch
      system.activationScripts.configDir.text = ''
        rm -rf /etc/nixos
        ln --symbolic --no-dereference --force /home/${globals.user}/system /etc/nixos
      '';

      # Configuration
      networking.hostName = "luna";

      theme = {
        colors = (import ../../colorscheme/gruvbox-dark).dark;
        dark = true;
      };

      # Integrations
      integrations.cursorIde.enable = true;
      integrations.dockerDesktop.enable = true;
      integrations.vscode = {
        enable = true;
        windowsBinPath = "/mnt/c/Users/${globals.windowsUser}/AppData/Local/Programs/Microsoft VS Code/bin";
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
