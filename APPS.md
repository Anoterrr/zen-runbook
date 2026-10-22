# zen-runbook - apps (Windows / Fedora KDE / macOS)

Desktop apps, under the same pillars as `README.md`. This file says why each one is here, the lists in `packages/` install them, and `audit.sh` checks them. GUI apps on WSL2 run on the Windows host, so WSL2 uses the Windows list.

Each machine's role decides what goes on it:

- **Windows + Fedora WSL2**: main machine. Data engineering, games, recording and editing, guitar.
- **Fedora KDE**: where the main machine is headed. Same apps as Windows wherever they run on Linux, so the move doesn't change how I work.
- **macOS**: work machine, managed by the company's MDM. Work tools, plus my notes and browser.

## Apps

| App | Why | Win | KDE | Mac |
|---|---|:-:|:-:|:-:|
| Bitwarden | Every password, unique per site (`HARDENING.md`). The work Mac uses the company's | ✓ | ✓ | |
| Brave | Browser, blocks trackers and ads by default (`HARDENING.md`) | ✓ | ✓ | ✓ |
| Obsidian | Notes as local `.md` files (`OBSIDIAN.md`) | ✓ | ✓ | ✓ |
| Syncthing | Syncs the vault peer to peer, no server in between (`OBSIDIAN.md`) | ✓ | ✓ | ✓ |
| Bruno | API client. Collections are plain text files in git, no account | ✓ | ✓ | ✓ |
| DBeaver | SQL client for every database I touch | ✓ | ✓ | ✓ |
| Discord | Talking with friends while playing and recording | ✓ | ✓ | |
| Anki | Spaced-repetition reviews | ✓ | ✓ | |
| LibreOffice | Office files people send me | ✓ | ✓ | |
| VLC | Plays any file, raw recordings included | ✓ | ✓ | |
| OBS Studio | Records gameplay | ✓ | ✓ | |
| DaVinci Resolve | Edits the channel's videos | ✓ | ✓ | |
| Affinity | Thumbnails and graphics: vector, raster and layout in one free app | ✓ | | |
| Inkscape, Krita | Same jobs as Affinity, but they run on Linux too, so they're the ones that move with me | ✓ | ✓ | |
| Reaper | DAW for guitar and narration | ✓ | ✓ | |
| Neural Amp Modeler | Amp simulation inside Reaper. The same `.nam` captures load on every OS, so the guitar setup moves to Linux unchanged | ✓ | ✓ | |
| Steam | Games | ✓ | ✓ | |
| NVIDIA App | GPU driver updates on Windows | ✓ | | |
| Rancher Desktop | Containers and local Kubernetes for work (`setup/macos.md`) | | | ✓ |
| p7zip | 7z support for KDE's archive tool. Windows 11 and macOS handle the common formats themselves | | ✓ | |

## Web apps

They run the same on every machine, so they never block a move to Fedora and there's no platform column. `audit.sh` can't see them, so this list is the check. Each one is an account: password in Bitwarden, 2FA on, and when I stop using one I close the account instead of leaving it behind. Daily ones get Brave's "Install app", which gives them their own window and taskbar icon on Windows, Fedora and macOS alike.

| App | Why | Where the data lives, and how I get it out |
|---|---|---|
| GitHub | Code, this repo included. `gh` covers the CLI side (`GIT.md`) | Every repo is a local clone. Issues and PRs through `gh` or GitHub's migration export |
| YouTube Studio | Runs the channel | The edited masters stay on my disk, since YouTube only keeps its re-encode. Channel data through Google Takeout |
| YouTube Music | Music | Library and playlists through Google Takeout |
| Google Drive / Sheets | Sharing a file or sheet with someone who isn't on my tools. Also stores the encrypted backup (`BACKUP.md`) | Takeout, or download as `.xlsx`/`.docx`. Nothing lives only there |
| AnkiWeb | Syncs the desktop Anki (where I create my own cards) with the phone | The real copy is desktop Anki's local collection, with its automatic backups and `.apkg` export |
| Bunpro (free tier) | Japanese grammar | Progress only lives there. Free tier, so nothing paid is at stake |
| WaniKani (free tier) | Japanese kanji | Progress through WaniKani's public API. Free tier, same as Bunpro |

**Watching:** PhotoCraft (`storytold/photocraft`), an open-source, cross-platform Photoshop clone with PSD support. It's alpha (as of 2026-10), so it isn't on the list. If it gets a stable release and a winget package plus a verified Flatpak, it could replace Affinity and Krita on every machine.

**Editors:** Zed is the daily driver and Neovim the fallback without a GUI (`setup/`). Notebooks for debugging data run with `uvx marimo edit <file>.py`: no install, `uv` is already in the toolkit, and a marimo notebook is a plain `.py` file that diffs cleanly in git.

---

## Windows

The list is `packages/windows-apps.winget.json`, in the format winget's own `export` writes. Run it from Fedora WSL2, where the repo lives (it needs the interop step in `setup/wsl.md`). Anything already installed is skipped:

```bash
winget.exe import -i "$(wslpath -w ~/repos/zen-runbook/packages/windows-apps.winget.json)" \
  --accept-package-agreements --accept-source-agreements

```

Three apps come straight from the vendor's site, because winget can't track them:

**NVIDIA App**: https://www.nvidia.com/software/nvidia-app/. winget only has the Microsoft Store build, which is a separate install from the one on NVIDIA's site and doesn't show up as the same package. It updates itself and the driver. NVIDIA publishes no checksum for it.

**Neural Amp Modeler**: the official plugin installer from https://www.neuralampmodeler.com/ (Steven Atkinson, its author). No winget package and no published checksum.

**DaVinci Resolve** has no winget package. Download it from https://www.blackmagicdesign.com/products/davinciresolve (free account required). Blackmagic publishes no checksum either, so these three are the only downloads in this repo that can't be pinned and verified. The free version reads and exports H.264/H.265 on Windows through the OS's own codecs (as of 2026-10).

**OBS records audio as PCM**, not AAC: Settings → Output, Output Mode "Advanced" → Recording, container MKV, audio encoder "FFmpeg PCM (16-bit)". On Windows either works, but Resolve on Linux can't read AAC even in Studio, so recordings made today stay editable after the move. Video stays H.264/HEVC through NVENC. Recording Path: a `Recordings` folder in my user folder, not the default Videos, which `BACKUP.md` sends to Google Drive and raw gameplay would fill.

---

## Fedora KDE

### 1. Repos (one time)

Terra is already added by `setup/fedora.md`.

```bash
# RPM Fusion: VLC/OBS codecs, Steam, NVIDIA driver
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Brave
sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

# Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

```

### 2. Install

```bash
sudo dnf install -y $(grep -v '^#' ~/repos/zen-runbook/packages/fedora-kde-apps.txt)
flatpak install -y flathub $(grep -v '^#' ~/repos/zen-runbook/packages/flathub.txt)

```

Every app comes from Fedora, RPM Fusion (VLC and OBS, for the codecs), the vendor's own repo (Brave) or a Flatpak marked **Verified** on Flathub (the vendor publishes it). The exception is DBeaver (`dbeaver-bin`), from Terra: DBeaver has no dnf repo, its Flatpak isn't verified, and its RPM never updates. Terra is already trusted for Ghostty and Zed, so this adds no new source.

Not on Linux, and why that's fine:

- **Affinity**: no Linux build (as of 2026-10). Inkscape and Krita cover the same jobs.
- **Reaper and Neural Amp Modeler**: guitar moves when I move it, with no change to how I play. Reaper has a native Linux build on reaper.fm, same license, with LV2 support, but no package or verified Flatpak (as of 2026-10). NAM's author ships no Linux plugin. The LV2 port is `mikeoliphant/neural-amp-modeler-lv2`, a third party, and its releases publish a SHA-256 per file to pin against. The Scarlett Solo is class-compliant and needs no driver. Turn off its MSD mode once with Focusrite Control on Windows before moving.

### 3. Steam & NVIDIA (RTX 5070 / Blackwell)

**NVIDIA driver**, from RPM Fusion:

```bash
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda

```

snapper (`setup/fedora.md`) takes a snapshot before this and every later driver update, so a driver that breaks the desktop can be undone from a text console. `xorg-x11-drv-nvidia-cuda` is for GPU-accelerated Python (RAPIDS, PyTorch), not games. Blackwell cards only work with NVIDIA's open kernel modules, and `akmod-nvidia` picks those on its own. **Wait 2-5 minutes before rebooting**: `akmods` builds the module in the background, and an early reboot leaves it missing.

**Secure Boot**, only if `mokutil --sb-state` says it's enabled:

```bash
sudo kmodgenca -a
sudo mokutil --import /etc/pki/akmods/certs/public_key.der

```

Set a temporary password, reboot, and in the blue MOK Manager screen choose **Enroll MOK → Continue**, type the password and reboot again. Without this, Secure Boot silently refuses the module.

**Steam and gaming helpers:**

```bash
sudo dnf install -y steam gamemode gamemode.i686 mangohud mangohud.i686 vulkan-tools

```

Per game, Steam launch option: `gamemoderun mangohud %command%`.

**Verify.** A driver that fails any of these isn't working:

```bash
modinfo -F version nvidia                                    # driver version
cat /sys/module/nvidia_drm/parameters/modeset                 # must print Y, required for Wayland
modinfo nvidia | grep -i license                              # must say "Dual MIT/GPL": the open module loaded
echo $XDG_SESSION_TYPE                                        # wayland
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
vulkaninfo --summary | grep deviceName                        # Vulkan sees the GPU, which Proton/DXVK needs
for bin in steam gamemoderun mangohud; do
    command -v $bin >/dev/null && echo "OK      $bin" || echo "MISSING $bin"
done

```

Known Blackwell issues (as of 2026-09, from [falcao.org](https://falcao.org/posts/nvidia-fedora-kde-wayland/)): suspend can hang on resume on some kernels (force `s2idle` sleep instead of `deep`), and VRR has to be turned on by hand in System Settings → Display & Monitor.

### 4. DaVinci Resolve

Blackmagic only supports Rocky Linux (as of 2026-10). The free version on Linux can't read or write H.264/H.265 at all, and transcoding long gameplay sessions to an editing codec means hundreds of GB per hour. So on Fedora it's **Resolve Studio**: a one-time license that works on Windows and Linux, and on Linux decodes and encodes H.264/H.265 through the NVIDIA GPU. Even Studio can't read or write AAC on Linux, which is why OBS records PCM (Windows section), and exports go to MOV with Linear PCM audio, which YouTube accepts.

Download the `.run` installer from Blackmagic, then skip its package check (it looks for a zlib Fedora no longer ships):

```bash
chmod +x ./DaVinci_Resolve_*_Linux.run
SKIP_PACKAGE_CHECK=1 ./DaVinci_Resolve_*_Linux.run

```

If it fails to start, move Resolve's bundled GLib libraries out of its `libs` folder so it uses Fedora's.

---

## macOS

```bash
brew bundle --file ~/repos/zen-runbook/packages/macos-apps.Brewfile

```

Work tools plus Obsidian, Syncthing and Brave, nothing personal beyond that. Rancher Desktop is in the toolkit Brewfile (`setup/macos.md`). Syncthing is a formula, not a cask, because it's a background service. `OBSIDIAN.md` starts it.
