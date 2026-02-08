# Sway Tiling Window Manager Configuration

Sway module for NixOS providing Wayland compositor and tiling window manager configuration.

## Module Structure

- **`default.nix`** - Main module file that imports sub-modules
- **`sway.nix`** - Sway-specific NixOS configuration (systemd, packages, display manager)
- **`sway-config.nix`** - Generates the Sway configuration file (`/etc/sway/config`)
- **`walker.nix`** - Walker launcher configuration and theming
- **`walker-theme.nix`** - CSS theme for Walker launcher using Base16 colorscheme

## Implementation Status

### ✅ Implemented

- **Sway Core**: Enabled with systemd integration, config at `/etc/sway/config`
- **Display Manager**: GDM configured, Sway as default session
- **Launcher**: Walker [¹⁴][14] with Elephant backend, custom Ashes theme
- **Terminal**: WezTerm (if enabled) or Alacritty fallback
- **Wallpaper**: swaybg integration (if wallpaper module enabled)
- **Theme**: Base16 colorscheme applied to windows and Walker
- **Input**: Norwegian keyboard (nodeadkeys), touchpad configured
- **NVIDIA**: `WLR_NO_HARDWARE_CURSORS=1` set if NVIDIA hardware detected

### 🔄 Future Components

- swayidle/swaylock (idle management and screen lock)
- waybar (status bar)
- Notification daemon (dunst/mako)
- Polkit agent (authentication dialogs)
- xdg-desktop-portal-wlr (screen sharing)

## Configuration

### Sway Config (`sway-config.nix`)

- Systemd integration, wallpaper, terminal/launcher setup
- Window colors from Base16 colorscheme
- Norwegian keyboard layout, two-finger touchpad scrolling
- No borders, 8px gaps, 3 workspaces
- Keybindings: `Mod+Enter` (terminal), `Mod+D` (launcher), `Mod+Shift+Q` (close), `Mod+Shift+1/2/3` (move to workspace)

### Walker Launcher

- Custom Ashes theme (CSS)
- Elephant backend providers: desktop applications, files, runner, websearch, menus
- Systemd service with PATH configuration

## Usage

Enable Sway on a host:

```nix
graphical = {
  enable = true;
  environment = "sway";
};
```

Reload configuration after rebuild:

```bash
swaymsg reload
```

## Wayland Notes

Sway is a Wayland compositor (not X11). X11 apps run via XWayland automatically. NVIDIA GPUs may need `WLR_NO_HARDWARE_CURSORS=1` (configured automatically if detected).

## References

[¹][1] [Sway](https://github.com/swaywm/sway) | [²][2] [greetd](https://git.sr.ht/~kennylevinsen/greetd) | [³][3] [swaybg](https://github.com/swaywm/swaybg) | [⁴][4] [swayidle](https://github.com/swaywm/swayidle) | [⁵][5] [swaylock](https://github.com/swaywm/swaylock) | [⁶][6] [wofi](https://github.com/SimplyCEO/wofi) | [⁷][7] [waybar](https://github.com/Alexays/Waybar) | [⁸][8] [xdg-desktop-portal-wlr](https://github.com/emersion/xdg-desktop-portal-wlr) | [⁹][9] [NVIDIA Drivers](https://us.download.nvidia.com/XFree86/Linux-x86_64/580.126.09/README/index.html) | [¹⁰][10] [X.org](https://www.x.org/wiki/) | [¹¹][11] [Wayland](https://wayland.freedesktop.org/) | [¹²][12] [waypipe](https://github.com/deepin-community/waypipe) | [¹³][13] [XWayland](https://cgit.freedesktop.org/xorg/xserver) | [¹⁴][14] [Walker](https://github.com/abenz1267/walker)

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
[14]: https://github.com/abenz1267/walker
