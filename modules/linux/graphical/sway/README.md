# Sway Tiling Window Manager Configuration

Planning and implementation notes for transitioning from GNOME to Sway on the mani host.

## Components Needed

### Core Components

1. **Sway** (Window Manager/Compositor)
   - Wayland compositor and tiling window manager
   - Replaces GNOME desktop environment
   - Requires Wayland (not X11)

2. **Display Manager**
   - Current: GDM (GNOME Display Manager)
   - Options:
     - Keep GDM (can launch Sway)
     - Switch to `greetd` + `gtkgreet` (lightweight, Sway-focused)
     - Use `sway` directly (no display manager)

### Essential Utilities

3. **swaybg** (Wallpaper)
   - Sets wallpaper in Sway
   - Replaces GNOME wallpaper management

4. **swayidle** (Idle Management)
   - Handles idle timeouts (screen lock, suspend)
   - Works with `swaylock`

5. **swaylock** (Screen Lock)
   - Screen locker for Sway
   - Replaces GNOME screen lock

### User Interface Components

6. **Launcher** (Application Launcher)
   - **wofi** (recommended): Wayland-native, lightweight
   - **rofi**: X11-based, works via XWayland (less ideal)
   - Replaces GNOME application launcher

7. **Status Bar**
   - **waybar**: Standard status bar for Sway
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
    - **xdg-desktop-portal-wlr**: For screen sharing in Wayland
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

- Sway works with NVIDIA, but may need environment variables:
  - `WLR_NO_HARDWARE_CURSORS=1` (if cursor issues)
  - Ensure NVIDIA drivers are properly configured for Wayland
- Test GPU compatibility before full transition

## Wayland vs X11

### Current State (X11)

- **Current setup**: Uses X11 (`services.xserver.enable = true`)
- **X11 (X Window System)**: Legacy display server protocol from the 1980s
- **Architecture**: Client-server model where X server manages display, input, and windows
- **Security model**: Applications can see/interact with each other's windows (security concern)
- **Network transparency**: Built-in (can run apps remotely)
- **Compatibility**: Universal support, mature ecosystem

### Target State (Wayland)

- **Sway requirement**: Sway is a Wayland compositor, requires Wayland (not X11)
- **Wayland**: Modern display server protocol (2008+)
- **Architecture**: Compositor-centric model where compositor (Sway) manages everything
- **Security model**: Applications are isolated, cannot see/interact with other windows (more secure)
- **Network transparency**: Not built-in (requires separate solutions like `waypipe`)
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

- **XWayland**: Automatic compatibility layer that runs X11 applications under Wayland
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
