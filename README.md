# MaiaLinux-Android

![alt text](<images/Pôster neon do MaiaLinux com Tux e Android.png>)

**A Lightweight Linux Desktop for Android (Debian 13 Trixie + LXQt)**

MaiaLinux-Android brings a Debian 13 (Trixie) desktop environment to compatible Android devices using Termux, PRoot and Termux-X11. It uses the lightweight **LXQt** desktop, retaining the MaiaLinux visual identity while allowing Linux applications to run alongside Android.

> **Project status:** Under active development. MaiaLinux-Android now features Debian 13 (Trixie), LXQt with touch/tablet optimizations, a dedicated on-screen virtual keyboard with programming layouts, and tablet-optimized MaiaLinux wallpapers.

## Overview

| Component | Technology |
| --- | --- |
| Host operating system | Android (ARM64 recommended) |
| Terminal and package manager | Termux |
| Linux userspace | Debian 13 (Trixie), via PRoot Distro |
| Desktop environment | LXQt (Openbox + PCManFM-Qt) |
| Display server integration | Termux-X11 (X11) |
| Audio | PulseAudio (TCP loopback) |
| On-screen keyboard | `onboard` & `matchbox-keyboard` with custom MaiaLinux layout |
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
- Optional: Termux:Widget for launching the desktop from the Android home screen.

Download links:
- Termux: https://github.com/termux/termux-app
- Termux-X11: https://github.com/termux/termux-x11
- Termux:Widget: https://github.com/termux/termux-widget

---

## 1. Automated Installation & Setup

### Passo 1: Preparar o Termux e instalar Debian 13

No **Termux** (fora do Debian), execute o script de preparação:

```sh
cd ./maialinux-android/termux/scripts
./setup.sh
```

Esse script atualiza os pacotes do Termux, instala o `proot-distro`, `x11-repo`, `termux-x11-nightly`, `pulseaudio`, aceleração gráfica (`virglrenderer-android`, `angle-android`) e baixa o Debian no PRoot Distro.

### Passo 2: Entrar no Debian e configurar o MaiaLinux (Debian 13 + LXQt)

Ainda no Termux, entre no container Debian:

```sh
proot-distro login debian --shared-tmp
```

Dentro do container Debian (como root), execute o instalador completo:

```sh
cd ./maialinux-android/debian/scripts
./setup.sh
```

O script `setup.sh`:
1. Configura os repositórios oficiais do **Debian 13 (Trixie)** com componentes `main contrib non-free non-free-firmware`.
2. Atualiza o sistema (`apt update && apt dist-upgrade`).
3. Remove qualquer resquício legado do XFCE.
4. Instala o ambiente **LXQt** (`lxqt-core`, `lxqt-panel`, `openbox`, `pcmanfm-qt`, `qterminal`), ícones `Papirus-Dark`, fontes DejaVu e Noto.
5. Instala e configura os teclados virtuais (`onboard` e `matchbox-keyboard`).
6. Configura o usuário padrão `maia` (e `user`) com permissões sudo sem senha e grupos de áudio/vídeo.
7. Instala os papéis de parede para tablet em `/usr/share/wallpapers/maialinux/`.
8. Aplica as configurações visuais do MaiaLinux (tema Dark Catppuccin, barra inferior de 36px com ícone de teclado, menu Maia e atalhos rápidos).

---

## 2. Iniciar o MaiaLinux (LXQt)

Abra o aplicativo **Termux-X11** no Android. Em seguida, no **Termux**, execute:

```sh
cd ./maialinux-android/termux/scripts
./Debian.sh
```

Ou se preferir via startup do Termux-X11:
```sh
./startlxqt.sh
```

Para fechar todas as sessões e processos em segundo plano:
```sh
./killall.sh
```

---

## 3. Recursos do Desktop MaiaLinux para Tablet

### Teclado Virtual na Tela (On-Screen Keyboard)
- O teclado virtual pode ser alternado a qualquer momento com um toque no ícone de teclado na **barra de tarefas (Quicklaunch)** ou na área de trabalho.
- Se você tiver um teclado físico conectado, pode pressionar **F12** para exibir/ocultar o teclado.
- Utiliza `onboard` (com suporte a toque, redimensionamento automático e predição) ou `matchbox-keyboard` com o layout de programação do MaiaLinux (4 linhas, 50 teclas, números dedicados e símbolos de programação acessíveis).
- Script de controle: `/usr/local/bin/maialinux-keyboard-toggle`.

### Papéis de Parede para Tablet
Adicionados papéis de parede em alta resolução na pasta `images/`:
1. **Paisagem Neon com Logo Maialinux** (`maialinux-tablet-neon.png`)
2. **Paisagem Roxa com Logo MAIALINUX** (`maialinux-tablet-purple.png`)
3. **Pôster neon do MaiaLinux com Tux e Android** (`maialinux-tablet-tux-android.png`)

Para alternar entre eles a qualquer momento:
- Clique no ícone **Alternar Papel de Parede** na barra ou na Área de Trabalho.
- Ou execute no terminal:
  ```sh
  maialinux-wallpaper.sh next
  ```

---

## 4. Opcional: Aceleração Gráfica 3D (VirGL / ANGLE)

O script `Debian.sh` já inicializa o servidor `virgl_test_server_android` em segundo plano com ANGLE Vulkan.
Dentro do Debian, aplicações com aceleração utilizam os scripts em `/usr/local/bin/`:
- `firefox-virgl.sh`
- `wings3d-virgl.sh`

Para testar a aceleração 3D dentro do Debian:
```sh
GALLIUM_DRIVER=virpipe glxinfo -B
```

---

## 5. Estrutura do Projeto

```text
maialinux-android/
├── android/
│   └── scripts/            # Scripts ADB para controle de processos phantom no Android
├── debian/
│   ├── bin/                # Utilitários (teclado virtual, alternador de papel de parede, virgl)
│   ├── config/             # Configurações do LXQt, Openbox, PCManFM-Qt e Matchbox
│   │   ├── keyboard/       # Layout de teclado de programação XML
│   │   ├── lxqt/           # Tema, painel, sessão e pcmanfm-qt
│   │   └── openbox/        # Regras de janelas, atalhos de toque e F12
│   ├── desktop/            # Atalhos .desktop (Teclado, Papel de Parede, Terminal, IDE)
│   ├── scripts/
│   │   ├── setup.sh        # Instalador completo do Debian 13 + LXQt + MaiaLinux
│   │   └── setup_wine.sh   # Configuração opcional de Box86/Box64 e Wine
│   └── wallpapers/         # Papéis de parede instalados no sistema
├── images/                 # Papéis de parede originais de alta resolução para tablet
├── termux/
│   └── scripts/
│       ├── setup.sh        # Setup de pacotes Termux e criação do container
│       ├── Debian.sh       # Inicializador completo (X11 + áudio + LXQt)
│       ├── startlxqt.sh    # Inicializador LXQt
│       ├── startdebian.sh  # Login direto no LXQt
│       └── killall.sh      # Encerramento limpo de processos
└── README.md
```

## Solução de Problemas

| Sintoma | Verificação inicial |
| --- | --- |
| Tela preta no Termux-X11 | Verifique se o app Termux-X11 está aberto em primeiro plano; certifique-se de que `DISPLAY=:0` está exportado |
| LXQt não inicia | Certifique-se de ter rodado `debian/scripts/setup.sh` dentro do container Debian e que `dbus-x11` está instalado |
| Teclado virtual não abre | Verifique se `onboard` ou `matchbox-keyboard` estão instalados (`sudo apt install onboard matchbox-keyboard`) |
| Sem áudio | Verifique se o PulseAudio no Termux iniciou com o módulo TCP (`pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1"`) |
| Processo fecha sozinho no Android | Desative a limitação de phantom processes do Android (`android/scripts/disable_phantom_process_killer.sh`) |

## Licença

Distribuído sob licença compatível com o projeto MaiaLinux e Apache 2.0.
