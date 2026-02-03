{
  description = "My systems";

  inputs = {
    # Used for system packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Used for MacOS system config
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Windows Subsystem for Linux config
    wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Used for dynamic user files
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Used for dynamically linked libraries
    # Required for VS Code Server in WSL derivations
    nix-ld-rs = {
      url = "github:nix-community/nix-ld-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Wallpapers repository
    # TODO! This repository is large (3.2GB). We should likely move this
    # out of band and do local cloning to speed up the build process.
    walls = {
      url = "github:dharmx/walls/main";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      # Modifications to the declared inputs
      overlays = [ ];

      # Helpers for generating attribute sets across systems
      supportedSystems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin" # TODO! Not verified, but likely to work
        "aarch64-linux" # TODO! Not verified, but likely to work
      ];
      withSystem = nixpkgs.lib.genAttrs supportedSystems;
      withPkgs = callback: withSystem (system: callback (import nixpkgs { inherit system; }));
    in
    {
      # Full NixOS builds
      nixosConfigurations = {
        luna = import ./hosts/luna { inherit inputs overlays; };
      };

      # Full macOS builds
      darwinConfigurations = {
        lupus = import ./hosts/lupus { inherit inputs overlays; };
        minmus = import ./hosts/minmus { inherit inputs overlays; };
      };

      # Standalone applications
      packages = { };

      # Development environments
      devShells = withPkgs (pkgs: {
        # For working on this repository
        default = pkgs.mkShell {
          packages = [
            pkgs.git
            pkgs.vim
          ];
        };
      });

      # For formatting the repository
      # "nix fmt"
      formatter = withPkgs (pkgs: pkgs.nixfmt);
    };
}
