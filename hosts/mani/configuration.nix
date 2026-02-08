{ config, lib, pkgs, ... }:

{
  # Hardware configuration (from nixos-generate-config)
  # Explicit replacement for installer/scan/not-detected.nix: enable
  # redistributable (non-free) firmware so NIC and other hardware work.
  hardware.enableRedistributableFirmware = true;

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "uas" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Explicit MAC address configuration for network interfaces
  networking.interfaces.eno1.macAddress = "58:11:22:40:62:1a";
  networking.interfaces.wlp3s0.macAddress = "b4:8c:9d:5d:5c:8d";

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/5b624167-e3f7-4ced-9a9f-e5a8c8c101b3";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/EEB3-1B0F";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/fab8cf70-03d0-4b36-90ba-edbeee98dbac"; }
    ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # NVIDIA configurations (RTX 3080 Mobile)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    # PRIME configuration: Use NVIDIA as primary GPU
    # NVIDIA RTX 3080: PCI:1:0:0 (0000:01:00.0)
    # AMD Radeon (integrated): PCI:6:0:0 (0000:06:00.0)
    prime = {
      sync.enable = true;
      nvidiaBusId = "PCI:1:0:0";
      amdgpuBusId = "PCI:6:0:0";
    };
  };
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "mem_sleep_default=s2idle"
  ];

  # Sync virtual console keymap with X11 keymap to avoid redundancy
  console.useXkbConfig = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.logind.settings.Login = {
    HandlePowerKey = "suspend";
  };
}
