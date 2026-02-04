{
  inputs,
}:

let
  system = "aarch64-darwin";

  # Import abstract identity (the atom)
  identity = import ../../identities/zabronax;

  # Translation: Convert abstract identity to concrete user on this host
  # Direct mapping with host-specific details (homePath format, etc.)
  userConfig = {
    user = identity.commonName;
    email = identity.email;
    displayName = identity.displayName;
    # Host-specific: macOS uses /Users/ prefix
    homePath = "/Users/${identity.commonName}";
  };
in

inputs.darwin.lib.darwinSystem {
  inherit system;

  # The modules list is executed in order
  modules = [
    # Unfree predicate for system packages
    # Needs to happen before any nixpkgs consumers are called
    (
      { config, pkgs, ... }:
      {
        nixpkgs.config.allowUnfreePredicate =
          pkg:
          builtins.elem (pkgs.lib.getName pkg) [
            "1password-cli"
          ];
      }
    )

    # Shared modules
    ../../modules/shared
    ../../modules/darwin

    # Home Manager
    inputs.home-manager.darwinModules.home-manager

    # Theme configuration
    ../../themes/gruvbox

    # User configuration
    userConfig

    # Host specific configuration
    {
      # Configuration
      networking.hostName = "minmus";

      # Temporary fix for darwin-nix
      # TODO: Remove this once the "The Plan" is implemented (switching to system wide activation)
      # https://github.com/nix-darwin/nix-darwin/issues/1452
      system.primaryUser = userConfig.user;

      # Theme variant
      theme.variant = "dark";

      # Applications
      _1password-cli.enable = true;

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = 5;
    }
  ];
}
