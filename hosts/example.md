# Host Configuration Options

This document provides a quick reference for major configuration blocks available in host configurations.

## Configuration Template

Copy this template into your host configuration and trim what you don't need:

```nix
{
  inputs,
  overlays,
}:

let
  system = "x86_64-linux";  # or "aarch64-darwin" for macOS

  # Import abstract identity (the atom)
  privateIdentity = import ../../identities/private;

  # Translation: Convert abstract identity to concrete user on this host
  userConfig = {
    user = privateIdentity.commonName;
    gitName = privateIdentity.displayName;
    gitEmail = privateIdentity.email;
    homePath = "/home/${privateIdentity.commonName}";  # or "/Users/..." for macOS
  };
in

inputs.nixpkgs.lib.nixosSystem {  # or inputs.darwin.lib.darwinSystem for macOS
  inherit system;

  modules = [
    ../../modules/shared
    # ../../modules/wsl  # WSL-specific
    # ../../modules/darwin  # Darwin-specific
    inputs.home-manager.nixosModules.home-manager

    # Theme configuration (import theme module)
    ../../themes/gruvbox  # or ../../themes/ashes

    # User configuration
    userConfig

    {
      # Core Configuration (Required)
      networking.hostName = "hostname";
      system.stateVersion = "25.05";  # NixOS: string, Darwin: integer

      # Theme variant (set after importing theme module above)
      theme.variant = "dark";  # Options depend on theme (e.g., gruvbox: "dark" or "light", ashes: "dark")

      # GUI
      gui.enable = false;

      # Unfree Packages
      unfreePackages = [ "1password-cli" ];

      # Applications
      _1password-cli.enable = true;
      wezterm.enable = true;

      # Integrations (WSL-specific)
      integrations.cursorIde.enable = true;
      integrations.dockerDesktop.enable = true;
      integrations.vscode = {
        enable = true;
        windowsBinPath = "/mnt/c/Users/username/AppData/Local/Programs/Microsoft VS Code/bin";
      };

      # Signing (Service-based)
      signing = {
        service = "gpg-agent";  # "gpg-agent", "pkcs11", "ssh-agent", or "sigstore"
        keyId = "0xABCD1234";
        signByDefault = true;
      };

      # Desktop
      wallpaper = {
        enable = true;
        source = inputs.walls;
        # Static: path = "gruvbox/wallpaper.jpg";
        # Dynamic:
        dynamic = {
          interval = "hourly";  # "hourly", "daily", or "weekly"
          filter = path: builtins.match "^apeiros/.*" path != null;
        };
      };

      # Toolchains
      toolchain.nix.enable = true;
      toolchain.kubernetes.enable = true;

      # System-Specific (Darwin only)
      system.primaryUser = userConfig.user;
    }
  ];
}
```

## Option Definitions

For detailed option definitions, see the module files:

- **Core options** (`user`, `theme`, `gui`, `unfreePackages`, `homePath`, `dotfilesPath`): `modules/shared/default.nix`
- **Applications**: `modules/shared/applications/`
- **Signing**: `modules/shared/signing.nix`
- **Desktop/Wallpaper**: `modules/shared/wallpaper/`
- **Toolchains**: `modules/shared/programming/`
- **Shell**: `modules/shared/shell/`
- **WSL Integrations**: `modules/wsl/integrations/`
- **Darwin-specific**: `modules/darwin/`

## Notes

- User configuration (`user`, `gitName`, `gitEmail`, `homePath`) is set via `userConfig` from identity translation in the host file
- Options are typically enabled/disabled via `.enable` boolean flags
- Themes are imported as modules (e.g., `../../themes/gruvbox`) and variants are set via `theme.variant`
- Each theme defines its own available variants (e.g., gruvbox: `["dark" "light"]`, ashes: `["dark"]`)
- Identity information is translated from `identities/` into `userConfig` in each host
