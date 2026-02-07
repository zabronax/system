# Findings (mani)

Notes and references from working on this bare metal host configuration.

## linux-firmware

NixOS exposes redistributable (non-free) firmware via `hardware.enableRedistributableFirmware`. Enabling it pulls in a single large derivation, `pkgs.linux-firmware`, which is the kernel.org firmware tree repackaged for Nix. That package is an excessively large closure (hundreds of MB even compressed; uncompressed can exceed 1 GB) [¹][1]. There is no built-in way to include only a subset (e.g. “just my NIC”); `hardware.firmware` accepts a list of packages, but nixpkgs does not ship split packages (e.g. per-vendor or per-directory) for the main blob [¹][1]. The module where `enableRedistributableFirmware` sets `hardware.firmware` to a fixed list including `linux-firmware` is [²][2].

Because everything lives in one derivation, we could limit the set ourselves by either an overlay or a custom derivation that subsets `linux-firmware` (e.g. by copying only the needed subdirs). nixpkgs maintainers have not taken on that responsibility, which is reasonable given they are repackaging the upstream linux-firmware tree.

### References

[¹][1] NixOS. "linux-firmware is really big," NixOS/nixpkgs, Issue #148197, Dec. 2021. [Online]. Available: <https://github.com/NixOS/nixpkgs/issues/148197>

[²][2] NixOS. "all-firmware.nix," nixpkgs, nixos/modules/hardware/all-firmware.nix. [Online]. Available: <https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/all-firmware.nix>

[1]: https://github.com/NixOS/nixpkgs/issues/148197
[2]: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/all-firmware.nix
