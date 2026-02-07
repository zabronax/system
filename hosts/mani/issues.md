# Issues (mani)

Known issues and instability experienced on the Mani host system. These issues have been observed across both the original Windows installation and the current NixOS installation.

## Sleep and Hibernation

**Severity:** High  
**Impact:** System becomes unresponsive, requires hard restart

The system frequently fails to resume properly from sleep or hibernation states. When attempting to wake the machine, it often remains unresponsive and requires a hard power cycle to recover. This issue was present on the original Windows installation, suggesting a hardware-level or firmware-level problem rather than an OS-specific configuration issue.

**Configuration Observed:**
- Kernel command line includes `mem_sleep_default=deep` (deep sleep mode)
- Systemd-logind is configured to watch sleep button (`/dev/input/event10`)
- Hibernate storage info clearing skipped (EFI variable not present)
- NVMe device has platform quirk: `setting simple suspend`

**ACPI Issues Related to Sleep:**
The boot-time ACPI errors include thermal zone problems (`\_TZ.THRM._SCP.CTYP` not found) which directly affect power management. The ACPI BIOS bugs observed during boot likely also affect suspend/resume operations.

**Potential causes:**
- **BIOS/UEFI firmware bug:** ACPI table errors suggest firmware-level bugs affecting power management
- **ACPI thermal zone failure:** Missing thermal control type prevents proper power state transitions
- **Dual GPU power management:** NVIDIA + AMD GPU combination may cause resume failures
- **NVMe suspend quirks:** Platform-specific suspend handling may be incompatible with deep sleep

## Boot-Time Errors

**Severity:** Medium  
**Impact:** Error messages displayed during boot sequence

Multiple ACPI BIOS errors appear during every boot. These are BIOS-level bugs (not OS issues) that occur during ACPI table parsing:

**ACPI Errors Observed:**
- `AE_ALREADY_EXISTS` errors for duplicate object creation:
  - `\_SB.PCI0.GP19.NHI0._RST` (Thunderbolt/USB4 controller reset)
  - `\_SB.PCI0.GP19.NHI1._RST` (Thunderbolt/USB4 controller reset)
  - `\_SB.PCI0.GPP6.WLAN` (WiFi adapter)
- `AE_NOT_FOUND` errors for missing symbols:
  - `\_SB.PCI0.GPP2.WWAN` (WWAN device not present)
  - `\_SB.PCI0.GPP5.RTL8` (Realtek device not present)
  - `\_SB.PCI0.GPP7.DEV0` (Unknown device)
  - `\_TZ.THRM._SCP.CTYP` (Thermal zone control type)
- Keyboard controller errors:
  - `atkbd serio0: Failed to deactivate keyboard on isa0060/serio0`
  - `atkbd serio0: Failed to enable keyboard on isa0060/serio0`

**Analysis:**
These errors indicate the BIOS ACPI tables contain bugs (duplicate definitions, missing devices, incomplete thermal management). While the system boots successfully, these errors may contribute to power management issues and hardware initialization problems. The thermal zone error (`\_TZ.THRM._SCP`) is particularly concerning as it relates to power management and could affect sleep/hibernation functionality.

## Application Crashes

**Severity:** Medium  
**Impact:** Random application termination during normal use

Multiple applications experience frequent unexpected crashes during normal operation. Log analysis shows a pattern of crashes occurring in clusters, suggesting system-wide instability events.

**Crash Patterns Observed:**

**Cursor (Electron App):**
- **Packaging:** Cursor is installed as `code-cursor-fhs`, wrapped in an FHS (Filesystem Hierarchy Standard) environment using bubblewrap (`bwrap`)

- **FHS Wrapping Context:**
  NixOS uses a non-standard filesystem layout where packages are stored in `/nix/store/` with content-addressed paths. Electron applications like Cursor expect a traditional Linux filesystem hierarchy (`/usr/lib`, `/lib64`, `/bin`, etc.) and often have hardcoded library paths or use dynamic linking assumptions that don't work in NixOS's isolated store model.
  
  The `code-cursor-fhs` package wraps Cursor in an FHS-compatible environment using `bwrap` (bubblewrap), which creates a lightweight namespace-based sandbox. This wrapper:
  - Mounts an FHS rootfs containing standard Linux directory structure
  - Provides bind mounts for `/usr`, `/lib`, `/lib64`, `/bin`, `/etc`, etc. from the FHS environment
  - Allows Cursor's Electron runtime and native Node.js modules to find expected libraries and paths
  - Maintains isolation while providing compatibility with traditional Linux application expectations
  
  This is a common pattern in NixOS for proprietary or binary-only applications that cannot be easily patched to work with Nix's store model.

- **Crash Signals:**
  - **Most common:** `SIGTRAP` (signal 5) - Breakpoint/trap exceptions
  - **Frequent:** `SIGSEGV` (signal 11) - Segmentation faults
  - **Occasional:** `SIGILL` (signal 4) - Illegal instruction exceptions

- Crash frequency: Multiple crashes per hour during active use
- Core dumps show crashes in native modules (`file_service.linux-x64-gnu.node`) and main process
- Recent example: 10+ crashes within 5 minutes (Feb 7, 23:45-23:50)

- **FHS Wrapping Implications:**
  The FHS wrapper adds an additional layer of complexity and potential failure points:
  - **Library binding issues:** Native modules may link against libraries in the FHS environment that have version mismatches or incompatibilities with the actual system libraries
  - **System call interposition:** The `bwrap` sandbox intercepts and filters system calls, which could affect low-level operations in native code
  - **Path resolution complexity:** Multiple layers of path resolution (Nix store → FHS mount → actual filesystem) could introduce edge cases
  - **Graphics/GPU access:** The wrapper must properly expose GPU devices and graphics libraries, which may be complicated by dual GPU configuration (NVIDIA + AMD)
  
  While the FHS wrapper itself shouldn't directly cause crashes, any instability in the underlying system (memory corruption, GPU driver issues, CPU microcode problems) could be exacerbated by the additional abstraction layer. The crashes in native Node.js modules (`file_service.linux-x64-gnu.node`) suggest issues with native code execution, which could be affected by:
  - Library version mismatches between FHS environment and system
  - Graphics driver interactions through the wrapper
  - System call filtering or sandbox restrictions
  - Memory access patterns that interact poorly with the namespace isolation

**Mozilla Firefox:**
- Crashes in `WebKitWebProcess` child processes
- `SIGSEGV` and `SIGABRT` signals observed
- Exception handler messages indicate crash recovery attempts
- Multiple WebKit processes crashing simultaneously suggests memory corruption or graphics driver issues

**GNOME Shell:**
- `SIGSEGV` crashes observed
- Core dump inaccessible in at least one instance

**Analysis:**
The variety of crash types (`SIGTRAP`, `SIGSEGV`, `SIGILL`) affecting multiple applications suggests:
- Potential memory corruption (hardware or driver-related)
- Graphics driver instability (affects Electron apps and compositor)
- CPU instruction execution issues (SIGILL suggests hardware or microcode problems)
- System-wide instability events causing cascading failures

The clustering of crashes suggests periodic system-wide instability rather than isolated application bugs.

## Early Boot Instability

**Severity:** High  
**Impact:** System freeze or user session termination shortly after boot

Boot log analysis reveals numerous extremely short boot sessions, indicating frequent early boot failures or forced restarts:

**Boot Session Analysis:**
- Multiple boots lasting only seconds to minutes before termination
- Example pattern (Feb 7, 11:11-11:22): 9 consecutive boots with durations ranging from 19 seconds to 14 minutes
- Many boots show identical start/end times, indicating immediate failures or forced restarts

**Observed Manifestations:**
- User session unexpectedly terminating (kicked to login screen)
- Complete system freeze requiring hard restart
- GNOME Shell crashes immediately after boot (observed: `SIGSEGV` crash at 23:44:44)

**Potential Root Causes:**
The combination of ACPI errors, graphics driver initialization, and thermal management issues during boot suggests:

- **ACPI initialization failures:** The thermal zone error (`\_TZ.THRM._SCP`) during boot may cause power management initialization to fail
- **Graphics driver issues:** NVIDIA driver initialization with `nvidia-drm.modeset=1` combined with dual GPU (NVIDIA + AMD) may cause conflicts
- **Hardware initialization race conditions:** Multiple PCI devices initializing simultaneously may cause timing issues
- **Memory instability:** Early boot memory access patterns may trigger hardware-level memory errors

**Frequency:** Frequent - multiple short boot cycles observed, suggesting this is a recurring issue rather than intermittent.

## Summary and Root Cause Analysis

**Common Threads:**
All documented issues appear to stem from underlying hardware or firmware problems rather than OS configuration:

1. **ACPI BIOS Bugs:** The ACPI table errors are BIOS-level bugs that affect:
   - Power management (sleep/hibernation)
   - Thermal management (boot instability)
   - Hardware initialization (boot errors)

2. **Hardware Instability Indicators:**
   - `SIGILL` (illegal instruction) crashes suggest CPU microcode or hardware execution issues
   - Clustered crashes across multiple applications indicate system-wide events
   - Frequent short boot cycles suggest hardware-level failures
   - Memory testing completed prior to NixOS migration: no errors or warnings detected

3. **Dual GPU Configuration:**
   - NVIDIA RTX 3080 Laptop GPU + AMD Radeon Graphics
   - Graphics driver initialization conflicts may contribute to crashes and boot instability
   - Power management complexity with dual GPUs may affect sleep/resume

**Recommended Investigation Steps:**

1. **BIOS/UEFI Firmware:**
   - Check for BIOS updates from ASUS
   - Review ACPI-related BIOS settings
   - Consider disabling unused hardware (WWAN, Thunderbolt) if not needed

2. **Graphics Driver Configuration:**
   - Test with single GPU mode (disable NVIDIA or AMD)
   - Review NVIDIA driver parameters and power management settings
   - Check for graphics driver updates

3. **ACPI Workarounds:**
   - Consider kernel parameters to work around ACPI bugs
   - Test different sleep modes (`mem_sleep_default=s2idle` vs `deep`)
   - Monitor ACPI errors during suspend/resume attempts

4. **Hardware Diagnostics:**
   - Check CPU microcode version and updates
   - Review system temperatures during crashes
   - Test with minimal hardware configuration
