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

**Severity:** Medium (Reduced)  
**Impact:** Occasional application termination

**Status:** ✅ **Significantly Improved** - GPU configuration fix reduced crashes by ~95%

**Current State:**
- Cursor: Occasional SIGILL crashes (1 crash in ~10 minutes vs 31 crashes previously)
- Firefox: No crashes observed after GPU fix
- GNOME Shell: No crashes observed after GPU fix

**Remaining Issue:**
- Cursor still experiences occasional SIGILL (illegal instruction) crashes
- Suggests CPU-level or instruction execution problems
- May be related to FHS wrapper, CPU microcode, or hardware defects
- See CPU hardware testing guide for investigation methods

## Early Boot Instability

**Severity:** Medium (Improved)  
**Impact:** Occasional system issues shortly after boot

**Status:** ✅ **Improved** - GPU configuration fix appears to have stabilized boot process

**Current State:**
- Boot stability improved after GPU configuration fix
- No recent short boot cycles observed
- System appears stable after boot

**Remaining Concerns:**
- ACPI errors still present during boot (may affect power management)
- Thermal zone errors could still cause issues under certain conditions

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

3. **Dual GPU Configuration:** ✅ **RESOLVED**
   - NVIDIA RTX 3080 Laptop GPU + AMD Radeon Graphics (integrated)
   - **Status:** NVIDIA configured as primary GPU via PRIME sync
   - **Result:** Significant stability improvement, crash frequency reduced by ~95%
   - **Impact:** Resolved performance and stability issues

**Next Priority: ACPI Workarounds** ⚠️

**Status:**
- ✅ Sleep mode configuration aligned (deep → s2idle)
- ⏳ ACPI error workarounds pending

**Remaining Issues:**
- Sleep/hibernation failures (ACPI-related)
- Boot-time ACPI errors (16 errors per boot)
- Thermal zone errors affecting power management

## Current Priority: ACPI Workarounds ⚠️

**Status:** Step 1 completed, Step 2 pending

**Rationale:**
ACPI BIOS bugs are affecting sleep/hibernation and causing boot-time errors. Kernel parameter workarounds are:
- **Low risk:** Easy to test and revert
- **Quick to implement:** Can be tested immediately
- **High potential impact:** May address sleep/resume and boot stability issues
- **Non-invasive:** No hardware changes or BIOS flashing required

**Step 1: Align Sleep Mode Configuration** ✅ **COMPLETED**

Investigation revealed that deep sleep (S3) is not supported by ACPI/BIOS - only `s2idle` is available.

**Action Taken:** Modified `boot.kernelParams` in `hosts/mani/configuration.nix`:
- Changed `mem_sleep_default=deep` → `mem_sleep_default=s2idle`
- Aligns configuration with actual system capabilities

**Step 2: Add ACPI Error Suppression/Workarounds** 🔄 **IN PROGRESS**

Add kernel parameters to work around specific ACPI bugs. Test parameters one at a time:

**Parameter 1: `acpi_osi=Linux`** ❌ **NO IMPROVEMENT**
- **Purpose:** Override OS identification (may help with vendor-specific bugs)
- **Result:** Parameter active but no reduction in ACPI errors (still 16 errors)
- **Conclusion:** BIOS bugs are structural and not affected by OS identification

**Parameter 2: `acpi_osi=!Windows`** ❌ **NO IMPROVEMENT**
- **Purpose:** Tell BIOS we're not Windows (may improve compatibility)
- **Result:** Parameter active but no reduction in ACPI errors (still 16 errors)
- **Conclusion:** OS identification parameters don't affect structural BIOS bugs

**Parameter 3: `acpi=noirq`** ❌ **BROKE FUNCTIONALITY**
- **Purpose:** Disable ACPI IRQ routing (may help with initialization issues)
- **Result:** Touchpad became unresponsive - hardware functionality broken
- **Conclusion:** Disabling ACPI IRQ routing breaks hardware that relies on ACPI interrupts
- **Action:** Reverted parameter - not viable workaround

**ACPI Workaround Summary:**
- ✅ `acpi_osi=Linux`: No improvement (16 errors remain)
- ✅ `acpi_osi=!Windows`: No improvement (16 errors remain)
- ❌ `acpi=noirq`: Broke hardware (touchpad unresponsive)

**Conclusion:**
ACPI kernel parameter workarounds are not effective for these BIOS bugs:
- OS identification parameters don't affect structural ACPI table bugs
- Disabling ACPI features breaks hardware functionality
- BIOS bugs are fundamental and require BIOS updates or different approach

**Remaining Option:**
- `acpi=strict` - Use strict ACPI compliance (may expose more issues, not recommended)
- **Recommendation:** Skip remaining parameters - not effective for structural BIOS bugs

**Next Steps - BIOS Update Investigation:**

**Assessment:** BIOS update is the most likely path to fix ACPI bugs, but not guaranteed.

**Likelihood of Fix:** Moderate to High (60-70%)
- ✅ ACPI bugs are firmware-level issues that BIOS updates can fix
- ✅ Vendors often address ACPI table bugs in BIOS updates
- ⚠️ Not guaranteed - depends on whether ASUS identified/fixed these bugs
- ⚠️ Some ACPI bugs persist across BIOS versions

**Before BIOS Update:**
1. Check current BIOS version: `sudo dmidecode -s bios-version` or `/sys/class/dmi/id/bios_version`
2. Check ASUS support site for available BIOS updates for exact model
3. Read BIOS release notes for ACPI/thermal/power management fixes
4. Verify update is for exact model (ASUS ROG Zephyrus G15)

**Risks:**
- ⚠️ BIOS flashing can brick motherboard if it fails
- ⚠️ Ensure stable power (AC adapter) during flash
- ⚠️ Verify compatibility with hardware revision
- ⚠️ Have recovery plan if update fails

**Alternative if BIOS update unavailable/unhelpful:**
- Accept ACPI errors (non-fatal, system functions)
- Focus on other stability improvements (GPU fix already helped significantly)
- Monitor for kernel updates with better ACPI error handling

**Testing Plan:**
- Add one parameter at a time
- Rebuild and reboot
- Monitor boot logs for ACPI error reduction
- Test sleep/resume functionality
- Document results before trying next parameter

**Success Criteria:**
- Reduction in ACPI boot errors (currently 16 errors per boot)
- Improved sleep/resume reliability
- More stable boot process

**Note:** Avoid `acpi=off` as it disables ACPI entirely and breaks power management.
