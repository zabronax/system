{ config, lib, pkgs, ... }:

{
  # ============================================================================
  # Hardware Configuration - PC Builder's Perspective
  # ============================================================================
  # This configuration is organized from a PC builder's perspective, thinking
  # about how hardware is physically assembled and connected:
  #
  # 1. Motherboard and soldered components (CPU, chipset, firmware)
  # 2. Custom motherboard extensions (power buttons, LEDs, input devices)
  # 3. System boot configuration (bootloader, initrd, kernel)
  # 4. Capability extension devices (GPUs, audio, storage)
  # 5. Capability communication devices (NICs, Bluetooth, printing)
  # ============================================================================

  # ----------------------------------------------------------------------------
  # 1. Motherboard and Soldered Components
  # ----------------------------------------------------------------------------
  # CPU, chipset, firmware, and other components integrated into the motherboard

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Kernel modules for motherboard components (NVMe, USB, storage controllers)
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usbhid"
    "uas"
    "sd_mod"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [
  ];
  boot.kernelModules = [
    "kvm-amd"
  ];
  boot.extraModulePackages = [
  ];

  # ----------------------------------------------------------------------------
  # 2. Custom Motherboard Extensions
  # ----------------------------------------------------------------------------
  # Power buttons, LEDs, and other physical controls/extensions

  services.logind.settings.Login = {
    HandlePowerKey = "suspend";
  };

  # Note: Console keymap sync with X11 (console.useXkbConfig) is handled
  # by the desktop environment module (GNOME) since it's X11-dependent

  # ----------------------------------------------------------------------------
  # 3. System Boot Configuration
  # ----------------------------------------------------------------------------
  # Bootloader, initrd, kernel parameters, and filesystem mounts

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel parameters
  boot.kernelParams = [
    # System-level parameters
    "mem_sleep_default=s2idle"
    # NVIDIA GPU-specific parameters (see section 4 for GPU config)
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

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

  # ----------------------------------------------------------------------------
  # 4. Capability Extension Devices
  # ----------------------------------------------------------------------------
  # GPUs, audio cards, and storage devices that extend system capabilities

  # NVIDIA GPU (RTX 3080 Mobile)
  # Note: NVIDIA-specific kernel parameters are defined in section 3 (Boot Configuration)
  # Note: X11 video driver configuration (services.xserver.videoDrivers) is handled
  # by the desktop environment module (GNOME) since it's X11-specific
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

  # Audio (PipeWire replaces PulseAudio)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ----------------------------------------------------------------------------
  # 5. Capability Communication Devices
  # ----------------------------------------------------------------------------
  # Network interfaces, Bluetooth, printing, and other I/O devices

  # Network interfaces with explicit MAC address configuration
  networking.interfaces.eno1.macAddress = "58:11:22:40:62:1a";
  networking.interfaces.wlp3s0.macAddress = "b4:8c:9d:5d:5c:8d";
  networking.networkmanager.enable = true;

  # Printing (CUPS)
  services.printing.enable = true;
}
