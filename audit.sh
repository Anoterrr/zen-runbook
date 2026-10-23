#!/usr/bin/env bash
# shellcheck disable=SC2088  # the ~ in OK/MISMATCH labels is printed, not expanded
# Read-only check of this machine against the repo. Installs nothing, changes nothing, never asks for sudo.
# Reads the lists in packages/ and the files in config/, so adding a tool there is enough to have it checked.
# Exits 1 if anything is MISSING or MISMATCH.
set -uo pipefail

repo=$(cd "$(dirname "$0")" && pwd -P)
PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
problems=0

ok()      { printf 'OK       %s\n' "$1"; }
bad()     { printf '%-8s %s\n' "$1" "$2"; problems=$((problems + 1)); }
check()   { local label=$1; shift; if "$@" >/dev/null 2>&1; then ok "$label"; else bad MISSING "$label"; fi; }
section() { printf '\n== %s\n' "$1"; }
list()    { grep -v '^#' "$repo/packages/$1" | grep .; }   # a package list without comments or blank lines

if [[ $OSTYPE == darwin* ]]; then platform=macos
elif [[ -n ${WSL_DISTRO_NAME:-} ]]; then platform=wsl
else platform=kde
fi
echo "platform: $platform"

# --- packages ------------------------------------------------------------------
section packages
rpm_check() {
    local pkg
    for pkg in $(list "$1"); do
        if [[ $pkg == @* ]]; then
            check "$pkg" grep -qw "${pkg#@}" <(dnf group list --installed 2>/dev/null)
        else
            check "$pkg" rpm -q "$pkg"
        fi
    done
}
case $platform in
    wsl) rpm_check fedora.txt ;;
    kde)
        rpm_check fedora.txt
        rpm_check fedora-kde.txt
        rpm_check fedora-kde-apps.txt
        for app in $(list flathub.txt); do check "$app" flatpak info "$app"; done
        ;;
    macos)
        for file in macos.Brewfile macos-apps.Brewfile; do
            if brew bundle check --file="$repo/packages/$file" >/dev/null 2>&1; then
                ok "$file"
            else
                bad MISSING "$file: $(brew bundle check --file="$repo/packages/$file" --verbose 2>&1 | grep -c '→') entries, see 'brew bundle check --verbose'"
            fi
        done
        ;;
esac

check "mise" command -v mise
missing=$(mise ls --missing 2>/dev/null)
if [[ -z $missing ]]; then
    ok "mise tools (config.toml)"
else
    while read -r line; do bad MISSING "mise: $line"; done <<< "$missing"
fi

# Windows host apps, through WSL interop. winget's own export is the only listing that isn't truncated.
if [[ $platform == wsl ]] && command -v winget.exe >/dev/null; then
    export_file=$(mktemp --suffix=.json)
    if winget.exe export -o "$(wslpath -w "$export_file")" --accept-source-agreements >/dev/null 2>&1; then
        installed=$(jq -r '.Sources[].Packages[].PackageIdentifier' "$export_file")
        for id in $(jq -r '.Sources[].Packages[].PackageIdentifier' "$repo/packages/windows-apps.winget.json") ZedIndustries.Zed; do
            check "windows: $id" grep -qxF "$id" <<< "$installed"
        done
    else
        bad MISMATCH "windows: winget export failed, apps not checked"
    fi
    rm -f "$export_file"
fi

# --- links: every file in config/ should be a symlink back into the repo -------
section links
packages_to_link=(zsh git ssh mise topgrade)
[[ $platform != wsl ]] && packages_to_link+=(ghostty)
[[ $platform != macos ]] && packages_to_link+=(systemd)
for pkg in "${packages_to_link[@]}"; do
    while read -r file; do
        file=${file#./}
        if [[ $(readlink -f "$HOME/$file") == "$repo/config/$pkg/$file" ]]; then
            ok "~/$file"
        else
            bad MISMATCH "~/$file is not linked to the repo ($([[ $pkg == systemd ]] && echo BACKUP.md || echo "setup/shell.md, step 1")))"
        fi
    done < <(cd "$repo/config/$pkg" && find . -type f)
done

# --- configuration a package or link check can't see ---------------------------
section configuration
check "git user.name"             git config --global --get user.name
check "git user.email"            git config --global --get user.email
signingkey=$(git config --global --get user.signingkey)
check "git signing key file"      test -r "${signingkey/#\~/$HOME}"
check "gh authenticated"          gh auth status
check "starship.toml"             test -s "$HOME/.config/starship.toml"
if command -v podman >/dev/null; then
    check "podman rootless"       test "$(podman info --format '{{.Host.Security.Rootless}}' 2>/dev/null)" = true
fi

case $platform in
    macos)
        check "login shell is zsh"    grep -q /bin/zsh <(dscl . -read "/Users/$USER" UserShell)
        check "Rancher Desktop on PATH"  test "$(command -v kubectl)" = "$HOME/.rd/bin/kubectl"
        ;;
    wsl|kde)
        check "login shell is zsh"    grep -q /usr/bin/zsh <(getent passwd "$USER")
        check "restic settings (BACKUP.md)" test -s "$HOME/.config/restic/env" -a -s "$HOME/.config/restic/paths" -a -s "$HOME/.config/restic/password"
        check "backup timer enabled"     systemctl --user is-enabled backup.timer
        check "last backup didn't fail"  test "$(systemctl --user is-failed backup.service)" != failed
        check "cgroup delegation (kind)" grep -qw cpuset "/sys/fs/cgroup/user.slice/user-$(id -u).slice/user@$(id -u).service/cgroup.controllers"
        ;;
esac

if [[ $platform == wsl ]]; then
    check "Windows interop"       test -e /proc/sys/fs/binfmt_misc/WSLInterop
    check "/ is a shared mount (podman)" test "$(findmnt -no PROPAGATION /)" = shared
    localappdata=$(wslpath "$(cmd.exe /c 'echo %LOCALAPPDATA%' 2>/dev/null | tr -d '\r')" 2>/dev/null)
    check "Nerd Font on Windows"  test -e "$localappdata/Microsoft/Windows/Fonts/JetBrainsMonoNerdFont-Regular.ttf"
    check "Windows Terminal font" grep -qF "JetBrainsMono Nerd Font" "$localappdata/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
fi

if [[ $platform == kde ]]; then
    check "JetBrainsMono Nerd Font" grep -qi "JetBrainsMono Nerd Font" <(fc-list)
    check "root is Btrfs (snapper)" test "$(findmnt -no FSTYPE /)" = btrfs
    check "snapper on dnf transactions" test -s /etc/dnf/libdnf5-plugins/actions.d/snapper.actions
    check "snapper cleanup timer"   systemctl is-enabled snapper-cleanup.timer
    check "terra limited to includepkgs" test "$(dnf repoquery -q --repo=terra --qf '%{name}\n' | grep -cvE '^(terra-release|ghostty|zed|dbeaver-bin)')" = 0
fi

printf '\n%d problem(s)\n' "$problems"
(( problems == 0 ))
