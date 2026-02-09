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

**Status Update (2026-02-08):**
- Issue persists in Sway/Wayland environment (confirmed after transition from GNOME/X11)
- Confirms this is a hardware/firmware-level issue, not display server specific
- Sleep/resume failures occur regardless of desktop environment (GNOME/X11 or Sway/Wayland)

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
- Multiple SIGTRAP crashes observed - **GPU DRIVER RELATED**
- Multiple SIGSEGV (Segmentation Fault) crashes observed - **NEW CRASH TYPE**
- Crashes observed:
  - 01:33:18: SIGSEGV in zygote process (`--type=zygote`) - 101.4M coredump (PID unknown)
  - 12:59:42: SIGSEGV in zygote process (`--type=zygote`) - 84.8M coredump (PID 3636) - Sway/Wayland
  - 13:00:29: SIGSEGV in Compositor process - 88.8M coredump (PID 4201) - Sway/Wayland
  - 13:35:09: SIGSEGV in zygote process (`--type=zygote`) - 63.4M coredump (PID 2839) - Sway/Wayland
  - 17:03:43: SIGTRAP - 8.8M coredump (PID 14169) - **GPU driver exception** - Sway/Wayland
  - 19:31:46: SIGSEGV in Compositor process (PID 30988) and zygote process (PID 30981, `--type=zygote`) - 69.9M coredump - **Freeze and crash** - Application froze during standard working flow, then crashed 1-2 seconds later - Sway/Wayland
    - Crash involved `libXcursor.so.1` (X cursor library) - notable for Wayland environment
    - Error: `segfault at 26bc45a18cca ip 0000555ca5dc7a0b sp 00007f34031d52e0 error 4` (invalid memory access)
    - Thread 7 crashed, Thread 5 waiting in epoll_wait
    - Both Compositor and zygote processes crashed simultaneously
- SIGSEGV crashes occurred in Electron zygote and Compositor processes
- SIGTRAP crash (17:03:43): Caused by nouveau GPU driver graphics exception
  - Graphics Exception on GPC 0: "3D HEIGHT CT Violation"
  - Graphics Exception on GPC 1: "WIDTH CT Violation"
  - GPU channel 56 errored and was killed by nouveau driver
  - Context: After reboot, during startup (WezTerm and Cursor running, Firefox not started)
  - Root cause: nouveau driver GPU exception, not Cursor application bug
- Pattern continues across both GNOME/X11 and Sway/Wayland environments
- SIGSEGV suggests memory corruption or memory access violation (different from SIGILL)
- SIGTRAP (17:03:43) suggests GPU driver incompatibility or hardware-level GPU issue

**Analysis:**
- SIGILL crashes: Suggest CPU-level issues (illegal instruction execution)
  - May be related to FHS wrapper, CPU microcode, or hardware defects
  - See CPU hardware testing guide in snapshot directory for investigation methods
- SIGSEGV crashes: Suggests memory corruption or invalid memory access
  - First SIGSEGV observed after GPU fix (01:33:18)
  - Pattern continues in both GNOME/X11 and Sway/Wayland environments
  - Multiple crashes observed in Sway/Wayland (12:59:42, 13:00:29, 13:35:09, 19:31:46)
  - Different root cause than SIGILL crashes
  - **New Finding (19:31:46)**: Crash involved `libXcursor.so.1` (X11 cursor library) in Wayland environment
    - Suggests Electron/Cursor using X11 cursor libraries while running under Wayland
    - Invalid memory access (`error 4`) in cursor handling code path
    - Both Compositor and zygote processes crashed simultaneously
    - May indicate Wayland/X11 cursor compatibility issue
  - Could be related to:
    * Cursor 2.4.22 version bugs
    * Kernel 6.12.68 compatibility issues
    * FHS wrapper memory mapping issues
    * Electron/Chromium zygote process memory management
    * Wayland compositor interaction (for crashes in Sway environment)
    * NVIDIA GPU Wayland compatibility (WLR_NO_HARDWARE_CURSORS set)
    * **X11 cursor library (`libXcursor.so.1`) incompatibility with Wayland** (new finding)
- SIGTRAP crashes (GPU driver related): Caused by nouveau GPU driver graphics exceptions
  - Crash at 17:03:43: nouveau driver encountered graphics exception and killed GPU channel
  - Graphics coordinate violations suggest GPU command buffer corruption or driver bug
  - Occurs during application startup/initialization (consistent with user report)
  - Root cause: nouveau (open-source NVIDIA) driver incompatibility or bug
  - Not an application bug - driver killed the GPU channel causing application termination
  - Could be related to:
    * nouveau driver Wayland compatibility issues
    * GPU hardware defects or instability
    * Driver bug with certain GPU operations
    * Missing or incorrect GPU initialization
- Freeze and crash incidents: Application freezes before crashing
  - Crash at 19:31:46: Application froze during standard working flow, then crashed 1-2 seconds later
  - Context: Occurred during normal operation (not during startup/initialization)
  - **Key Finding**: Crash involved `libXcursor.so.1` (X cursor library) in Wayland/Sway environment
    - Cursor is using X11 cursor libraries (`libXcursor.so.1`) while running under Wayland
    - Suggests potential compatibility issue between Electron's X11 cursor handling and Wayland
    - Invalid memory access (`error 4`) in cursor-related code path
  - **Process Details**: Both Compositor process (PID 30988) and zygote process (PID 30981) crashed simultaneously
    - Compositor process segfaulted first
    - Zygote process terminated as a result
    - Thread 7 crashed in cursor handling code, Thread 5 was waiting in epoll_wait
  - Timing: Short freeze duration (1-2 seconds) before crash suggests:
    * Rapid memory corruption in cursor handling code
    * Invalid memory access in X11 cursor library (libXcursor.so.1)
    * Wayland/X11 compatibility issue causing immediate crash
  - Freezes before crashes can indicate:
    * UI thread deadlock or blocking operation
    * Resource exhaustion (memory, file descriptors, etc.)
    * GPU driver hang before exception
    * Wayland compositor interaction issues
    * Electron main process blocking
    * **X11 cursor library incompatibility with Wayland** (new finding)
  - May be related to SIGSEGV crashes but with specific X11 cursor library involvement
  - Pattern suggests application becomes unresponsive briefly before actual crash occurs
  - Different from startup crashes (17:03:43) - occurs during active use
  - **Potential Root Cause**: Electron/Cursor using X11 cursor libraries (`libXcursor.so.1`) in Wayland environment may cause memory access violations when handling cursor operations

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
- 🔴 **Critical System Crash**: Complete system lockup requiring hard reboot (2026-02-09)
  - Triggered by Cursor crash leading to kernel "scheduling while atomic" bug
  - RCU stalls causing system unresponsiveness
- ⚠️ Sleep/Hibernation: Fails to resume reliably (ACPI BIOS bugs)
- ⚠️ ACPI BIOS Bugs: 16 non-fatal errors per boot (requires BIOS update)
- ⚠️ Cursor Crashes: Multiple crash types observed (SIGILL, SIGTRAP, SIGSEGV)
  - SIGILL: CPU-level instruction execution issues (reduced but not eliminated)
  - SIGSEGV: Memory corruption/access violations (new pattern on Cursor 2.4.22)
  - SIGTRAP: GPU driver exceptions (nouveau driver graphics violations)
  - **NEW**: SIGTRAP crashes may trigger kernel-level system crashes

**Root Causes:**
- **Kernel-level bugs** (Critical - "scheduling while atomic" bug triggered by application crashes)
- ACPI BIOS bugs (firmware-level, require BIOS update)
- CPU-level issues (SIGILL crashes suggest microcode or hardware problems)
- Memory corruption/access issues (SIGSEGV crashes suggest different underlying problem)
- GPU driver issues (SIGTRAP crashes caused by nouveau driver graphics exceptions)
- Potential Cursor version compatibility issues (2.4.22 introduces SIGSEGV pattern)
- **Application crashes triggering kernel bugs** (Critical - Cursor crashes may cause system lockups)

**Next Steps:**
- **PRIORITY**: Monitor for recurrence of critical system crash pattern
  - Watch for "scheduling while atomic" kernel bugs
  - Monitor RCU stall patterns
  - Track if Cursor crashes trigger system crashes
- Check for BIOS updates from ASUS (current: GA503RS.317, 02/27/2024)
- Monitor Cursor crash patterns:
  - Track SIGILL vs SIGSEGV vs SIGTRAP frequency
  - Monitor if SIGSEGV becomes common pattern on Cursor 2.4.22
  - Monitor SIGTRAP crashes related to nouveau GPU driver
  - Check Cursor 2.4.22 release notes for known issues
  - Consider compatibility with kernel 6.12.68
- Continue monitoring system stability improvements from GPU fix
- For SIGTRAP GPU driver crashes:
  - Investigate nouveau driver compatibility with Wayland/Sway
  - Consider switching to proprietary NVIDIA driver (nvidia) instead of nouveau
  - Check if crashes occur with other GPU-intensive applications
  - Monitor if crashes are specific to startup/initialization phase
- If SIGSEGV crashes persist on 2.4.22, consider:
  - Temporarily downgrading to 2.4.21 to compare patterns
  - Investigating FHS wrapper memory mapping issues
  - Checking Electron/Chromium zygote process compatibility

## Critical System Crash (Previous Boot - 2026-02-09)

**Severity:** Critical  
**Impact:** Complete system lockup requiring hard reboot  
**Date:** 2026-02-09 (Previous boot, boot -1)

**Timeline:**
- **21:18:35** - System boot initiated
- **21:18:36** - Standard ACPI BIOS errors (16 errors, as documented)
- **21:18:40** - nouveau GPU driver error: `[BL_GET level:0] (ret:-22)`
- **21:18:58** - **Cursor crash (SIGTRAP/int3)** - Process 2579 crashed with trap int3
  - Stack trace shows crash in cursor binary at `0x6cfed13`
  - Involved `libXcursor.so.1` module (X11 cursor library)
  - Coredump generated
- **21:19:07** - **Critical kernel crash** - "Fixing recursive fault but reboot is needed!"
  - **BUG: scheduling while atomic** - Process 2630 (sleep) attempted to schedule while in atomic context
  - **RCU stalls detected** - RCU (Read-Copy-Update) subsystem detected stalls
  - Process 2630 blocked on level-0 rcu_node (CPUs 0-15)
  - System became completely unresponsive
- **21:19:26 onwards** - Multiple RCU stall warnings (every ~30-60 seconds)
  - RCU stalls continued for several minutes
  - System services began timing out (systemd-hostnamed, systemd-localed)
  - System required hard reboot

**Root Cause Analysis:**
1. **Initial trigger**: Cursor application crash (SIGTRAP) at 21:18:58
   - Crash occurred ~23 seconds after boot
   - Involved X11 cursor library (`libXcursor.so.1`) in Wayland environment
   - Similar to previously documented SIGTRAP crashes

2. **Cascade failure**: The Cursor crash appears to have triggered a kernel-level failure
   - Process 2630 (sleep) attempted to schedule while in atomic context
   - This violated kernel scheduling rules and triggered "scheduling while atomic" bug
   - RCU subsystem detected the stall and began reporting errors

3. **System lockup**: The kernel bug caused complete system unresponsiveness
   - RCU stalls prevented proper CPU task scheduling
   - System services could not complete shutdown procedures
   - Required hard reboot to recover

**Key Findings:**
- **Cursor crash preceded system crash** - The application crash appears to have triggered the kernel bug
- **Kernel bug**: "scheduling while atomic" indicates a serious kernel-level issue
- **RCU stalls**: Multiple RCU stalls suggest CPU scheduling subsystem failure
- **Process 2630 (sleep)**: This process was involved in the kernel bug
- **Timing**: Crash occurred very early in boot (~30 seconds after system start)

**Potential Contributing Factors:**
- Cursor crash may have left kernel state inconsistent
- nouveau GPU driver error (`[BL_GET level:0] (ret:-22)`) may indicate GPU driver issues
- ACPI BIOS bugs may contribute to system instability
- Kernel 6.12.68 compatibility issues
- Possible memory corruption from Cursor crash affecting kernel state

**Impact:**
- Complete system lockup requiring hard reboot
- Data loss risk (unsaved work)
- System instability during early boot phase
- Suggests deeper system-level issues beyond application crashes

**Recommendations:**
1. **Immediate**: Monitor for recurrence of this crash pattern
2. **Investigation**: 
   - Check kernel logs for similar "scheduling while atomic" bugs
   - Investigate Process 2630 (sleep) - what was it doing?
   - Review Cursor crash patterns - are they triggering kernel bugs?
3. **Mitigation**:
   - Consider delaying Cursor startup until system is fully initialized
   - Monitor nouveau GPU driver errors more closely
   - Consider kernel parameter adjustments if pattern continues
   - May need to report kernel bug if this recurs
4. **Long-term**:
   - Continue monitoring for kernel-level crashes
   - Document any patterns in timing or triggers
   - Consider kernel version changes if issues persist

**Status:** Active - Critical system crash requiring monitoring
