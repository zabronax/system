# Host Configuration Options

This document provides a quick reference for major configuration blocks available in host configurations.

## Configuration Template

Copy this template into your host configuration and trim what you don't need:

```nix
{
  # Core Configuration (Required)
  networking.hostName = "hostname";
  system.stateVersion = 5;  # NixOS: "25.05" (string), Darwin: 5 (integer)

  # Theme
  theme = {
    colors = (import ../../colorscheme/gruvbox-dark).dark;
    dark = true;
  };

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
- Theme colors should be imported from `colorscheme/` directory
- Identity information is translated from `identities/` into `userConfig` in each host
