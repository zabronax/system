# Issues (mani)

Known issues and instability experienced on the Mani host system. These issues have been observed across both the original Windows installation and the current NixOS installation.

## Sleep and Hibernation

**Severity:** High  
**Impact:** System becomes unresponsive, requires hard restart

The system frequently fails to resume properly from sleep or hibernation states. When attempting to wake the machine, it often remains unresponsive and requires a hard power cycle to recover. This issue was present on the original Windows installation, suggesting a hardware-level or firmware-level problem rather than an OS-specific configuration issue.

**Configuration:**
- Sleep mode: `s2idle` (deep sleep/S3 not supported by BIOS)
- ACPI reports: `ACPI: PM: (supports S0 S4 S5)` - S3 suspend-to-RAM missing
- NVMe device has platform quirk: `setting simple suspend`

**Root Cause:**
ACPI BIOS bugs affecting power management. The thermal zone error (`\_TZ.THRM._SCP.CTYP` not found) directly affects power state transitions. Combined with other ACPI bugs, this prevents reliable sleep/resume functionality.

**Resolution:**
Requires BIOS update from ASUS. Kernel parameter workarounds tested and found ineffective:
- `acpi_osi=Linux`: No improvement
- `acpi_osi=!Windows`: No improvement  
- `acpi=noirq`: Broke hardware (touchpad unresponsive)

**Current BIOS:** GA503RS.317 (02/27/2024)

## ACPI BIOS Bugs (Non-Fatal)

**Severity:** Low (Non-fatal)  
**Impact:** Error messages during boot, may contribute to power management issues

**Status:** Known BIOS bugs, non-fatal, system functions normally

Multiple ACPI BIOS errors appear during every boot (16 errors). These are BIOS-level bugs in the ACPI tables:

**ACPI Errors:**
- `AE_ALREADY_EXISTS` - Duplicate object definitions:
  - `\_SB.PCI0.GP19.NHI0._RST`, `\_SB.PCI0.GP19.NHI1._RST` (Thunderbolt/USB4)
  - `\_SB.PCI0.GPP6.WLAN` (WiFi adapter)
- `AE_NOT_FOUND` - Missing symbols:
  - `\_SB.PCI0.GPP2.WWAN`, `\_SB.PCI0.GPP5.RTL8`, `\_SB.PCI0.GPP7.DEV0`
  - `\_TZ.THRM._SCP.CTYP` (Thermal zone control type) ⚠️ Affects power management
- Keyboard controller errors: `atkbd serio0` deactivate/enable failures

**Resolution:** Requires BIOS update from ASUS to fix ACPI table bugs.

**Note:** These errors are non-fatal - the system boots successfully and functions normally. They may contribute to sleep/hibernation issues but do not prevent normal operation.

## Application Crashes

**Severity:** Low (Significantly Reduced)  
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
- See CPU hardware testing guide in snapshot directory for investigation methods

## Summary

**Resolved Issues:**
- ✅ GPU Configuration: NVIDIA configured as primary GPU via PRIME sync - crash frequency reduced by ~95%
- ✅ Early Boot Instability: Stabilized after GPU configuration fix
- ✅ Sleep Mode Configuration: Aligned with actual BIOS capabilities (s2idle)

**Active Issues:**
- ⚠️ Sleep/Hibernation: Fails to resume reliably (ACPI BIOS bugs)
- ⚠️ ACPI BIOS Bugs: 16 non-fatal errors per boot (requires BIOS update)
- ⚠️ Cursor Crashes: Occasional SIGILL crashes (reduced but not eliminated)

**Root Causes:**
- ACPI BIOS bugs (firmware-level, require BIOS update)
- CPU-level issues (SIGILL crashes suggest microcode or hardware problems)

**Next Steps:**
- Check for BIOS updates from ASUS (current: GA503RS.317, 02/27/2024)
- Monitor Cursor crash patterns for CPU hardware defect indicators
- Continue monitoring system stability improvements from GPU fix
