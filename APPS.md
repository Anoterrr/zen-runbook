# zen-dots — everyday apps (Windows / Fedora KDE / macOS)

A reference + install commands for the apps actually in daily use, one command per platform wherever a package manager covers it. Companion to `README.md`, not bound by its pillars — this is a factual inventory, not a minimal/vanilla toolkit. WSL2 users: GUI apps run on the Windows host, same as `README.md`'s WSL2 sections — use the Windows list below.

Anything already covered in `README.md` (Git, Zed) is only cross-referenced here, not repeated.

**Editor split, so nothing here looks redundant:** Zed (`README.md`) is the daily driver, LazyVim (`README.md`) is the non-GUI fallback, and **VS Code (below) is scoped specifically to Jupyter notebooks for data debugging** — the one workflow the other two don't cover well.

**Bruno over Insomnia:** both are API clients, so only one is listed. Bruno wins for this setup specifically — collections are plain `.bru` text files you can put straight in a git repo, no forced account or cloud sync, matches this repo's own Organic/Reproducibility pillars. Insomnia's collection format and Kong's cloud-account push don't.

**Obsidian over Notion:** local `.md` files instead of a proprietary cloud database — same Organic/Reproducibility win as Bruno's `.bru` above — and Obsidian ships an official **Verified** Flatpak on Fedora, unlike Notion which has no Linux client at all (was the web app before). Vault structure, daily flow, and the Syncthing setup for cross-device sync (phone/Fedora/Mac) all live in `OBSIDIAN.md`, not repeated here.

**Anki — web app only (ankiweb.net), no desktop install anywhere.** Review-only workflow, no deck creation/editing, no add-ons — the one thing AnkiWeb doesn't do is exactly the thing not needed here. If that ever changes (building decks, using add-ons like AnkiConnect or Image Occlusion), the desktop app is the only place those exist; AnkiWeb can't grow into them.

---

## Windows

```powershell
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id Docker.DockerDesktop
winget install -e --id DBeaver.DBeaver.Community
winget install -e --id Bruno.Bruno
winget install -e --id Bitwarden.Bitwarden
winget install -e --id Brave.Brave
winget install -e --id Obsidian.Obsidian
winget install -e --id TheDocumentFoundation.LibreOffice
winget install -e --id 7zip.7zip
winget install -e --id Microsoft.PowerToys
winget install -e --id VideoLAN.VLC
winget install -e --id OBSProject.OBSStudio
winget install -e --id Audacity.Audacity
winget install -e --id Discord.Discord
winget install -e --id BlenderFoundation.Blender
winget install -e --id Inkscape.Inkscape
winget install -e --id KDE.Krita
winget install -e --id Canva.Affinity

```

Git and Zed on Windows are `README.md`'s WSL2 "install natively on Windows" step — `winget install -e --id Git.Git` / `winget install -e --id ZedIndustries.Zed` are the exact commands for it.

**DaVinci Resolve** — no winget package exists; Blackmagic gates the download behind a free account at https://www.blackmagicdesign.com/products/davinciresolve. The free edition strips H.264/H.265 import *and* export on every platform (patent licensing, not a bug) — if your footage is H.264 (most cameras/phones), either transcode it first (`ffmpeg` to DNxHR/ProRes-compatible/FFV1) or buy the one-time Studio license, which removes the restriction.

Sanity check:

```powershell
$ids = "Microsoft.VisualStudioCode","Docker.DockerDesktop","DBeaver.DBeaver.Community","Bruno.Bruno","Bitwarden.Bitwarden","Brave.Brave","Obsidian.Obsidian","TheDocumentFoundation.LibreOffice","7zip.7zip","Microsoft.PowerToys","VideoLAN.VLC","OBSProject.OBSStudio","Audacity.Audacity","Discord.Discord","BlenderFoundation.Blender","Inkscape.Inkscape","KDE.Krita","Canva.Affinity"
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

One exception needs Flatpak — Obsidian, verified below. Everything else has either an official repo/`.rpm`, or (Discord) is used as a web app instead.

### Native dnf packages

```bash
sudo dnf install -y p7zip p7zip-plugins libreoffice inkscape krita blender audacity

```

`7-Zip`'s GUI is Windows-only — `p7zip` gives the same compression via CLI and your file manager's archive plugin.

### RPM Fusion (needed for VLC/OBS codecs — one-time repo setup)

```bash
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y vlc obs-studio

```

### VS Code (Microsoft's own repo)

```bash
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
sudo dnf install -y code

```

### Podman (not Docker — native Fedora package, no third-party repo)

```bash
sudo dnf install -y podman podman-compose podman-docker

```

`podman-docker` provides the `docker` command as a thin wrapper around Podman, so existing `docker`/`docker-compose` commands and scripts keep working without a rewrite. Runs rootless by default — no root daemon, no `usermod -aG docker` group grant, and no third-party repo/GPG import the way Docker's own `docker-ce.repo` needs.

Sanity check:

```bash
for bin in podman podman-compose docker; do
    command -v $bin >/dev/null && echo "OK      $bin" || echo "MISSING $bin"
done
podman info --format '{{.Host.Security.Rootless}}'   # should print true

```

### Obsidian (replaces Notion)

Obsidian ships an official **Verified** Flatpak — checked directly on its Flathub listing, the Obsidian team controls this build, same trust level as downloading from their own site:

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub md.obsidian.Obsidian

```

Vault structure, daily flow, and the Syncthing setup for cross-device sync (Fedora/Mac/Android) are in `OBSIDIAN.md`, not repeated here.

Sanity check:

```bash
flatpak list | grep -q md.obsidian.Obsidian && echo "OK      Obsidian" || echo "MISSING Obsidian"

```

### Where these actually come from — checked against Flathub's own verification status, and against what `topgrade` actually updates

Before defaulting everything without a dnf package to Flatpak, I checked each one's actual Flathub listing. None of DBeaver, Bitwarden, or Brave were marked **Verified** — Flathub's own page for each states it's "not verified by, affiliated with, or supported by" the vendor, meaning a third party controls the build, not the company that makes the app. That's a real gap against this repo's own Security pillar (vendor's own domain, not a third party).

Beyond just "official," each pick below is also something `topgrade` (`README.md`) actually knows how to update on its own — the point is `topgrade` once and never think about any of these individually again:

**Brave — official repo, `topgrade` updates it as a normal dnf package:**

```bash
sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo dnf install -y brave-browser

```

**Bitwarden & DBeaver — official Snap, not the unverified `.rpm`-free-for-all:** both publishers ship domain-verified Snaps (`dbeaver-corp` for DBeaver, `8bit Solutions LLC` for Bitwarden — checked directly on Snapcraft, both carry a real "Verified account" badge). Snap also self-updates automatically in the background by design, and `topgrade` has a native Snap step on top of that:

```bash
sudo dnf install -y snapd
sudo ln -s /var/lib/snapd/snap /snap   # Fedora doesn't create this symlink by default
# log out and back in here, then:
sudo snap install dbeaver-ce --classic
sudo snap install bitwarden

```

**fish won't see these commands without one more line.** snapd registers its `PATH` addition in `/etc/profile.d/*.sh` — fish doesn't source `.sh` files, so `dbeaver`/`bitwarden` silently won't be found otherwise (a known, longstanding snapd/fish incompatibility, not specific to this setup). Add it to `~/.config/fish/local.fish` (`README.md`'s escape hatch for exactly this kind of addition, so it survives re-running the fish config block):

```fish
echo 'fish_add_path -g /var/lib/snapd/snap/bin' >> ~/.config/fish/local.fish

```

Trade-off worth naming: Snap becomes a fourth package manager on the machine (dnf + mise + Snap + Flatpak, the last one only for Obsidian) — worth it here specifically because it's the only path that's both vendor-verified and hands-off, not a default to reach for casually.

### No good Linux path

- **Bruno** — no official Flatpak; grab the `.rpm`/AppImage from https://www.usebruno.com.
- **Discord** — no first-party path exists on Fedora at all (no `.rpm`, no repo, only `.deb`/`.tar.gz` upstream). Chosen fix: skip installing it — use the web app at https://discord.com/app instead. Trade-off: no global push-to-talk, no "playing X" rich presence, no system-tray integration.
- **Affinity** — no Linux build, no workaround worth using.

### Steam & NVIDIA (RTX 5070 / Blackwell) — the one gaming exception in this file

Everything else here is deliberately non-gaming, but a GPU driver is hardware setup, not a game library, so it earns a spot. Sourced against a 2026 field report from someone running this exact card on Fedora KDE Wayland ([falcao.org](https://falcao.org/posts/nvidia-fedora-kde-wayland/)) plus current RPM Fusion/Fedora docs — not generic NVIDIA-on-Linux advice.

**1. NVIDIA driver.** RPM Fusion needed first — same repo as the VLC/OBS step above, skip if already done:

```bash
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda

```

`xorg-x11-drv-nvidia-cuda` is optional for pure gaming, but worth having given `README.md`'s PySpark/data work — CUDA is what a GPU-accelerated Python stack (RAPIDS, PyTorch) needs. **Blackwell (RTX 50-series) only works with NVIDIA's open-source kernel modules** — proprietary modules don't support this card at all. `akmod-nvidia` already resolves to the open variant automatically for Blackwell, nothing extra to select; the verification step below confirms it actually did.

**Wait 2–5 minutes** before rebooting — `akmods` builds the kernel module in the background right after install, and rebooting too soon means it isn't there yet.

**2. Secure Boot — only if it's on:**

```bash
mokutil --sb-state   # tells you if this section applies at all

```

If enabled:

```bash
sudo kmodgenca -a
sudo mokutil --import /etc/pki/akmods/certs/public_key.der

```

Set a temporary password when prompted, reboot. A blue MOK Manager screen appears before Fedora boots — choose **Enroll MOK → Continue**, enter that password, reboot again. Without this, Secure Boot refuses to load the unsigned akmod-built module and the driver silently doesn't work.

**3. Steam and gaming helpers:**

```bash
sudo dnf install -y steam gamemode gamemode.i686 mangohud mangohud.i686 vulkan-tools

```

Use `gamemode`/`MangoHud` per-game via a Steam launch option: `gamemoderun mangohud %command%`.

**4. Verify** (all five matter — a driver that "installs" without matching all five isn't actually working):

```bash
modinfo -F version nvidia                                    # driver version
cat /sys/module/nvidia_drm/parameters/modeset                 # must print Y — required for Wayland
modinfo nvidia | grep -i license                              # must say "Dual MIT/GPL" — confirms the open module loaded, not the (unsupported) proprietary one
echo $XDG_SESSION_TYPE                                        # wayland
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
vulkaninfo --summary | grep deviceName                        # confirms Vulkan sees the GPU — what Proton/DXVK needs for Windows games

```

**Watch, don't switch yet — NVK/Nouveau:** the open-source Vulkan driver for NVIDIA (Mesa, Valve-backed) covers Blackwell and is Vulkan 1.4 conformant, but its own lead developer put it at ~50% of proprietary-driver speed as of late 2025, with ray tracing still incomplete — not a gaming replacement today. No committed date exists for parity; revisit this once NVK exits Mesa's "experimental" status, the project's own stated bar for maturity, not a specific year.

**Known Blackwell-specific rough edges** (per the field report above, not resolved by anything in this guide — check the source if you hit either):
- Suspend-to-idle can hang on resume on some kernel versions; the documented workaround forces `s2idle` sleep mode instead of `deep`.
- Variable refresh rate (VRR) isn't automatic — enable it manually in System Settings → Display & Monitor, or via `kscreen-doctor`.

### DaVinci Resolve — Fedora is unofficial, expect manual steps

Blackmagic only officially supports Rocky Linux; Fedora works, but not out of the box.

1. Download the free `.run` installer from https://www.blackmagicdesign.com/products/davinciresolve (needs a free account — no dnf/flatpak package exists).
2. Fedora deprecated the zlib version the installer checks for, and Resolve ships its own outdated GLib libraries that conflict with Fedora's — skip the check to install, then the app itself will run against Fedora's newer GLib once the outdated bundled copies are moved aside:

```bash
chmod +x ./DaVinci_Resolve_*_Linux.run
SKIP_PACKAGE_CHECK=1 ./DaVinci_Resolve_*_Linux.run

```

A community script (`fedora-resolve` on GitHub) automates this plus GPU-specific fixes in one command — that's a third-party script patching system libraries, a meaningfully bigger trust ask than anything else in this repo (`HARDENING.md` covers exactly why to read a script before running it, not pipe it blind). The manual steps above are the safer default; reach for the script only after reading what it does.

**The free-version codec limitation is the same on every platform** — H.264/H.265 import and export are stripped entirely (patent licensing, not a bug), worse to hit on Linux since it's also the platform Blackmagic supports least. Fix: transcode with `ffmpeg` to DNxHR/ProRes-compatible/FFV1 before importing, or buy the one-time Studio license, which removes the restriction and adds hardware-accelerated decode.

Sanity check:

```bash
for bin in p7zip libreoffice inkscape krita blender audacity vlc obs code podman steam gamemoderun mangohud vulkaninfo nvidia-smi brave-browser bitwarden dbeaver-ce; do
    command -v $bin >/dev/null && echo "OK      $bin" || echo "MISSING $bin"
done

```

---

## macOS

```bash
brew install --cask visual-studio-code docker-desktop dbeaver-community bruno \
  bitwarden brave-browser obsidian libreoffice keka vlc obs discord \
  blender inkscape krita affinity

```

`7-Zip` has no macOS build either — `keka` is the common equivalent. Syncthing setup for this Mac (Obsidian vault sync) is in `OBSIDIAN.md`, not repeated here.

### No good macOS path

- **DaVinci Resolve** — no Homebrew cask (repeatedly requested, never added); download from https://www.blackmagicdesign.com/products/davinciresolve or the Mac App Store. Same free-version H.264/H.265 stripping as everywhere else — see the Fedora section above for the fix.

Sanity check:

```bash
for app in visual-studio-code docker-desktop dbeaver-community bruno bitwarden brave-browser obsidian anki libreoffice keka vlc obs discord blender inkscape krita affinity; do
    brew list --cask $app >/dev/null 2>&1 && echo "OK      $app" || echo "MISSING $app"
done

```
