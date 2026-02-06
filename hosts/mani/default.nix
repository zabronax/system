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
    # Host-specific: macOS uses /Users/ prefix
    homePath = "/home/${identity.commonName}";
  };
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  modules = [
    ./configuration.nix
  ];
}
