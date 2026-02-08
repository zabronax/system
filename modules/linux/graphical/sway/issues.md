# Sway Issues and Crashes

Issues and crashes observed after transitioning to Sway window manager on the mani host.

## Application Crashes

### Fish Shell Crash (SIGSEGV)

**Severity:** Medium  
**Impact:** Terminal session crashes, user loses work in progress

**First Observed:** 2026-02-08 12:59:04 (after Sway transition)

**Details:**
- **Signal:** SIGSEGV (Segmentation Fault)
- **Process:** fish (PID 3208)
- **Stack Trace:** Crashed during input handling
  - `__poll` → `next_input_event` → `read_char` → `handle_char_event` → `readline`
- **Context:** Running in Sway/Wayland session
- **Coredump:** 521.9K

**Analysis:**
- Crash occurred in fish shell's input handling code (`input_common::next_input_event`)
- Happened during character reading (`read_char`)
- Possible causes:
  - Wayland input handling incompatibility
  - Fish shell bug with Wayland terminal emulators
  - Memory corruption in input event queue
  - Terminal emulator (WezTerm) interaction issue

**Next Steps:**
- Monitor frequency of fish crashes in Sway
- Test with different terminal emulators (Alacritty fallback)
- Check fish shell version compatibility with Wayland
- Review WezTerm Wayland support status

### Cursor Crashes (SIGSEGV)

**Note:** Cursor crashes are tracked as host-specific issues, not Sway-specific. See `hosts/mani/issues.md` for full details.

**Observed in Sway/Wayland:**
- 2026-02-08 12:59:42: SIGSEGV in zygote process (PID 3636) - 84.8M coredump
- 2026-02-08 13:00:29: SIGSEGV in Compositor process (PID 4201) - 88.8M coredump
- 2026-02-08 13:35:09: SIGSEGV in zygote process (PID 2839) - 63.4M coredump

**Analysis:**
- These crashes are part of the documented Cursor 2.4.22 SIGSEGV pattern (see `hosts/mani/issues.md`)
- Pattern continues across both GNOME/X11 and Sway/Wayland environments
- Possible Sway/Wayland-specific factors may exacerbate the issue:
  - Wayland compositor interaction with Electron/Chromium
  - NVIDIA GPU compatibility with Wayland (WLR_NO_HARDWARE_CURSORS set)
  - XWayland compatibility layer issues
  - Memory management differences between X11 and Wayland

## Sway/Wayland Warnings

### Touchpad Event Processing Lag

**Severity:** Low  
**Impact:** Minor input lag, non-fatal

**Message:**
```
[ERROR] [wlr] [libinput] event11 - ASUE120D:00 04F3:31FB Touchpad: 
client bug: event processing lagging behind by 21ms, your system is too slow
```

**Analysis:**
- libinput warning about touchpad event processing lag
- 21ms lag is relatively minor
- May indicate system load or input handling inefficiency
- Non-fatal, system continues to function

### Swaybar Tray Icon Errors

**Severity:** Low  
**Impact:** System tray icons may not display correctly, non-fatal

**Messages:**
```
[ERROR] [swaybar/tray/item.c:127] :1.5/StatusNotifierItem IconThemePath: error occurred in Get
[ERROR] [swaybar/tray/item.c:127] :1.5/StatusNotifierItem IconName: error occurred in Get
```

**Analysis:**
- StatusNotifierItem (system tray) icon retrieval errors
- Affects system tray icon display
- Non-fatal, functionality continues
- May be related to missing status bar configuration (waybar not yet configured)

## Summary

**New Issues After Sway Transition:**
- ⚠️ Fish shell SIGSEGV crash (input handling)
- ⚠️ Cursor SIGSEGV crashes (host-specific pattern, see `hosts/mani/issues.md`)
- ⚠️ Touchpad event processing lag warning
- ⚠️ Swaybar tray icon errors

**Potential Root Causes:**
- Wayland input handling differences from X11
- NVIDIA GPU Wayland compatibility (even with WLR_NO_HARDWARE_CURSORS)
- Electron/Chromium Wayland support maturity
- Missing status bar configuration (waybar)

**Next Steps:**
- Monitor crash frequency and patterns
- Compare stability between Sway (Wayland) and GNOME (X11)
- Investigate fish shell Wayland compatibility
- Consider adding waybar status bar (may resolve tray icon errors)
- Review NVIDIA Wayland driver compatibility

**Note:** Sleep/hibernation issues persist but are not Sway-specific. See `hosts/mani/issues.md` for details.
