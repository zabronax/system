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
- Cursor: Multiple crash types observed (SIGILL, SIGTRAP, SIGSEGV)
- Firefox: No crashes observed after GPU fix
- GNOME Shell: No crashes observed after GPU fix

**Cursor Crash Patterns:**

**Version 2.4.21 (prior to update):**
- 6 SIGILL (Illegal Instruction) crashes observed
- 2 SIGTRAP (Trace/Breakpoint) crashes observed
- Pattern: Multiple crashes in quick succession, then gaps
- Suggests CPU-level or instruction execution problems

**Version 2.4.22 (after update, 2026-02-08):**
- 1 SIGTRAP crash observed
- 1 SIGSEGV (Segmentation Fault) crash observed - **NEW CRASH TYPE**
- Most recent crash (01:33:18): SIGSEGV in zygote process (101.4M coredump)
- Crash occurred in Electron zygote process (`--type=zygote`)
- Suggests memory corruption or memory access violation (different from SIGILL)

**Analysis:**
- SIGILL crashes: Suggest CPU-level issues (illegal instruction execution)
  - May be related to FHS wrapper, CPU microcode, or hardware defects
  - See CPU hardware testing guide in snapshot directory for investigation methods
- SIGSEGV crash: Suggests memory corruption or invalid memory access
  - First SIGSEGV observed after GPU fix
  - Different root cause than SIGILL crashes
  - Could be related to:
    * Cursor 2.4.22 version bugs
    * Kernel 6.12.68 compatibility issues
    * FHS wrapper memory mapping issues
    * Electron/Chromium zygote process memory management

**Crash Frequency:**
- Reduced significantly after GPU fix (~95% reduction)
- Crashes still occur but at much lower frequency
- Multiple crash types suggest multiple underlying issues

## Summary

**Resolved Issues:**
- ✅ GPU Configuration: NVIDIA configured as primary GPU via PRIME sync - crash frequency reduced by ~95%
- ✅ Early Boot Instability: Stabilized after GPU configuration fix
- ✅ Sleep Mode Configuration: Aligned with actual BIOS capabilities (s2idle)

**Active Issues:**
- ⚠️ Sleep/Hibernation: Fails to resume reliably (ACPI BIOS bugs)
- ⚠️ ACPI BIOS Bugs: 16 non-fatal errors per boot (requires BIOS update)
- ⚠️ Cursor Crashes: Multiple crash types observed (SIGILL, SIGTRAP, SIGSEGV)
  - SIGILL: CPU-level instruction execution issues (reduced but not eliminated)
  - SIGSEGV: Memory corruption/access violations (new pattern on Cursor 2.4.22)

**Root Causes:**
- ACPI BIOS bugs (firmware-level, require BIOS update)
- CPU-level issues (SIGILL crashes suggest microcode or hardware problems)
- Memory corruption/access issues (SIGSEGV crashes suggest different underlying problem)
- Potential Cursor version compatibility issues (2.4.22 introduces SIGSEGV pattern)

**Next Steps:**
- Check for BIOS updates from ASUS (current: GA503RS.317, 02/27/2024)
- Monitor Cursor crash patterns:
  - Track SIGILL vs SIGSEGV frequency
  - Monitor if SIGSEGV becomes common pattern on Cursor 2.4.22
  - Check Cursor 2.4.22 release notes for known issues
  - Consider compatibility with kernel 6.12.68
- Continue monitoring system stability improvements from GPU fix
- If SIGSEGV crashes persist on 2.4.22, consider:
  - Temporarily downgrading to 2.4.21 to compare patterns
  - Investigating FHS wrapper memory mapping issues
  - Checking Electron/Chromium zygote process compatibility
