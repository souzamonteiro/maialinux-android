# MaiaLinux-Android

![MaiaLinux Poster](images/Pôster%20neon%20do%20MaiaLinux%20com%20Tux%20e%20Android.png)

**A Lightweight Linux Desktop for Android (Debian 13 Trixie + LXQt)**

MaiaLinux-Android brings a Debian 13 (Trixie) desktop environment to compatible Android devices using Termux, PRoot, and Termux-X11. It features the lightweight **LXQt** desktop environment, preserving the MaiaLinux visual identity while allowing Linux desktop applications to run alongside Android.

> **Project status:** Under active development. MaiaLinux-Android now features Debian 13 (Trixie), LXQt with touch/tablet optimizations, a dedicated on-screen virtual keyboard with programming layouts, and tablet-optimized MaiaLinux widescreen wallpapers.

## Overview

| Component | Technology |
| --- | --- |
| Host operating system | Android (ARM64 recommended) |
| Terminal and package manager | Termux |
| Linux userspace | Debian 13 (Trixie), via PRoot Distro |
| Desktop environment | LXQt (Openbox + PCManFM-Qt) |
| Display server integration | Termux-X11 (X11) |
| Audio | PulseAudio (TCP loopback bridge) |
| On-screen virtual keyboard | `onboard` & `matchbox-keyboard` with custom MaiaLinux layout |
| Wallpapers | Tablet-friendly widescreen neon & purple MaiaLinux wallpapers |
| Optional graphics acceleration | VirGL / ANGLE, device-dependent |
| Optional home-screen launcher | Termux:Widget |

## Architecture

```text
Android device
├── Termux
│   ├── PRoot Distro
│   │   └── Debian 13 (Trixie)
│   │       ├── LXQt desktop (Dark theme, Catppuccin palette)
│   │       ├── Virtual on-screen keyboard (F12 / panel toggle)
│   │       ├── Linux applications (Geany, Firefox, GIMP, etc.)
│   │       └── Development tools (C/C++, Python, Git)
│   ├── PulseAudio (TCP bridge)
│   └── Optional VirGL/ANGLE server
└── Termux-X11 Android application
    └── LXQt graphical session
```

PRoot provides a Linux filesystem and userspace without requiring root access. The Android kernel remains in control, and hardware access is subject to Android and Termux limitations.

## Requirements

- An ARM64 Android tablet or phone with sufficient free storage and RAM.
- Termux and the matching Termux-X11 Android application.
- A network connection for downloading Debian and packages.
- A physical keyboard or the integrated on-screen virtual keyboard (`onboard` / `matchbox-keyboard`).
- Optional: Termux:Widget for launching the desktop directly from the Android home screen.

Download links:
- Termux: https://github.com/termux/termux-app
- Termux-X11: https://github.com/termux/termux-x11
- Termux:Widget: https://github.com/termux/termux-widget

---

## Clone the Repository

Inside **Termux**, install git and clone the project:

```sh
pkg update -y && pkg upgrade -y
pkg install -y git
git clone https://github.com/souzamonteiro/maialinux-android.git
```

---

## 1. Automated Installation & Setup

### Step 1: Prepare Termux and install Debian 13

Inside **Termux** (outside Debian), run the preparation script:

```sh
cd ./maialinux-android/termux/scripts
./setup.sh
```

This script updates Termux packages, installs `proot-distro`, `x11-repo`, `termux-x11-nightly`, `pulseaudio`, graphics acceleration packages (`virglrenderer-android`, `angle-android`), and downloads the Debian container via PRoot Distro.

### Step 2: Enter Debian and configure MaiaLinux (Debian 13 + LXQt)

Still in Termux, log into the Debian container as root:

```sh
proot-distro login debian --shared-tmp
```

Inside the Debian container, execute the main installer:

```sh
cd ./maialinux-android/debian/scripts
./setup.sh
```

The `setup.sh` script:
1. Configures official **Debian 13 (Trixie)** APT repositories with `main contrib non-free non-free-firmware`.
2. Upgrades the system (`apt update && apt dist-upgrade`).
3. Removes legacy Xfce packages if present.
4. Installs the **LXQt** desktop environment (`lxqt-core`, `lxqt-panel`, `openbox`, `pcmanfm-qt`, `qterminal`), `Papirus-Dark` icons, and DejaVu/Noto fonts.
5. Installs and configures virtual on-screen keyboards (`onboard` and `matchbox-keyboard`).
6. Sets up the default `maia` user (and `user` for compatibility) with passwordless `sudo` and audio/video groups.
7. Installs tablet wallpapers into `/usr/share/wallpapers/maialinux/`.
8. Applies the MaiaLinux visual profile (Dark Catppuccin theme, 36px touch-friendly panel with virtual keyboard launcher, Maia menu, and quicklaunch bar).

---

## 2. Launching MaiaLinux (LXQt)

Open the **Termux-X11** application on Android. Then, in **Termux**, run:

```sh
cd ~/maialinux-android/termux/scripts
./Debian.sh
```

Or if you prefer launching directly via Termux-X11 startup:
```sh
./startlxqt.sh
```

To cleanly close all running sessions and background processes:
```sh
./killall.sh
```

---

## 3. Tablet Desktop Features

### Virtual On-Screen Keyboard
- The virtual keyboard can be toggled at any time by tapping the keyboard icon on the **Taskbar (Quicklaunch)** or on the Desktop.
- If a physical keyboard is attached, press **F12** to show or hide the keyboard.
- Automatically uses `onboard` (supporting multi-touch, auto-resize, and word suggestions) or `matchbox-keyboard` with the MaiaLinux programming layout (4 rows, 50 keys, dedicated numbers, and accessible programming symbols).
- Helper toggle script: `/usr/local/bin/maialinux-keyboard-toggle`.

### High-Resolution Tablet Wallpapers
Tablet-ready wallpapers are included in `images/`:
1. **Neon Landscape with MaiaLinux Logo** (`maialinux-tablet-neon.png`)
2. **Purple Landscape with MaiaLinux Logo** (`maialinux-tablet-purple.png`)
3. **Neon Poster of MaiaLinux with Tux and Android** (`maialinux-tablet-tux-android.png`)

To switch wallpapers at any time:
- Click the **Switch Wallpaper** icon in the quicklaunch bar or on the Desktop.
- Or run in the terminal:
  ```sh
  maialinux-wallpaper.sh next
  ```

---

## 4. Optional: 3D Graphics Acceleration (VirGL / ANGLE)

The `Debian.sh` script automatically launches the `virgl_test_server_android` server in the background using ANGLE Vulkan.
Inside Debian, hardware-accelerated application shortcuts are located in `/usr/local/bin/`:
- `firefox-virgl.sh`
- `wings3d-virgl.sh`

To verify 3D acceleration inside Debian:
```sh
GALLIUM_DRIVER=virpipe glxinfo -B
```

---

## 5. Project Structure

```text
maialinux-android/
├── android/
│   └── scripts/            # ADB helper scripts for Android phantom process management
├── debian/
│   ├── bin/                # Utilities (virtual keyboard toggle, wallpaper switcher, virgl scripts)
│   ├── config/             # LXQt, Openbox, PCManFM-Qt, and Matchbox configurations
│   │   ├── keyboard/       # MaiaLinux programming keyboard layout (XML)
│   │   ├── lxqt/           # Dark Catppuccin theme, panel, session, and pcmanfm-qt configs
│   │   └── openbox/        # Window rules, touch margins, and F12 keyboard keybind
│   ├── desktop/            # Desktop entry shortcuts (Keyboard, Wallpaper, Terminal, IDE)
│   ├── scripts/
│   │   ├── setup.sh        # Complete Debian 13 + LXQt + MaiaLinux installer
│   │   └── setup_wine.sh   # Optional Box86/Box64 and Wine configuration
│   └── wallpapers/         # Installed system wallpapers
├── images/                 # Original high-resolution tablet wallpapers
├── termux/
│   └── scripts/
│       ├── setup.sh        # Termux package setup and Debian container installation
│       ├── Debian.sh       # Complete launcher (Termux-X11 + audio + VirGL + LXQt)
│       ├── startlxqt.sh    # Direct LXQt session launcher
│       ├── startdebian.sh  # Direct login into Debian LXQt
│       └── killall.sh      # Clean shutdown of all processes
└── README.md
```

## Troubleshooting

| Symptom | Initial Check |
| --- | --- |
| Black screen in Termux-X11 | Ensure Termux-X11 app is open in foreground; verify `DISPLAY=:0` is exported |
| LXQt does not start | Ensure `debian/scripts/setup.sh` finished successfully and `dbus-x11` is installed |
| Virtual keyboard does not open | Ensure `onboard` or `matchbox-keyboard` is installed (`sudo apt install onboard matchbox-keyboard`) |
| No audio | Check if PulseAudio in Termux started with TCP protocol (`pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1"`) |
| Process killed in background | Disable Android phantom process killer (`android/scripts/disable_phantom_process_killer.sh`) |

## License

Distributed under terms compatible with the MaiaLinux project and the Apache License 2.0.
