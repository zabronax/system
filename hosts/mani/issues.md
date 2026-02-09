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
   - Process 2579 crashed with trap int3 (breakpoint/trace trap)

2. **Intermediate failure**: Process 2630 (sleep) kernel bug at 21:19:05
   - **Critical finding**: Sleep process hit an **invalid opcode** in kernel memory management code
   - Invalid opcode occurred in `copy_page_range+0x1553/0x1b70` function
   - Sleep process was **exiting** and cleaning up memory mappings when the bug occurred
   - Call trace: `do_exit` → `mmput` → `__mmput` → `exit_mmap` → `unmap_vmas` → `unmap_page_range` → `copy_page_range`
   - Sleep process exited with `preempt_count 1`, meaning it was in an atomic context
   - This suggests memory corruption or kernel bug in page range copying during process exit
   - **Important distinction**: This is a **kernel-level** invalid opcode (kernel bug), not an application-level SIGILL
     - Cursor crashes show "trap invalid opcode" (application-level SIGILL)
     - Sleep process shows "Oops: invalid opcode" (kernel-level bug)
     - These are different types of bugs, though may be related

3. **Cascade failure**: The invalid opcode led to "scheduling while atomic" bug at 21:19:07
   - Sleep process attempted to schedule while in atomic context (from invalid opcode handling)
   - This violated kernel scheduling rules and triggered "scheduling while atomic" bug
   - RCU subsystem detected the stall and began reporting errors
   - **Note**: The "scheduling while atomic" bug was a consequence, not the root cause

4. **System lockup**: The kernel bug caused complete system unresponsiveness
   - RCU stalls prevented proper CPU task scheduling
   - System services could not complete shutdown procedures
   - Required hard reboot to recover

**Key Findings:**
- **Cursor crash preceded system crash** - The application crash occurred first, but may not be directly related
- **Kernel bug in sleep process**: Process 2630 (sleep) hit an **invalid opcode** during memory cleanup
  - Invalid opcode in `copy_page_range` function (kernel memory management)
  - Occurred during process exit cleanup (`exit_mmap` path)
  - This is a **kernel-level bug**, not an application bug
- **"Scheduling while atomic" was a symptom**: The actual bug was the invalid opcode
  - Sleep process was in atomic context when invalid opcode occurred
  - Kernel tried to handle the invalid opcode, which triggered scheduling while atomic
- **RCU stalls**: Multiple RCU stalls suggest CPU scheduling subsystem failure
- **Process 2630 (sleep)**: This process was exiting when it hit the kernel bug
- **Timing**: Crash occurred very early in boot (~30 seconds after system start)
- **Uniqueness**: This is the only instance of "scheduling while atomic" in all logs - suggests rare kernel bug

**Potential Contributing Factors:**
- **Kernel bug in `copy_page_range`**: Invalid opcode suggests kernel memory management bug
  - May be related to kernel 6.12.68 version
  - Could be triggered by specific memory layout or process state
  - May be related to AMD CPU architecture (Ryzen 9 5900HS)
- **Cursor crash timing**: Cursor crash occurred ~7 seconds before sleep process bug
  - May have left kernel state inconsistent
  - Could have triggered memory corruption affecting subsequent processes
  - Or may be coincidental timing
- **nouveau GPU driver error**: `[BL_GET level:0] (ret:-22)` occurs on every boot
  - Common, non-critical error (backlight control)
  - Unlikely related to this crash
- **ACPI BIOS bugs**: May contribute to system instability
- **Process exit path**: Bug occurred during process exit memory cleanup
  - Suggests kernel bug in memory unmapping code path
  - May be related to specific memory layout or page table state

**Impact:**
- Complete system lockup requiring hard reboot
- Data loss risk (unsaved work)
- System instability during early boot phase
- Suggests deeper system-level issues beyond application crashes

**Recommendations:**
1. **Immediate**: Monitor for recurrence of this crash pattern
   - Watch for "invalid opcode" errors in kernel logs
   - Monitor for `copy_page_range` errors
   - Track if Cursor crashes correlate with kernel bugs

2. **Investigation**: 
   - ✅ **COMPLETED**: Investigated Process 2630 (sleep) - found invalid opcode in `copy_page_range`
   - ✅ **COMPLETED**: Checked kernel logs - this is the only instance of "scheduling while atomic"
   - ✅ **COMPLETED**: Reviewed Cursor crash patterns - timing correlation but unclear causation
   - **Next**: Research kernel 6.12.68 `copy_page_range` bugs or AMD CPU-related issues
   - **Next**: Check if this is a known kernel bug (search kernel bug trackers)

3. **Mitigation**:
   - **Kernel-level**: This appears to be a kernel bug, not application issue
   - Consider kernel parameter adjustments if pattern continues:
     - `nohz=off` (disable nohz mode) - may help with RCU issues
     - `rcupdate.rcu_cpu_stall_timeout=300` (increase RCU timeout)
   - Consider testing with different kernel version if bug recurs
   - **Application-level**: Delaying Cursor startup may help avoid timing issues
   - Monitor nouveau GPU driver errors (though likely unrelated)

4. **Bug Reporting**:
   - If this recurs, consider reporting to kernel bug tracker
   - Include: kernel version (6.12.68), CPU (AMD Ryzen 9 5900HS), full oops trace
   - Focus on `copy_page_range` invalid opcode bug

5. **Long-term**:
   - Continue monitoring for kernel-level crashes
   - Document any patterns in timing or triggers
   - Consider kernel version changes if issues persist
   - Monitor for AMD CPU microcode updates

**Additional Context:**
- **Kernel bug frequency**: Only 1 instance of "scheduling while atomic" in all logs (63 boots recorded)
- **Kernel Oops/BUG count**: 14 total kernel warnings/errors across all boots
- **Cursor crash frequency**: 128 Cursor-related crash/signal messages across all boots
- **Invalid opcode patterns**: 
  - 9 Cursor application-level "trap invalid opcode" (SIGILL) - application bugs
  - 1 kernel-level "Oops: invalid opcode" (sleep process) - kernel bug
  - The kernel bug is unique and rare

**Status:** Active - Critical system crash requiring monitoring
