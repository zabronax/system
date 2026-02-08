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

## Input Configuration Issues

### Keyboard Layout Not Applied

**Severity:** High  
**Impact:** Keyboard layout is incorrect (not Norwegian), affects typing

**Observed:** 2026-02-08 (after Sway transition)

**Details:**
- Expected layout: Norwegian (`no`) with `nodeadkeys` variant
- Actual behavior: Keyboard layout is not Norwegian
- Configuration: `graphical.xkb.layout = "no"` and `graphical.xkb.variant = "nodeadkeys"` set in host config
- Issue: Sway configuration does not apply X11 keyboard settings

**Analysis:**
- Sway uses Wayland input handling, not X11's `services.xserver.xkb`
- Keyboard layout must be configured in Sway config file, not via X11 options
- Current Sway config does not include keyboard layout configuration
- Need to add `input * xkb_layout` and `input * xkb_variant` to Sway config

**Next Steps:**
- Add keyboard layout configuration to Sway config:
  - `input * xkb_layout "no"`
  - `input * xkb_variant "nodeadkeys"`
- Verify layout applies correctly after configuration

### Touchpad Scroll Inverted

**Severity:** Medium  
**Impact:** Touchpad scrolling direction is inverted (unnatural)

**Observed:** 2026-02-08 (after Sway transition)

**Details:**
- Touchpad scroll direction is inverted (scrolling down moves content up)
- Natural scrolling may be enabled when it shouldn't be, or vice versa
- Affects user experience and productivity

**Analysis:**
- Sway/libinput handles touchpad input differently than GNOME
- Scroll direction can be configured via libinput settings
- May need to set `input * natural_scroll` or adjust scroll direction

**Next Steps:**
- Add touchpad scroll configuration to Sway config:
  - `input * natural_scroll enabled` or `disabled` (depending on preference)
  - Or use `input * scroll_method` and `input * scroll_button` settings
- Test scroll direction after configuration

## Summary

**New Issues After Sway Transition:**
- ⚠️ Fish shell SIGSEGV crash (input handling)
- ⚠️ Cursor SIGSEGV crashes (host-specific pattern, see `hosts/mani/issues.md`)
- ⚠️ Touchpad event processing lag warning
- ⚠️ Swaybar tray icon errors
- ⚠️ **Keyboard layout not applied (Norwegian layout missing)** - ✅ RESOLVED
- ⚠️ **Touchpad scroll inverted** - ✅ RESOLVED

**Potential Root Causes:**
- Wayland input handling differences from X11
- Missing keyboard layout configuration in Sway config
- Missing touchpad scroll configuration in Sway config
- NVIDIA GPU Wayland compatibility (even with WLR_NO_HARDWARE_CURSORS)
- Electron/Chromium Wayland support maturity
- Missing status bar configuration (waybar)

**Next Steps:**
- **Immediate:** Add keyboard layout configuration to Sway config
- **Immediate:** Add touchpad scroll configuration to Sway config
- Monitor crash frequency and patterns
- Compare stability between Sway (Wayland) and GNOME (X11)
- Investigate fish shell Wayland compatibility
- Consider adding waybar status bar (may resolve tray icon errors)
- Review NVIDIA Wayland driver compatibility

**Note:** Sleep/hibernation issues persist but are not Sway-specific. See `hosts/mani/issues.md` for details.
