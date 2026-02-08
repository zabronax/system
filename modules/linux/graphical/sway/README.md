# Sway Tiling Window Manager Configuration

Planning and implementation notes for transitioning from GNOME to Sway on the mani host.

## Components Needed

### Core Components

1. **Sway** (Window Manager/Compositor) [¹][1]
   - Wayland compositor and tiling window manager
   - Replaces GNOME desktop environment
   - Requires Wayland (not X11)

2. **Display Manager**
   - Current: GDM (GNOME Display Manager)
   - Options:
     - Keep GDM (can launch Sway)
     - Switch to `greetd` + `gtkgreet` [²][2] (lightweight, Sway-focused)
     - Use `sway` directly (no display manager)

### Essential Utilities

3. **swaybg** (Wallpaper) [³][3]
   - Sets wallpaper in Sway
   - Replaces GNOME wallpaper management

4. **swayidle** (Idle Management) [⁴][4]
   - Handles idle timeouts (screen lock, suspend)
   - Works with `swaylock`

5. **swaylock** (Screen Lock) [⁵][5]
   - Screen locker for Sway
   - Replaces GNOME screen lock

### User Interface Components

6. **Launcher** (Application Launcher)
   - **wofi** [⁶][6] (recommended): Wayland-native, lightweight
   - **rofi**: X11-based, works via XWayland (less ideal)
   - Replaces GNOME application launcher

7. **Status Bar**
   - **waybar** [⁷][7]: Standard status bar for Sway
   - Shows system info, workspaces, time, etc.
   - Replaces GNOME top bar

### Additional Considerations

8. **Notification Daemon**
   - **dunst** or **mako**: Lightweight notification daemons
   - Replaces GNOME notification system

9. **Polkit Agent**
   - For authentication dialogs (sudo, etc.)
   - Options: `polkit-kde-agent` or `polkit-gnome`

10. **Screen Sharing**
    - **xdg-desktop-portal-wlr** [⁸][8]: For screen sharing in Wayland
    - Required for applications that need screen sharing

## Transition Order

1. **Phase 1: Foundation**
   - Add Sway to graphical module
   - Basic Sway configuration
   - Test that Sway works with NVIDIA GPU

2. **Phase 2: Essential Utilities**
   - Configure swaybg (wallpaper)
   - Set up swayidle/swaylock (idle/lock)
   - Basic keybindings

3. **Phase 3: Launcher**
   - Install and configure wofi
   - Set up application launcher keybinding

4. **Phase 4: Status Bar**
   - Install and configure waybar
   - Customize status bar modules

5. **Phase 5: Polish**
   - Notification daemon
   - Polkit agent
   - Screen sharing support
   - Fine-tune configuration

## NVIDIA Considerations

- Sway works with NVIDIA [⁹][9], but may need environment variables:
  - `WLR_NO_HARDWARE_CURSORS=1` (if cursor issues)
  - Ensure NVIDIA drivers are properly configured for Wayland
- Test GPU compatibility before full transition

## Wayland vs X11

### Current State (X11)

- **Current setup**: Uses X11 (`services.xserver.enable = true`)
- **X11 (X Window System)** [¹⁰][10]: Legacy display server protocol from the 1980s
- **Architecture**: Client-server model where X server manages display, input, and windows
- **Security model**: Applications can see/interact with each other's windows (security concern)
- **Network transparency**: Built-in (can run apps remotely)
- **Compatibility**: Universal support, mature ecosystem

### Target State (Wayland)

- **Sway requirement**: Sway is a Wayland compositor, requires Wayland (not X11)
- **Wayland** [¹¹][11]: Modern display server protocol (2008+)
- **Architecture**: Compositor-centric model where compositor (Sway) manages everything
- **Security model**: Applications are isolated, cannot see/interact with other windows (more secure)
- **Network transparency**: Not built-in (requires separate solutions like `waypipe` [¹²][12])
- **Compatibility**: Most modern apps support Wayland natively

### Key Differences

1. **Security & Isolation**
   - **X11**: Any application can read keyboard input, capture screens, manipulate other windows
   - **Wayland**: Applications only see their own windows and input, compositor enforces isolation

2. **Architecture**
   - **X11**: Separate X server process manages display, window managers are clients
   - **Wayland**: Compositor (Sway) IS the display server, window manager, and compositor combined

3. **Performance**
   - **X11**: Older protocol, more overhead, potential for tearing
   - **Wayland**: Modern protocol, better performance, built-in vsync/compositing

4. **Configuration**
   - **X11**: Global X server config (`services.xserver.xkb`), system-wide settings
   - **Wayland**: Per-compositor configuration (Sway config file), compositor-specific

5. **Input Handling**
   - **X11**: Centralized input handling through X server
   - **Wayland**: Compositor handles input directly, more responsive

### XWayland Compatibility Layer

- **XWayland** [¹³][13]: Automatic compatibility layer that runs X11 applications under Wayland
- **How it works**: XWayland creates a virtual X server that translates X11 calls to Wayland
- **Transparency**: Most X11 apps work seamlessly, user may not notice
- **Limitations**: Some X11-specific features may not work (e.g., global hotkeys, screen capture)
- **Performance**: Slight overhead, but generally acceptable

### Configuration Changes Required

1. **Disable X11**: Remove or disable `services.xserver.enable` (Sway handles display)
2. **Keyboard Layout**: Move from `services.xserver.xkb` to Sway config (`input * xkb_layout`)
3. **Display Manager**: GDM can launch Wayland sessions, or use Wayland-native alternatives
4. **Environment Variables**: May need Wayland-specific vars (e.g., `XDG_SESSION_TYPE=wayland`)
5. **GPU Drivers**: Ensure Wayland-compatible drivers (NVIDIA needs special consideration)

### Migration Considerations

- **Testing**: Test critical applications for Wayland compatibility before full switch
- **Fallback**: Can keep X11 session available for troubleshooting
- **Gradual**: Some apps may need XWayland indefinitely (legacy software)
- **Documentation**: Update any X11-specific configuration/documentation

## References

[¹][1] Sway. "Sway - i3-compatible Wayland compositor," GitHub. [Online]. Available: <https://github.com/swaywm/sway>

[²][2] C. Miller. "greetd - A minimal, agnostic, flexible login manager," GitHub. [Online]. Available: <https://git.sr.ht/~kennylevinsen/greetd>

[³][3] Sway. "swaybg - Wallpaper tool for Wayland compositors," GitHub. [Online]. Available: <https://github.com/swaywm/swaybg>

[⁴][4] Sway. "swayidle - Idle management daemon for Wayland," GitHub. [Online]. Available: <https://github.com/swaywm/swayidle>

[⁵][5] Sway. "swaylock - Screen locker for Wayland," GitHub. [Online]. Available: <https://github.com/swaywm/swaylock>

[⁶][6] dylanaraps. "wofi - A launcher/menu program for wlroots based wayland compositors," GitHub. [Online]. Available: <https://github.com/SimplyCEO/wofi>

[⁷][7] A. Pettersson. "waybar - Highly customizable Wayland bar for Sway and Wlroots based compositors," GitHub. [Online]. Available: <https://github.com/Alexays/Waybar>

[⁸][8] emersion. "xdg-desktop-portal-wlr - xdg-desktop-portal backend for wlroots," GitHub. [Online]. Available: <https://github.com/emersion/xdg-desktop-portal-wlr>

[⁹][9] NVIDIA. "NVIDIA Linux Driver README and Installation Guide," NVIDIA Developer Documentation. [Online]. Available: <https://us.download.nvidia.com/XFree86/Linux-x86_64/580.126.09/README/index.html>

[¹⁰][10] X.Org Foundation. "X Window System," X.org. [Online]. Available: <https://www.x.org/wiki/>

[¹¹][11] K. Høiland-Jørgensen et al. "Wayland," freedesktop.org. [Online]. Available: <https://wayland.freedesktop.org/>

[¹²][12] M. Larabel. "waypipe - Network transparency for Wayland," GitHub. [Online]. Available: <https://github.com/deepin-community/waypipe>

[¹³][13] X.Org Foundation. "XWayland - X server for Wayland," freedesktop.org. [Online]. Available: <https://cgit.freedesktop.org/xorg/xserver>

[1]: https://github.com/swaywm/sway
[2]: https://git.sr.ht/~kennylevinsen/greetd
[3]: https://github.com/swaywm/swaybg
[4]: https://github.com/swaywm/swayidle
[5]: https://github.com/swaywm/swaylock
[6]: https://github.com/SimplyCEO/wofi
[7]: https://github.com/Alexays/Waybar
[8]: https://github.com/emersion/xdg-desktop-portal-wlr
[9]: https://us.download.nvidia.com/XFree86/Linux-x86_64/580.126.09/README/index.html
[10]: https://www.x.org/wiki/
[11]: https://wayland.freedesktop.org/
[12]: https://github.com/deepin-community/waypipe
[13]: https://cgit.freedesktop.org/xorg/xserver
