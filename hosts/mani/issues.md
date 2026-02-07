# Issues (mani)

Known issues and instability experienced on the Mani host system. These issues have been observed across both the original Windows installation and the current NixOS installation.

## Sleep and Hibernation

**Severity:** High  
**Impact:** System becomes unresponsive, requires hard restart

The system frequently fails to resume properly from sleep or hibernation states. When attempting to wake the machine, it often remains unresponsive and requires a hard power cycle to recover. This issue was present on the original Windows installation, suggesting a hardware-level or firmware-level problem rather than an OS-specific configuration issue.

**Potential causes:**
- BIOS/UEFI firmware bug
- Power management hardware issue
- Incompatible ACPI implementation

## Boot-Time Errors

**Severity:** Medium  
**Impact:** Error messages displayed during boot sequence

Various error or bug messages appear during the boot process. The system typically continues to boot successfully despite these messages, but they indicate potential underlying issues that may require investigation.

**Status:** Messages need to be documented for further analysis.

## Application Crashes

**Severity:** Medium  
**Impact:** Random application termination during normal use

Multiple applications experience unexpected crashes during normal operation:

- **Mozilla Firefox:** Random crashes with no consistent reproduction pattern
- **Cursor (Electron App):** Random crashes with no consistent reproduction pattern

The randomness and variety of affected applications (both native and Electron-based) suggest potential memory instability, graphics driver issues, or system-level resource management problems.

## Early Boot Instability

**Severity:** High  
**Impact:** System freeze or user session termination shortly after boot

Immediately following system boot, the machine occasionally experiences severe instability manifesting as:

- User session unexpectedly terminating (kicked to login screen)
- Complete system freeze requiring hard restart

This behavior appears to be random with no identified reproduction pattern. The timing (shortly after boot) suggests potential issues with:

- Startup service race conditions
- Hardware initialization timing
- Thermal management during initial load
- Graphics driver initialization

**Frequency:** Intermittent, no clear pattern established.
