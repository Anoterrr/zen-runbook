# zen-runbook - everyday apps (Windows / Fedora KDE / macOS)

The apps I use day to day, with install commands for each platform wherever a package manager has them. This is a companion to `README.md`, but it doesn't follow that file's pillars: it's an inventory, not a minimal toolkit. On WSL2, GUI apps run on the Windows host, same as in `README.md`, so use the Windows list.

Anything already in `README.md` (Git, Zed) is only referenced here.

**Editors:** Zed (`README.md`) is the daily driver and Neovim (`README.md`) is the fallback when there's no GUI. **VS Code (below, Windows and macOS only) is only for Jupyter notebooks** when debugging data, which neither of the other two handles well.

**Bruno over Insomnia:** both are API clients, so I list one. Bruno stores collections as plain `.bru` text files that go straight into a git repo, with no account or cloud sync required. That fits the Organic and Reproducibility pillars in `README.md`. Insomnia uses its own collection format and pushes you toward a Kong cloud account.

**Obsidian over Notion:** notes are local `.md` files instead of a proprietary cloud database, the same reason I picked Bruno. Obsidian also has an official **Verified** Flatpak on Fedora, while Notion has no Linux client at all (I used the web app before). Vault structure, daily flow and Syncthing sync across phone, Fedora and Mac are in `OBSIDIAN.md`.

**Anki: web app only (ankiweb.net), no desktop install.** I only review cards. I don't create or edit decks and don't use add-ons, and those are the only things AnkiWeb can't do. If that changes (building decks, add-ons like AnkiConnect or Image Occlusion), I'll need the desktop app.

---

## Windows

Run in PowerShell. The accept flags skip the license prompts, so the whole list installs without stopping:

```powershell
$ids = @(
    "Microsoft.VisualStudioCode", "DBeaver.DBeaver.Community", "Bruno.Bruno",
    "Bitwarden.Bitwarden", "Brave.Brave", "Obsidian.Obsidian",
    "TheDocumentFoundation.LibreOffice", "7zip.7zip", "Microsoft.PowerToys",
    "VideoLAN.VLC", "OBSProject.OBSStudio", "Audacity.Audacity", "Discord.Discord",
    "BlenderFoundation.Blender", "Inkscape.Inkscape", "KDE.Krita", "Canva.Affinity"
)
foreach ($id in $ids) {
    winget install -e --id $id --accept-package-agreements --accept-source-agreements
}

```

No Docker Desktop. Containers run with Podman inside Fedora WSL2 (`README.md`, shared Fedora setup, step 3), same as on Fedora KDE and macOS.

Zed on Windows is covered by the "installed on host Windows side" step in `README.md` (`winget install -e --id ZedIndustries.Zed`). `git` isn't in this list because it lives inside Fedora WSL2 (`README.md`, shared Fedora setup, step 1). All dev work happens in the WSL2 filesystem, so a Windows copy of git would go unused.

**DaVinci Resolve** has no winget package. Blackmagic requires a free account to download it from https://www.blackmagicdesign.com/products/davinciresolve. The free edition can't import *or* export H.264/H.265 on any platform, because of patent licensing. If your footage is H.264 (most cameras and phones), transcode it first (`ffmpeg` to DNxHR, ProRes-compatible or FFV1) or buy the one-time Studio license, which removes the restriction.

Sanity check (same window as the install, it reuses `$ids`):

```powershell
foreach ($id in $ids) {
    if (winget list -e --id $id 2>$null | Select-String -SimpleMatch $id) {
        Write-Host "OK      $id"
    } else {
        Write-Host "MISSING $id"
    }
}

```

---

## Fedora KDE

Two steps: add the repos once, then install everything. Terra is already added by `README.md`'s Fedora KDE section. Every app comes from its vendor, through a dnf repo or a Flatpak marked **Verified** on Flathub (the vendor publishes that build). DBeaver is the one exception, see below. `topgrade` (`README.md`) updates all of it.

### 1. Repos (one time)

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
sudo dnf install -y p7zip p7zip-plugins libreoffice inkscape krita blender audacity \
  vlc obs-studio brave-browser dbeaver-bin
flatpak install -y flathub md.obsidian.Obsidian com.usebruno.Bruno com.bitwarden.desktop com.discordapp.Discord

```

Where each one comes from:

- **dnf, Fedora repos**: p7zip, LibreOffice, Inkscape, Krita, Blender, Audacity. The `7-Zip` GUI only exists on Windows, and `p7zip` gives the same compression on the CLI and through the file manager's archive plugin.
- **dnf, vendor or RPM Fusion repos**: VLC and OBS (RPM Fusion, for the codecs), Brave (Brave's own repo).
- **Flatpak, verified**: Obsidian, Bruno, Bitwarden, Discord.
- **dnf, Terra**: DBeaver (`dbeaver-bin`). DBeaver has no dnf repo of its own, its Flatpak isn't verified, and its official RPM is a one-off download that never updates. Terra repackages the official release and is already set up by `README.md`'s Fedora KDE section for Ghostty and Zed, so this adds no new trust. The catch: a Terra maintainer builds this package, not DBeaver.

Vault structure, daily flow and Syncthing sync for Obsidian (Fedora/Mac/Android) are in `OBSIDIAN.md`.

Sanity check:

```bash
for bin in 7za libreoffice inkscape krita blender audacity vlc obs brave-browser; do
    command -v $bin >/dev/null && echo "OK      $bin" || echo "MISSING $bin"
done
rpm -q dbeaver-bin >/dev/null && echo "OK      dbeaver-bin" || echo "MISSING dbeaver-bin"
for app in md.obsidian.Obsidian com.usebruno.Bruno com.bitwarden.desktop com.discordapp.Discord; do
    flatpak info $app >/dev/null 2>&1 && echo "OK      $app" || echo "MISSING $app"
done

```

### No good Linux path

- **Affinity**: no Linux build, and no workaround I'd use.

### Steam & NVIDIA (RTX 5070 / Blackwell)

The only gaming entry in this file. A GPU driver is hardware setup, so it belongs here even though the rest of this list isn't about games. Based on a 2026 write-up from someone running this card on Fedora KDE Wayland ([falcao.org](https://falcao.org/posts/nvidia-fedora-kde-wayland/)) and the current RPM Fusion and Fedora docs.

**1. NVIDIA driver.** Comes from RPM Fusion, added in step 1 above:

```bash
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda

```

`xorg-x11-drv-nvidia-cuda` isn't needed for games. I install it for the PySpark and data work in `README.md`, since GPU-accelerated Python (RAPIDS, PyTorch) needs CUDA. **Blackwell cards (RTX 50-series) only work with NVIDIA's open-source kernel modules.** The proprietary modules don't support them. `akmod-nvidia` picks the open variant for Blackwell on its own, and the verify step below confirms that.

**Wait 2-5 minutes** before rebooting. `akmods` builds the kernel module in the background after install, and if you reboot too early it won't be there.

**2. Secure Boot (only if it's on):**

```bash
mokutil --sb-state   # tells you if this section applies at all

```

If enabled:

```bash
sudo kmodgenca -a
sudo mokutil --import /etc/pki/akmods/certs/public_key.der

```

Set a temporary password when asked, then reboot. A blue MOK Manager screen shows up before Fedora boots: choose **Enroll MOK → Continue**, type the password and reboot again. Skip this and Secure Boot refuses to load the akmod-built module, so the driver just doesn't work, with no error.

**3. Steam and gaming helpers:**

```bash
sudo dnf install -y steam gamemode gamemode.i686 mangohud mangohud.i686 vulkan-tools

```

Turn on `gamemode` and `MangoHud` per game with this Steam launch option: `gamemoderun mangohud %command%`.

Sanity check:

```bash
for bin in steam gamemoderun mangohud vulkaninfo nvidia-smi; do
    command -v $bin >/dev/null && echo "OK      $bin" || echo "MISSING $bin"
done

```

**4. Verify.** Check every line. A driver that installed but fails any of these isn't working:

```bash
modinfo -F version nvidia                                    # driver version
cat /sys/module/nvidia_drm/parameters/modeset                 # must print Y, required for Wayland
modinfo nvidia | grep -i license                              # must say "Dual MIT/GPL", confirms the open module loaded, not the (unsupported) proprietary one
echo $XDG_SESSION_TYPE                                        # wayland
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
vulkaninfo --summary | grep deviceName                        # confirms Vulkan sees the GPU, which is what Proton/DXVK needs for Windows games

```

**NVK/Nouveau, keep an eye on it but don't switch yet.** It's the open-source Vulkan driver for NVIDIA, part of Mesa and backed by Valve. It supports Blackwell and is Vulkan 1.4 conformant, but in late 2025 its lead developer put it at about 50% of the proprietary driver's speed, and ray tracing isn't finished. There's no date for catching up. Look again when Mesa drops the "experimental" label from NVK, since that's the project's own sign it's ready.

**Known Blackwell issues** (from the write-up above, not fixed by anything here, see the source if you hit one):
- On some kernel versions, suspend-to-idle can hang on resume. The workaround is forcing `s2idle` sleep instead of `deep`.
- Variable refresh rate (VRR) doesn't turn on by itself. Enable it in System Settings → Display & Monitor, or with `kscreen-doctor`.

### DaVinci Resolve: Fedora isn't supported, expect manual steps

Blackmagic only supports Rocky Linux. Resolve runs on Fedora, but needs some work.

1. Download the free `.run` installer from https://www.blackmagicdesign.com/products/davinciresolve (free account required, no dnf or Flatpak package).
2. The installer checks for a zlib version Fedora no longer ships, and Resolve bundles old GLib libraries that clash with Fedora's. Skip the check to install. After that, move the bundled GLib copies out of the way and the app will use Fedora's newer GLib:

```bash
chmod +x ./DaVinci_Resolve_*_Linux.run
SKIP_PACKAGE_CHECK=1 ./DaVinci_Resolve_*_Linux.run

```

There's a community script, `fedora-resolve` on GitHub, that does all this plus GPU fixes in one command. It's a third-party script that patches system libraries, which is a lot more trust than anything else in this repo asks for (`HARDENING.md` explains why to read a script before running it). Do the manual steps. Only use the script after reading what it does.

**The free version's codec limit applies on every platform:** no H.264/H.265 import or export, because of patent licensing. It hurts more on Linux, the platform Blackmagic supports least. Either transcode with `ffmpeg` to DNxHR, ProRes-compatible or FFV1 before importing, or buy the one-time Studio license, which removes the limit and adds hardware-accelerated decoding.

---

## macOS

```bash
brew install --cask visual-studio-code dbeaver-community bruno \
  bitwarden brave-browser obsidian libreoffice keka vlc obs discord \
  blender inkscape krita affinity

```

`7-Zip` has no macOS build, and `keka` is the usual replacement. Syncthing on the Mac (for Obsidian vault sync) is in `OBSIDIAN.md`.

### Podman (instead of Docker Desktop, same as Fedora)

On macOS, `podman` is a Homebrew formula, not a cask, because it's a background tool and not a GUI app (same as Syncthing in `OBSIDIAN.md`). Containers need a Linux kernel and macOS doesn't have one, so Podman runs a small Linux VM underneath. `podman machine` creates and manages that VM for you:

```bash
brew install podman podman-compose
podman machine init
podman machine start

```

On macOS there's no `podman-docker` package like on Fedora, so `docker` and `docker-compose` don't exist as commands. On Fedora that package installs a real wrapper binary, which also works from cron jobs and other programs. On macOS the closest option is a shell alias, which only works in an interactive shell. It's already in the `~/.zshrc` block in `README.md`, which only sets it when there's no real `docker` binary:

```bash
alias docker='podman'
alias docker-compose='podman-compose'

```

Sanity check:

```bash
brew list podman >/dev/null 2>&1 && echo "OK      podman" || echo "MISSING podman"
podman machine list | grep -q Currently && echo "OK      podman machine running" || echo "MISSING run 'podman machine start'"

```

### No good macOS path

- **DaVinci Resolve**: no Homebrew cask (people have asked, it was never added). Download it from https://www.blackmagicdesign.com/products/davinciresolve or the Mac App Store. The free version has the same H.264/H.265 limit, see the Fedora section for the fix.

Sanity check:

```bash
for app in visual-studio-code dbeaver-community bruno bitwarden brave-browser obsidian libreoffice keka vlc obs discord blender inkscape krita affinity; do
    brew list --cask $app >/dev/null 2>&1 && echo "OK      $app" || echo "MISSING $app"
done

```
