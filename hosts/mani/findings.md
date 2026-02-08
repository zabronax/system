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

## Hardware Fingerprinting

The hardware dump script intentionally includes certain identifiers that can be used for hardware fingerprinting and device tracking. These are retained because they provide management value and can be changed or are already public.

### Network Identifiers

**MAC Addresses:**
- Ethernet (`eno1`): `58:11:22:40:62:1a`
- WiFi (`wlp3s0`): `b4:8c:9d:5d:5c:8d`
- MAC-based interface altnames: `enx58112240621a`, `wlxb48c9d5d5c8d`

MAC addresses are unique per network interface and can be used for device tracking on networks. They can be changed via NixOS configuration (`networking.interfaces.<name>.macAddress`), making them manageable if privacy concerns arise.

### Filesystem Identifiers

**Partition UUIDs:**
- Root filesystem (ext4): `5b624167-e3f7-4ced-9a9f-e5a8c8c101b3`
- Boot partition (vfat): `EEB3-1B0F`
- Swap partition: `fab8cf70-03d0-4b36-90ba-edbeee98dbac`

These UUIDs uniquely identify the partition layout and installation. They are already present in the public `hardware-configuration.nix` file, so filtering them from dumps would provide no additional privacy benefit. They can be regenerated during reinstallation if needed.

### Hardware Specifications

The dump includes detailed hardware specifications that contribute to fingerprinting:

- **CPU**: AMD Ryzen 9 6900HS (family 25, model 68, stepping 1)
- **GPU**: NVIDIA GeForce RTX 3080 Laptop GPU (Vendor 0x10de, Device 0x249c)
- **GPU**: AMD Radeon Graphics (Vendor 0x1002, Device 0x1681)
- **Storage**: WD PC SN735 SDBPNHH-1T00-1002 (953.9GB NVMe)
- **PCI Subsystem IDs**: Vendor 0x1043, Device 0x13dd (ASUS)
- **Memory**: 32GB total RAM, 9GB swap

These specifications are useful for NixOS configuration and hardware compatibility reference. While they contribute to device fingerprinting, they represent the hardware model rather than unique device identifiers.

### Filtered Identifiers

The following identifiers are intentionally filtered out for privacy:

- **Storage serial numbers**: Hardware-level identifiers that cannot be changed and have low management value after warranty expiration.

## Hardware Dump Methodology

The current hardware dump technique (plain text file) has limitations:

- **Noisy diffs**: Runtime measurements (bogomips, kernel module load order) create large diffs with no meaningful changes
- **Poor change tracking**: Difficult to identify actual hardware changes vs. runtime variance
- **Limited analysis**: No structured querying or analytical capabilities
- **Large file size**: Entire dump must be regenerated and compared as a whole

### Future Improvements

Consider moving to a structured, queryable format for hardware dumps:

- **DuckDB**: Analytical database format that can be persisted in the repository
  - Better facilities for tracking changes over time (temporal queries, versioning)
  - Structured schema allows filtering noise (runtime measurements) from actual hardware changes
  - Query capabilities enable targeted analysis without regenerating entire dumps
  - Compact binary format with efficient compression
  - Can export to various formats for analysis or review

This would provide better change tracking, reduce noise in version control, and enable more sophisticated hardware analysis over time.
