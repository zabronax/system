# Issues (mani)

Known issues and instability experienced on the Mani host system. These issues have been observed across both the original Windows installation and the current NixOS installation.

## Sleep and Hibernation

**Severity:** High  
**Impact:** System becomes unresponsive, requires hard restart

The system frequently fails to resume properly from sleep or hibernation states. When attempting to wake the machine, it often remains unresponsive and requires a hard power cycle to recover. This issue was present on the original Windows installation, suggesting a hardware-level or firmware-level problem rather than an OS-specific configuration issue.

**Configuration Observed:**
- Kernel command line was configured with `mem_sleep_default=deep` (deep sleep/S3 mode)
- Systemd-logind is configured to watch sleep button (`/dev/input/event10`)
- Hibernate storage info clearing skipped (EFI variable not present)
- NVMe device has platform quirk: `setting simple suspend`

**Sleep Mode Support Analysis:**
Investigation revealed that deep sleep (S3 suspend-to-RAM) is **not supported** by the ACPI/BIOS:
- ACPI reports: `ACPI: PM: (supports S0 S4 S5)` - only S0 (working), S4 (hibernate), and S5 (shutdown) are supported
- S3 (suspend-to-RAM/deep sleep) is missing from supported states
- `/sys/power/mem_sleep` shows only `s2idle` is available
- Despite kernel parameter requesting `deep`, the system was falling back to `s2idle` (modern standby)
- Configuration updated to `mem_sleep_default=s2idle` to align with actual capabilities

**ACPI Issues Related to Sleep:**
The boot-time ACPI errors include thermal zone problems (`\_TZ.THRM._SCP.CTYP` not found) which directly affect power management. The ACPI BIOS bugs observed during boot likely also affect suspend/resume operations. The lack of S3 support combined with ACPI bugs suggests the sleep issues are occurring with `s2idle` mode, which may be more sensitive to ACPI problems.

**Potential causes:**
- **BIOS/UEFI firmware bug:** ACPI table errors suggest firmware-level bugs affecting power management
- **ACPI thermal zone failure:** Missing thermal control type prevents proper power state transitions
- **Missing S3 support:** BIOS doesn't support traditional suspend-to-RAM, forcing use of s2idle
- **Dual GPU power management:** NVIDIA + AMD GPU combination may cause resume failures with s2idle
- **NVMe suspend quirks:** Platform-specific suspend handling may be incompatible with s2idle mode

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

3. **Dual GPU Configuration:** ⚠️ **TOP PRIORITY**
   - NVIDIA RTX 3080 Laptop GPU + AMD Radeon Graphics (integrated)
   - **Current state:** System running on Wayland with display driven by integrated AMD GPU
   - **Issue:** dGPU (NVIDIA) is loaded and available for offloading but not used as primary display GPU
   - Graphics driver initialization conflicts may contribute to crashes and boot instability
   - Power management complexity with dual GPUs may affect sleep/resume
   - **Impact:** Performance degradation, potential instability from GPU switching, power management issues

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

## GPU Configuration Issue ⚠️ **TOP PRIORITY**

**Severity:** High  
**Impact:** Performance degradation, potential instability, incorrect GPU usage

**Current State:**
- System running on Wayland (GNOME Shell)
- Display driven by integrated AMD Radeon GPU
- NVIDIA RTX 3080 dGPU is loaded and available but not used as primary display GPU
- NVIDIA GPU shows activity (GNOME Shell using 283MiB) but likely via offloading, not direct display
- Previously system was running exclusively on dGPU

**Investigation Findings:**
- `nvidia-smi` shows NVIDIA GPU is active and being used
- `glxinfo` shows NVIDIA RTX 3080 as OpenGL renderer (with PRIME offload)
- Both `nvidia-drm` and `amdgpu` drivers are loaded
- Wayland session type detected
- ACPI shows vga_switcheroo detected: `amdgpu: vga_switcheroo: detected switching method \_SB_.PCI0.GP17.VGA_.ATPX handle`

**Configuration Needed:**
- Configure NVIDIA as primary display GPU (or disable AMD iGPU)
- Set up proper PRIME configuration for Wayland
- Ensure dGPU is used exclusively for display output
- May require switching to X11 if Wayland doesn't support dGPU-only mode well

**Potential Impact on Other Issues:**
- GPU switching/power management may contribute to sleep/resume failures
- Dual GPU initialization conflicts may cause boot instability
- Incorrect GPU usage may affect application crashes (graphics driver issues)

## Recommended First Investigation Path

**Priority: GPU Configuration (dGPU Primary)** ⚠️ **UPDATED PRIORITY**

**Rationale:**
Observation indicates system is now running on integrated GPU instead of dGPU, which was previously working exclusively. This is likely contributing to:
- Performance issues
- Potential instability from GPU switching
- Sleep/resume problems (dual GPU power management)
- Application crashes (graphics driver conflicts)

Fixing GPU configuration should be prioritized as it may resolve multiple issues simultaneously.

**Step 1: Investigate Current GPU State** ✅ **IN PROGRESS**

**Findings:**
- NVIDIA GPU is loaded and active (`nvidia-smi` shows usage)
- Display appears to be driven by AMD iGPU
- Wayland session with both drivers loaded
- PRIME offloading available but not configured for primary use

**Step 2: Configure NVIDIA as Primary GPU** 🔄 **IN PROGRESS**

**GPU Bus IDs Identified:**
- NVIDIA RTX 3080: `PCI:1:0:0` (0000:01:00.0)
- AMD Radeon (integrated): `PCI:6:0:0` (0000:06:00.0)

**Configuration Options:**

**Option A: PRIME Sync (NVIDIA as primary)**
- Enable `hardware.nvidia.prime.sync.enable = true`
- Set `hardware.nvidia.prime.nvidiaBusId = "PCI:1:0:0"`
- Set `hardware.nvidia.prime.amdgpuBusId = "PCI:6:0:0"`
- **Note:** PRIME sync works better with X11 than Wayland

**Option B: Disable AMD iGPU**
- Add kernel parameter to disable AMD GPU: `amdgpu.blacklist=1` or similar
- May require BIOS setting to disable iGPU
- Forces NVIDIA-only mode

**Option C: Switch to X11**
- Better NVIDIA support and PRIME sync compatibility
- Can configure NVIDIA as exclusive display GPU
- May improve stability

**Option D: Keep Wayland with PRIME Offloading**
- Current setup (display on iGPU, render on dGPU)
- Configure environment variables for better dGPU usage
- Less ideal but may work if other options fail

**Action Plan:**
1. ✅ Identify GPU bus IDs
2. ✅ Configure PRIME sync with NVIDIA as primary (Option A)
   - Added `hardware.nvidia.prime.sync.enable = true`
   - Set `nvidiaBusId = "PCI:1:0:0"` (NVIDIA RTX 3080)
   - Set `amdgpuBusId = "PCI:6:0:0"` (AMD Radeon integrated)
3. ⏳ **Next:** Rebuild system and test
4. ⚠️ **Note:** PRIME sync works better with X11 than Wayland. If Wayland issues persist, may need to switch to X11 (Option C)
5. Monitor for stability improvements and GPU usage

**Previous Priority: ACPI Workarounds (Kernel Parameters)**

**Rationale:**
ACPI BIOS bugs are the root cause affecting multiple issues (sleep/hibernation, boot errors, early boot instability). Kernel parameter workarounds are:
- **Low risk:** Easy to test and revert
- **Quick to implement:** Can be tested immediately
- **High potential impact:** May address multiple issues simultaneously
- **Non-invasive:** No hardware changes or BIOS flashing required

**Step 1: Align Sleep Mode Configuration** ✅ **COMPLETED**

Investigation revealed that deep sleep (S3) is not supported by ACPI/BIOS - only `s2idle` is available. The kernel was requesting `deep` but falling back to `s2idle` anyway.

**Action Taken:** Modified `boot.kernelParams` in `hosts/mani/configuration.nix`:
- Changed `mem_sleep_default=deep` → `mem_sleep_default=s2idle`
- Aligns configuration with actual system capabilities
- Prevents kernel from attempting unsupported sleep mode

**Next Steps:**
- Rebuild system and test sleep/resume functionality
- Monitor for ACPI errors during suspend/resume
- If sleep still fails, proceed to Step 2 (ACPI workaround parameters)

**Step 2: Add ACPI Error Suppression/Workarounds**

If sleep mode change doesn't help, add kernel parameters to work around specific ACPI bugs:

**Potential parameters to test:**
- `acpi=noirq` - Disable ACPI IRQ routing (may help with initialization issues)
- `acpi=off` - Disable ACPI entirely (not recommended, breaks power management)
- `acpi=strict` - Use strict ACPI compliance (may expose more issues)
- `acpi_osi=Linux` - Override OS identification (may help with vendor-specific bugs)
- `acpi_osi=!Windows` - Tell BIOS we're not Windows (may improve compatibility)

**Step 3: Monitor and Document**

After each change:
- Monitor boot logs for ACPI error reduction
- Test sleep/resume functionality
- Track application crash frequency
- Document any improvements or regressions

**Success Criteria:**
- Reduction in ACPI boot errors
- Improved sleep/resume reliability
- Reduced application crash frequency
- More stable early boot behavior

**If ACPI workarounds don't help:**
Proceed to **Graphics Driver Configuration** testing (single GPU mode) as the next investigation path, as dual GPU configuration may be contributing to instability.
