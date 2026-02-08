# mani

Bare metal NixOS laptop host - ASUS ROG Zephyrus G15 gaming laptop.

> [!CAUTION]
>
> This is a fresh host under active and heavy development. As the first bare metal NixOS host in this repository, expect significant configuration changes and reorganization as hardware integration and desktop environment setup evolves.

## Overview

**mani** is a private backup laptop and portable workstation. First pure NixOS desktop host in this repository (non-WSL), configured with NVIDIA GPU support and full hardware integration.

- **Architecture**: `x86_64-linux`
- **Purpose**: Backup laptop / Portable workstation

## Hardware

### Core Specifications

- **CPU**: AMD Ryzen 9 6900HS (8-core/16-thread)
- **GPU**: NVIDIA GeForce RTX 3080 Laptop GPU (8GB GDDR6)
- **GPU**: AMD Radeon Graphics (integrated)
- **Memory**: 32GB DDR5
- **Storage**: 953.9GB NVMe SSD (WD PC SN735)

## Installation

### Prerequisites

1. Fresh NixOS installation or existing NixOS system
2. Flakes enabled

### Build and Switch

```sh
sudo nixos-rebuild switch --flake github:zabronax/system#mani
```

Or from a local checkout:

```sh
sudo nixos-rebuild switch --flake .#mani
```

## Configuration Structure

The configuration is organized from a PC builder's perspective:

- **`platform.nix`**: Hardware-specific platform configuration organized by physical hardware components:
  - Motherboard and soldered components (CPU, firmware, kernel modules)
  - Custom motherboard extensions (power buttons, console keymap)
  - System boot configuration (bootloader, filesystems, kernel parameters)
  - Capability extension devices (NVIDIA GPU, audio)
  - Capability communication devices (network interfaces, printing)
- **`default.nix`**: Host-specific configuration (applications, user accounts, desktop environment)
- **Shared modules**: Common configuration shared across hosts (time, i18n, graphical environment)

## Key Configuration

The following hardware capabilities are configured:

- **NVIDIA GPU**: Proprietary drivers with PRIME sync (NVIDIA as primary, AMD integrated)
- **Network**: NetworkManager with explicit MAC address configuration for wired and wireless interfaces
- **Audio**: PipeWire with ALSA and PulseAudio compatibility
- **Power Management**: Suspend on power button, sleep mode configuration (s2idle)
- **Graphical Environment**: Sway tiling window manager with Wayland compositor
- **Launcher**: Walker application launcher with Elephant backend
- **Theme**: Ashes dark theme (Base16 colorscheme)

## Documentation

- **[snapshot/hardware-dump](./snapshot/hardware-dump)**: Complete hardware information dump (see [findings.md](./findings.md) for privacy considerations)
- **[official-spec.html](./official-spec.html)**: OEM specifications for display, I/O ports, physical dimensions, battery, and other details not extractable from hardware dumps

## Notes

- See [findings.md](./findings.md) for detailed notes on firmware bloat and hardware fingerprinting considerations
- Hardware dumps exclude dynamic runtime data (CPU frequencies, memory usage) and storage serial numbers for privacy
