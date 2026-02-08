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

**Severity:** Medium  
**Impact:** Editor crashes, potential data loss

**Observed:** 2026-02-08 12:59:42 and 13:00:29 (after Sway transition)

**Details:**
- **Signal:** SIGSEGV (Segmentation Fault)
- **Processes:**
  - PID 3636: Cursor zygote process (`--type=zygote`) - 84.8M coredump
  - PID 4201: Cursor Compositor process - 88.8M coredump
- **Pattern:** Two crashes within ~1 minute
- **Context:** Running in Sway/Wayland session

**Analysis:**
- These crashes match the documented SIGSEGV pattern for Cursor 2.4.22 (see `hosts/mani/issues.md`)
- However, they occurred after transitioning to Sway/Wayland
- Possible Sway/Wayland-specific factors:
  - Wayland compositor interaction with Electron/Chromium
  - NVIDIA GPU compatibility with Wayland (WLR_NO_HARDWARE_CURSORS set)
  - XWayland compatibility layer issues
  - Memory management differences between X11 and Wayland

**Relationship to Existing Issues:**
- Cursor crashes were already documented in `hosts/mani/issues.md`
- These instances may be:
  - Continuation of existing Cursor 2.4.22 SIGSEGV pattern
  - Exacerbated by Wayland environment
  - New pattern specific to Sway/Wayland

**Next Steps:**
- Compare crash frequency in Sway vs GNOME (X11)
- Monitor if crashes are more frequent in Wayland
- Check if NVIDIA Wayland compatibility affects Electron apps
- Review Cursor's Wayland support status

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
- ⚠️ Cursor SIGSEGV crashes (may be exacerbated by Wayland)
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
