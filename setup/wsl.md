# Fedora WSL2

Two parts: create the instance (before `fedora.md`), then the Windows-side steps (after it).

## 1. Create the instance first

On WSL2 everything runs inside Fedora, so Fedora has to exist first. In PowerShell:

```powershell
wsl --list --online
wsl --install FedoraLinux-44

```

Open the new Fedora shell and do `fedora.md` (the shared part only), then come back here.

---

# Fedora WSL2: after the shared setup

## Windows interop: restore it after Podman

Podman pulls in `qemu-user-static` (through `containers-common-extra`), which registers binfmt handlers for other CPU architectures. On WSL2 that knocks out `WSLInterop`, the handler that lets Linux run Windows `.exe` files, so `powershell.exe`, `cmd.exe` and `winget.exe` stop working with "cannot execute binary file". These lines put it back now and on every boot, since `systemd-binfmt` reads `/etc/binfmt.d/`:

```bash
echo ':WSLInterop:M::MZ::/init:PF' | sudo tee /etc/binfmt.d/WSLInterop.conf > /dev/null
test -e /proc/sys/fs/binfmt_misc/WSLInterop \
  || echo ':WSLInterop:M::MZ::/init:PF' | sudo tee /proc/sys/fs/binfmt_misc/register > /dev/null

```

The steps below and `../audit.sh` call `winget.exe` and `cmd.exe` from Fedora, so they need this first.

If `systemctl --failed` lists `systemd-binfmt` right after installing Podman, it's harmless: the qemu packages restart it once each during install and it hits systemd's restart limit. `sudo systemctl reset-failed systemd-binfmt` clears it, and it runs normally on every boot after.

## Shared root mount, for Podman

WSL2 mounts `/` as private, and Podman warns `"/" is not a shared mount` on every command. Most containers still run, but a volume that needs mount propagation doesn't. This makes it shared on every boot, and the second line does it now:

```bash
grep -q make-rshared /etc/wsl.conf || sudo sed -i '/^\[boot\]/a command = mount --make-rshared /' /etc/wsl.conf
sudo mount --make-rshared /

```

## Zed and fonts: installed on host Windows side

Ghostty doesn't run on Windows, so WSL uses Windows Terminal. Zed gets installed on Windows and connects to the Fedora WSL instance as a remote target, the same way VS Code Remote-WSL works. `git` isn't installed on Windows because it's already inside Fedora WSL2, and that's where the dev work happens:

```powershell
winget install -e --id ZedIndustries.Zed

```

The font also goes on Windows, because Windows Terminal draws the text. Same release and hash as the Fedora KDE section in `fedora.md`, installed for the current user only (no admin):

```powershell
$zip = "$env:TEMP\JetBrainsMono.zip"
$src = "$env:TEMP\JetBrainsMono"
$dst = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
Invoke-WebRequest "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.zip" -OutFile $zip
if ((Get-FileHash $zip -Algorithm SHA256).Hash -eq "fab782a66f7d3019da64f6572db9fc5d3a4bcb19f9fa13e2d8a62e3693d6396e") {
    Expand-Archive $zip $src -Force
    New-Item -ItemType Directory -Force $dst | Out-Null
    Get-ChildItem "$src\*.ttf" | ForEach-Object {
        Copy-Item $_.FullName $dst -Force
        New-ItemProperty "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Name "$($_.BaseName) (TrueType)" -Value "$dst\$($_.Name)" -Force | Out-Null
    }
} else {
    Write-Host "MISMATCH hash, font not installed"
}
Remove-Item $zip, $src -Recurse -Force -ErrorAction SilentlyContinue

```

Copying the files and adding the registry entry is exactly what right-click → "Install" does for a single user. Then point Windows Terminal at it: Settings → the Fedora profile → Appearance → Font face → `JetBrainsMono Nerd Font`. Without this step starship's icons show up as boxes.

The everyday Windows apps are in `../APPS.md`.

---

Next: `shell.md`. `../audit.sh` checks interop, the shared mount, Zed, the font and the Windows Terminal setting from inside Fedora.
