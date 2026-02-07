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
    # Host-specific: Linux uses /home/ prefix
    homePath = "/home/${identity.commonName}";
  };
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  modules = [
    # Shared modules
    ../../modules/shared

    # Home Manager
    inputs.home-manager.nixosModules.home-manager

    # Theme configuration
    ../../themes/ashes

    # Identity configuration
    userConfig

    # Bootstrap configuration
    ./configuration.nix

    # Host specific configuration
    ({ config, pkgs, ... }: {
      # Configuration
      networking.hostName = "mani";

      # Theme variant
      theme.variant = "dark";

      # Applications
      wezterm.enable = true;

      # Programming Toolchains
      toolchain.nix.enable = true;

      # Define a user account. Don't forget to set a password with ‘passwd’.
      users.users.${userConfig.user} = {
        isNormalUser = true;
        description = userConfig.displayName;
        extraGroups = [ "networkmanager" "wheel" ];
        packages = with pkgs; [
          git
          vim
          wget
          mesa-demos # GPU Utilities
          code-cursor-fhs
        ];
      };
    })
  ];
}
