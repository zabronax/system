<h1 align="center">
 <!-- Project Logo and Slogan/One-liner  -->
 <img height="160" src="https://brand.nixos.org/logos/nixos-logo-rainbow-gradient-white-regular-horizontal-recommended.svg" />
 <p>Nix System Config for <a href="https://github.com/zabronax">zabronax</a></p>
</h1>

<p align="center">
 <!-- Project and Repo information -->
 <a href="https://github.com/zabronax/system/stargazers"><img src="https://img.shields.io/github/stars/zabronax/system?colorA=282828&colorB=fabd2f&style=for-the-badge"></a>
 <a href="https://github.com/zabronax/system/commits"><img src="https://img.shields.io/github/last-commit/zabronax/system?colorA=282828&colorB=d79921&style=for-the-badge"></a>
 <a href="https://github.com/zabronax/system/blob/main/LICENSE"><img src="https://img.shields.io/github/license/zabronax/system?colorA=282828&colorB=83a598&style=for-the-badge"></a>
 <a href="https://wiki.nixos.org/wiki/Flakes" target="_blank">
 <img alt="Nix Flakes Ready" src="https://img.shields.io/static/v1?logo=nixos&logoColor=ebdbb2&label=Nix%20Flakes&labelColor=458588&message=Ready&color=ebdbb2&style=for-the-badge"></a>
</p>
<p align="center">
  <!-- CI and Reconciliation Status -->
 <a href="https://github.com/zabronax/system/stargazers"><img alt="GitHub Actions Workflow Status" src="https://img.shields.io/github/actions/workflow/status/zabronax/system/reconcile-main.yaml?style=for-the-badge&label=CI"></a>
</p>

This is my repository for tracking and evolving the machines, nodes, and user environments I use. It contains my declarative configuration for reproducible and versioned systems, allowing me to define, share, and maintain consistent environments across different platforms. By expressing system state as code, I can version control changes, roll back to previous configurations, and ensure that my systems remain reproducible and maintainable over time.

> [!IMPORTANT]
> This repository is primarily for my personal machines and workflows. It is public for inspiration and reference — not as a supported template. Expect breaking changes, host-specific assumptions, and zero compatibility guarantees.
>
> So keep your debugging skills sharp and happy scrounging!

## Motivation

While curiosity guided my exploration, the primary motivation for diving into Nix for fully declarative systems came from necessity. The catalyst was a string of bad luck: several laptops in a row that broke down after just 2-3 weeks of use due to MUX switch failures between integrated and dedicated GPUs.

After spending multiple weekends repeatedly configuring and installing everything from scratch, I was fed up. I needed a solution that would prevent me from wasting any more time on thankless setup work. This search led me to Nix, NixOS, Nix Flake Dev Shells, Darwin-Nix, and Nix-WSL.

Since then, I've stopped counting how many times I've switched hardware—it simply doesn't matter anymore. I can get fully set up in a matter of minutes across most setups I've tried (barring bandwidth constraints). This has taken a load off my shoulders and allows me to focus on the problems that actually matter.

## Architecture

This repository follows a clear separation of concerns:

- **Root Flake (`flake.nix`)**: Manages external inputs and exposes outputs.
- **Hosts (`hosts/`)**: Declare the composition of a host and its specific configuration. Host *wiring* lives here.
- **Modules (`modules/`)**: Provides configurable system modules split based on platform (shared, darwin, wsl)
- **Themes (`themes/`)**: Provide theme configurations.
- **Identities (`identities/`)**: Abstract identity definitions (OIDC/Certificate style).

> [!CAUTION]
>
> [identities](/identities/):
> **PUBLIC INFO ONLY**: No encryption is setup, so only add public info, like social handles and public keys. Assume everything here is public and scrapeable.

### Design Principles

1. **Hosts compose, modules provide**: Hosts declare what they need by importing modules and themes.
2. **Root flake is external interface-only**: The root flake only manages external dependencies and output declarations.
3. **Modules are host-agnostic**: Modules consume config values, never import identities or host-specific files.

## Quick Start

> [!NOTE]
>
> **Prerequisites**:
> Flakes enabled
> A platform installation of *One of*:
> - Nix-Darwin, for macOS
> - Nix-WSL, for Windows WSL
> - NixOS, for bare metal Linux

### macOS ([lupus](/hosts/lupus/))

```sh
sudo darwin-rebuild switch --flake github:zabronax/system#lupus
```

### WSL ([luna](/hosts/luna/))

```sh
sudo nixos-rebuild switch --flake github:zabronax/system#luna
```

### NixOS ([mani](/hosts/mani/))

```sh
sudo nixos-rebuild switch --flake github:zabronax/system#mani
```

## Hosts

See [`hosts/README.md`](hosts/README.md) for detailed host information.

| Hostname   | Architecture     | Platform | Description                      |
|------------|------------------|----------|----------------------------------|
| **lupus**  | `aarch64-darwin` | macOS    | Daily driver MacBook Air         |
| **minmus** | `aarch64-darwin` | macOS    | Minimal macOS system             |
| **luna**   | `x86_64-linux`   | WSL      | WSL development environment      |
| **mani**   | `x86_64-linux`   | NixOS    | Bare metal laptop (Sway/Wayland) |


## Structure

```sh
.
├── flake.nix          # External dependencies and output declarations
├── hosts/             # Host-specific compositions
│   ├── luna/          # WSL development environment
│   ├── lupus/         # Daily driver MacBook Air
│   ├── mani/          # Bare metal NixOS laptop
│   └── minmus/        # Minimal macOS system
├── modules/           # Reusable configuration modules
│   ├── darwin/        # macOS-specific modules
│   ├── linux/         # Linux-specific modules
│   ├── shared/        # Cross-platform modules
│   └── wsl/           # WSL-specific modules
├── themes/            # Theme configurations
│   ├── gruvbox/
│   └── ashes/
└── identities/        # Abstract identity definitions
    └── zabronax/      # Primary public identity
```

## Common Commands

```sh
# Format code
nix fmt

# Update flake lock
nix flake update

# Enter dev shell
nix develop

# Show available configurations
nix flake show
```
