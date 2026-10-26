# MaiaLinux-Android

![alt text](<images/Pôster neon do MaiaLinux com Tux e Android.png>)

**A Lightweight Linux Desktop for Android**

MaiaLinux-Android brings a Debian 13 (Trixie) desktop environment to compatible Android devices using Termux, PRoot and Termux-X11. It uses the lightweight **LXQt** desktop, retaining the MaiaLinux visual identity while allowing Linux applications to run alongside Android.

> **Project status:** Under development. The commands below are an initial installation guide and must be validated on target devices. This is a userspace Linux environment, **not** an Android ROM replacement or a native Linux kernel installation.

## Overview

| Component | Technology |
| --- | --- |
| Host operating system | Android (ARM64 recommended) |
| Terminal and package manager | Termux |
| Linux userspace | Debian 13 (Trixie), via PRoot Distro |
| Desktop environment | LXQt |
| Display server integration | Termux-X11 (X11) |
| Audio | PulseAudio |
| Optional graphics acceleration | VirGL / ANGLE, device-dependent |
| Optional home-screen launcher | Termux:Widget |

## Architecture

```text
Android device
├── Termux
│   ├── PRoot Distro
│   │   └── Debian 13 (Trixie)
│   │       ├── LXQt desktop
│   │       ├── Linux applications
│   │       └── Development tools
│   ├── PulseAudio
│   └── Optional VirGL/ANGLE server
└── Termux-X11 Android application
    └── LXQt graphical session
```

PRoot provides a Linux filesystem and userspace without requiring root access. The Android kernel remains in control, and hardware access is subject to Android and Termux limitations.

## Requirements

- An ARM64 Android tablet or phone with sufficient free storage and RAM.
- Termux and the matching Termux-X11 Android application.
- A network connection for downloading Debian and packages.
- A physical keyboard and mouse are recommended for desktop-oriented workflows.
- Optional: Termux:Widget for launching the desktop from the Android home screen.

Install Termux from its official releases or F-Droid. Install the Termux-X11 Android APK from the official Termux-X11 project. Avoid mixing incompatible Termux distributions or APK signing sources.

- Termux: https://github.com/termux/termux-app
- Termux-X11: https://github.com/termux/termux-x11
- Termux:Widget: https://github.com/termux/termux-widget

## 1. Prepare Android

Enable any battery/background-execution permissions needed by Termux and Termux-X11. Some Android versions restrict long-running child processes (often called the *phantom process* restriction). Only change developer settings if the device actually exhibits process termination, and consult the documentation for that Android version. Do not assume that ADB workarounds are portable across devices.

## 2. Install Termux packages

Run the following commands **in Termux, outside Debian**:

```sh
pkg update && pkg upgrade -y
pkg install -y proot-distro x11-repo pulseaudio dbus
pkg install -y termux-x11-nightly
termux-setup-storage
```

The `termux-x11-nightly` package supplies the Termux-side X server launcher; the separate Android Termux-X11 app is also required. If a package name differs in your Termux repository, consult the current Termux-X11 installation instructions.

## 3. Install Debian 13

Check the distribution definitions provided by your installed PRoot Distro:

```sh
proot-distro list
```

Then install Debian:

```sh
proot-distro install debian
proot-distro login debian --shared-tmp
```

**Important:** `debian` is a rolling alias in PRoot Distro's distribution definitions. Do **not** assume it installs Debian 13. Verify the release inside the container:

```sh
cat /etc/os-release
```

Proceed only if it reports **Debian GNU/Linux 13 (trixie)**. If not, select or define a Debian 13 root filesystem explicitly before continuing; do not blindly change APT sources across major releases.

## 4. Configure Debian

Run the following commands **inside Debian as root**:

```sh
apt update
apt install -y sudo locales tzdata dbus-x11 \
  lxqt-core openbox qterminal pcmanfm-qt \
  x11-xserver-utils fonts-noto-core fonts-noto-cjk \
  ca-certificates curl wget git vim
```

Set up a regular user:

```sh
useradd -m -s /bin/bash -G sudo maia
passwd maia
```

Configure a locale as appropriate for your device, for example:

```sh
sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8
```

For Brazilian Portuguese, enable `pt_BR.UTF-8 UTF-8` instead. Exit Debian:

```sh
exit
```

## 5. Launch LXQt with Termux-X11

Open the Termux-X11 Android app. Then, in **Termux**, run:

```sh
export DISPLAY=:0
export XDG_RUNTIME_DIR="$TMPDIR"

pulseaudio --start --exit-idle-time=-1
termux-x11 :0 &

proot-distro login debian --user maia --shared-tmp -- \
  env DISPLAY=:0 XDG_SESSION_TYPE=x11 \
  dbus-launch --exit-with-session startlxqt
```

This is the basic X11 path. Audio forwarding into Debian and graphics acceleration require additional configuration, described below. If LXQt fails to start, first test the X server and D-Bus session before enabling optional graphics features.

## 6. Optional audio forwarding

PulseAudio runs in Termux, while Linux applications run inside Debian. One approach is to expose a TCP listener bound to loopback on the Android host, then set `PULSE_SERVER=tcp:127.0.0.1` inside Debian. **Do not** expose an unauthenticated PulseAudio listener on a public interface. The exact socket/TCP configuration should be tested on the target Android version and PRoot setup.

## 7. Optional graphics acceleration

The original LinuxOnAndroid project explores VirGL and ANGLE. MaiaLinux-Android will follow the same experimental path, but graphics support depends on the GPU, Android version, Termux packages, and Mesa drivers.

```sh
# In Termux, if available in your repository:
pkg install -y virglrenderer-android angle-android
```

For initial validation, use software rendering. After the desktop works, configure a compatible VirGL server and test with `glxinfo -B` (install `mesa-utils` inside Debian). Avoid forcing an OpenGL version or enabling Vulkan paths without verifying driver support.

## 8. Optional applications

Inside Debian, as the regular user:

```sh
sudo apt install -y build-essential cmake pkg-config \
  python3 python3-venv python3-pip \
  firefox-esr libreoffice gimp inkscape \
  mesa-utils
```

Large applications can consume substantial disk space and may perform differently from native Android applications.

## 9. MaiaLinux appearance

The project will provide a consistent LXQt theme, icons, wallpapers, and startup artwork. Proposed asset structure:

```text
assets/
├── wallpapers/
│   ├── maialinux-android-landscape.png
│   └── maialinux-android-portrait.png
├── branding/
│   └── maialinux-android-banner.png
└── themes/
```

Configure the wallpaper in **LXQt Desktop Preferences**. Actual image dimensions should match the tablet's display resolution and orientation. These paths describe the planned repository structure; they are not downloadable assets until added to the repository.

## 10. Optional Termux:Widget launcher

Once the manual launch process works, place a tested shell script in `~/.shortcuts/` and make it executable. The script should start Termux-X11, initialize audio, and enter Debian to launch LXQt. Do not add unconditional `killall -9` commands: they can terminate unrelated sessions and lose work.

## 11. Experimental Windows application support

LinuxOnAndroid also investigates Box64, Box86, Wine and DXVK. MaiaLinux-Android may adopt a separate, optional compatibility layer after the Debian 13/LXQt base is stable. Windows applications, DirectX translation, and x86 emulation are **not** part of the baseline installation and are not guaranteed to work.

## Troubleshooting

| Symptom | First check |
| --- | --- |
| Black screen | Termux-X11 Android app is running; `DISPLAY=:0`; X server process exists |
| LXQt does not start | `dbus-x11`, `startlxqt`, shared temporary directory, and user account |
| Desktop process exits | Android battery/process restrictions and available RAM |
| No audio | PulseAudio server and Debian `PULSE_SERVER` configuration |
| Slow OpenGL | Check software rendering first; verify VirGL compatibility separately |
| Wrong Debian version | Inspect `/etc/os-release` and PRoot Distro's installed Debian definition |

## Roadmap

- [ ] Validate Debian 13 root filesystem installation on ARM64 tablets.
- [ ] Validate LXQt and Termux-X11 startup.
- [ ] Provide reliable start/stop scripts and Termux:Widget integration.
- [ ] Package MaiaLinux wallpapers, icons, and LXQt settings.
- [ ] Test PulseAudio integration.
- [ ] Benchmark software rendering and optional VirGL/ANGLE acceleration.
- [ ] Document tablet keyboard, mouse, touch, and screen rotation behavior.
- [ ] Evaluate optional Box64/Wine compatibility.
- [ ] Add tested device profiles and reproducible installation checks.

## Related projects

- [Maia Platform](https://www.maiaplatform.org/)
- [LinuxOnAndroid](https://github.com/souzamonteiro/linuxonandroid) — reference project and original installation workflow.
- [Termux](https://github.com/termux/termux-app)
- [Termux-X11](https://github.com/termux/termux-x11)
- [PRoot Distro](https://github.com/termux/proot-distro)
- [Debian](https://www.debian.org/)
- [LXQt](https://lxqt-project.org/)

## License

The related LinuxOnAndroid repository uses Apache License 2.0. **Confirm the license for this new repository** and include the corresponding `LICENSE` file before publication. Third-party packages, images, and trademarks retain their own licensing terms.
