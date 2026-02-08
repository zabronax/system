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
    # Unfree predicate for system packages
    # Needs to happen before any nixpkgs consumers are called
    (
      { config, pkgs, ... }:
      {
        nixpkgs.config.allowUnfreePredicate =
          pkg:
          builtins.elem (pkgs.lib.getName pkg) [
            "nvidia-x11"
            "nvidia-settings"
            "code-cursor-fhs"
            "cursor"
          ];
      }
    )

    # Shared modules
    ../../modules/shared

    # Linux-specific modules
    ../../modules/linux

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

      # Time configuration
      time = {
        timeZone = "Europe/Oslo";
        timeAuthority = "systemd-timesyncd";
      };

      # Theme variant
      theme.variant = "dark";

      # Applications
      wezterm.enable = true;
      programs.firefox.enable = true;

      # Programming Toolchains
      toolchain.nix.enable = true;

      # Define a user account. Don't forget to set a password with ‘passwd’.
      users.users.${config.user} = {
        isNormalUser = true;
        description = config.displayName;
        extraGroups = [ "networkmanager" "wheel" ];
        packages = with pkgs; [
          git
          vim
          wget
          mesa-demos # GPU Utilities
          code-cursor-fhs
        ];
      };

      # Desktop (plain attrset, closes over inputs like lupus)
      wallpaper = {
        enable = true;
        source = inputs.walls;
        path = "aerial/aerial_view_of_a_city_at_night.jpg";
      };

      # Graphical Environment
      graphical = {
        enable = true;
        environment = "gnome";
      };

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It's perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "25.11"; # Did you read the comment?
    })

  ];
}
