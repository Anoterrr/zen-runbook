# zen-dots — setup guide (Fedora WSL2 / Fedora KDE / macOS)

No executable scripts. Install `mise` first, then follow the section for your platform (Fedora WSL2 and Fedora KDE share one setup section in the middle), in order — later steps assume earlier ones are done.

## Purpose

A personal environment baseline — go from a fresh Fedora/macOS install to a productive shell in one read-through, with every choice traceable to a reason instead of copied defaults.

## Pillars

- **Simplicity** — no scripts, no hidden logic; every command is readable before you run it.
- **Organic** — native package manager first; nothing vendored or frozen without saying so.
- **Reproducibility** — pinned wherever the ecosystem around a tool lags (Python, Java, LazyVim, fonts), left floating wherever it doesn't (Node, Rust, Go).
- **Minimalism** — every tool has a stated reason to be here, not just "why not."
- **Performance** — startup cost is a factor in every tool choice, not an afterthought; measured, not assumed — see the sanity check at the end of the shell configuration section.
- **Close to vanilla** — presets over deep customization; LazyVim is the one deliberate exception, scoped to a fallback role.
- **Flexibility** — `~/.config/fish/local.fish` is the escape hatch for machine-specific tweaks that survive reruns.
- **Scalability** — shared steps live in one place; platform sections hold only what's actually different.
- **Convenience with no trade-off** — a free win (reusing a tool already installed, killing default noise) is always taken.
- **Security** — every download comes from the vendor's own domain over HTTPS; a version pin doubles as an integrity anchor (a git commit hash is content-addressed); any unavoidable trust bootstrap (e.g. installing a repo's own signing key unsigned, the one time before it can verify itself) is named explicitly instead of glossed over.

## Trust boundaries

Two points in this guide accept risk deliberately instead of avoiding it — named here so it's a decision, not an oversight:

- **`curl | sh` installers** (`mise`, Homebrew) — each project's own official install command, with no published checksum to verify against. Accepted because both are widely-audited, HTTPS-only, first-party domains — this is the standard bootstrap pattern across the ecosystem, not something unique to this guide.
- **Terra repo bootstrap** (`--nogpgcheck` on the initial `terra-release` install) — Terra's own documented command. The first package has to be installed unsigned because it's what installs the GPG key that verifies every package from that repo afterward.

## Tool index

| Tool | Role |
|---|---|
| `mise` | Runtime + fallback package manager (only for what `dnf`/`brew` lack) |
| `fish` | Login shell |
| `starship` | Prompt |
| `fzf` | Fuzzy finder (Ctrl-T / Ctrl-R / Alt-C) |
| `zoxide` | Frecency-based `cd` |
| `eza` | `ls` replacement |
| `bat` | `cat`/pager replacement with syntax highlighting |
| `ripgrep` (`rg`) | Fast recursive grep |
| `fd` | Fast, friendly `find` |
| `git-delta` | Syntax-highlighted git diff/merge pager |
| `neovim` + LazyVim | Terminal editor — non-GUI fallback only |
| `lazygit` | Terminal UI for git |
| `topgrade` | One command to upgrade everything (dnf/brew/mise/flatpak) |
| `lnav` | Regex-highlighted log viewer (reading DAG/pipeline run logs) |
| `jq` | JSON processor — pairs with API clients and pipeline output |
| `btop` | Terminal resource monitor |
| `kubectl` | Kubernetes CLI |
| `k9s` | Terminal UI for Kubernetes clusters |
| `wl-clipboard` / `terminal-notifier` / `wsl-notify-send` | Clipboard + desktop notifications, per platform |
| `uv` | Python package/venv manager, per-project |
| `Zed` | Primary GUI editor |
| `Ghostty` | Primary GUI terminal (not on WSL — Windows Terminal instead) |

## Installation priority: native package manager first, mise strictly as fallback

For any tool: try `dnf` (Fedora) or `brew` (macOS) first. `mise` is used **only** for packages missing from official native package managers — confirmed missing from Fedora official repositories: `starship`, `lazygit`, `topgrade`. `eza` and `lnav` have a less consistent package history — the guide installs them via `dnf` first and falls back to `mise` if that fails.

On macOS, `brew` covers all of these natively — `mise` is reserved exclusively for language runtimes (`node`/`python`/`rust`/`go`/`java`).

Two components remain outside of mise due to technical constraints rather than preference: **login shell** (`fish`, requires an absolute binary path registered in `/etc/shells`, not a shim) and **GUI applications** (`Zed`, `Ghostty`, which require desktop environment integration).

---

## mise — install first

Every section below uses `mise` as a fallback package manager, so install it before anything else:

```bash
curl https://mise.run | sh
mkdir -p ~/.config/mise
echo '[tools]
node = "lts"
python = "3.13.15"
rust = "latest"
go = "latest"
java = "temurin-17"
uv = "latest"

[settings]
experimental = true
python.uv_venv_auto = "create|source"' > ~/.config/mise/config.toml
~/.local/bin/mise install

```

`python` and `java` are pinned deliberately — their ecosystems (PySpark, JVM build tooling) lag behind new releases, so this is a known-good baseline you bump by hand once you've verified your usual stacks support the new version. `node`, `rust`, and `go` float (`lts`/`latest`) because their ecosystems don't have that lag, and per-project pins (e.g. via `uv` for Python) override this global default anyway.

If the exact patch build isn't available for your platform yet (precompiled binaries can lag a release by a few days), drop to the previous patch (check `mise ls-remote python | grep '^3.13'` for what's available) or force building from source with `mise settings set python.compile false` and run `mise install` again.

Sanity check:

```bash
~/.local/bin/mise --version || echo "MISSING mise"
~/.local/bin/mise ls || echo "MISMATCH one or more [tools] failed to install — see output above"

```

---

## Fedora WSL2 — prerequisite

```powershell
wsl --list --online
wsl --install FedoraLinux-44

```

Then continue with the shared Fedora setup below. Come back to "Fedora WSL2 — after the shared setup" once that's done.

---

## Fedora — shared setup (WSL2 & KDE)

Identical either way — run this once whether you just installed Fedora via WSL above or you're on a bare-metal/VM Fedora KDE install.

### 1. System packages + build toolchain (equivalent to Arch base-devel)

Fedora lacks a single meta-package — build tools are packaged as a DNF group. Use the lowercase group ID; quoted display names (e.g. `"Development Tools"`) fail with `No match for argument`:

```bash
sudo dnf upgrade --refresh -y
sudo dnf group install -y development-tools
sudo dnf install -y git curl wget unzip fish fzf man-db less openssh-clients \
  wl-clipboard fontconfig libnotify

```

Sanity check:

```bash
for bin in git curl wget unzip fish fzf man ssh wl-copy fc-cache notify-send; do
    command -v $bin >/dev/null && echo "OK      $bin" || echo "MISSING $bin"
done

```

### 2. CLI tools — dnf, with a mise fallback for the two with inconsistent Fedora package history

```bash
sudo dnf install -y bat ripgrep fd-find zoxide git-delta neovim jq btop kubernetes-client k9s

sudo dnf install -y eza || mise use -g eza
sudo dnf install -y lnav || mise use -g lnav

mise use -g starship lazygit topgrade

```

`jq`/`btop` are general-purpose (JSON on the command line, a terminal resource monitor); `kubernetes-client` (kubectl) and `k9s` are here because you run workloads on Kubernetes — both are official Fedora packages, no mise fallback needed.

Sanity check:

```bash
for bin in bat rg fd zoxide delta nvim eza lnav jq btop kubectl k9s; do
    command -v $bin >/dev/null && echo "OK      $bin" || echo "MISSING $bin"
done
for bin in starship lazygit topgrade; do
    test -x ~/.local/share/mise/shims/$bin && echo "OK      $bin" || echo "MISSING $bin"
done

```

### 3. Default shell → fish

```bash
grep -qxF /usr/bin/fish /etc/shells || echo /usr/bin/fish | sudo tee -a /etc/shells
chsh -s /usr/bin/fish

```

`chsh` takes effect starting at the next login. To switch immediately in the current active shell:

```bash
exec fish

```

fish's config file is written in the "Shell, prompt, and tool configuration" section below — until then it starts with no aliases or integrations. Run `exec fish` again once that section is done.

Sanity check:

```bash
getent passwd "$USER" | grep -q /usr/bin/fish \
  && echo "OK      login shell is fish" \
  || echo "PENDING chsh only applies at next login — run 'exec fish' now, or log out and back in"

```

---

## Fedora WSL2 — after the shared setup

### Notifications (Windows Toast integration)

The shared fish config below already aliases `notify-send` to `wsl-notify-send.exe` whenever `$WSL_DISTRO_NAME` is set, so this step is just fetching the binary:

```bash
mkdir -p ~/.local/bin
# download wsl-notify-send.exe: https://github.com/stuartleeks/wsl-notify-send/releases

```

Sanity check:

```bash
command -v wsl-notify-send.exe >/dev/null \
  && echo "OK      wsl-notify-send.exe on PATH" \
  || echo "MISSING place wsl-notify-send.exe in ~/.local/bin"

```

### Zed, Ghostty, Fonts — installed on host Windows side

Ghostty does not support Windows directly — WSL relies on Windows Terminal. Zed: install natively on Windows and connect to the Fedora WSL instance as a remote target (identical to the VS Code Remote-WSL pattern). Fonts must also be installed directly on Windows.

---

## Fedora KDE — after the shared setup

### Fonts

```bash
mkdir -p ~/.local/share/fonts
curl -Lo /tmp/jbmono.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.zip"
unzip -oq /tmp/jbmono.zip -d ~/.local/share/fonts && rm -f /tmp/jbmono.zip
fc-cache -f ~/.local/share/fonts

```

Pinned to `v3.5.1` instead of `/latest/download/` — bump the tag by hand when you want a newer release (check https://github.com/ryanoasis/nerd-fonts/releases).

Sanity check:

```bash
fc-list | grep -qi "JetBrainsMono Nerd Font" \
  && echo "OK      JetBrainsMono Nerd Font installed" \
  || echo "MISSING JetBrainsMono Nerd Font not found by fontconfig"

```

### Ghostty and Zed — via Terra repository (neither binary exists in Fedora official repositories)

```bash
sudo dnf install --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra$(rpm -E %fedora)" -y terra-release
sudo dnf install -y ghostty zed

```

Sanity check:

```bash
for bin in ghostty zed; do
    command -v $bin >/dev/null && echo "OK      $bin" || echo "MISSING $bin"
done

```

### Notifications

Natively supported via `libnotify` installed in the shared setup above.

---

## macOS

### 1. Homebrew — natively covers CLI tools on macOS; mise handles runtimes only

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

brew install git curl fzf fish openssh eza bat ripgrep fd zoxide git-delta \
  starship lazygit neovim topgrade lnav terminal-notifier jq btop kubectl k9s
brew install --cask zed ghostty font-jetbrains-mono-nerd-font

```

Sanity check:

```bash
for bin in git curl fzf fish ssh eza bat rg fd zoxide delta starship lazygit nvim topgrade lnav terminal-notifier jq btop kubectl k9s; do
    command -v $bin >/dev/null && echo "OK      $bin" || echo "MISSING $bin"
done
for app in Zed Ghostty; do
    test -d "/Applications/$app.app" && echo "OK      $app.app" || echo "MISSING $app.app"
done

```

### 2. Default shell → fish

```bash
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish

```

`chsh` takes effect starting at the next login. To switch immediately in the current active shell:

```bash
exec fish

```

Sanity check:

```bash
dscl . -read "/Users/$USER" UserShell 2>/dev/null | grep -q /opt/homebrew/bin/fish \
  && echo "OK      login shell is fish" \
  || echo "PENDING chsh only applies at next login — run 'exec fish' now, or log out and back in"

```

### 3. Notifications

Handled via `terminal-notifier` installed in Step 1 — the `notify` function defined in `config.fish` automatically detects and uses this binary.

---

## Git identity, SSH key, and commit signing

Basic setup for anyone new to this — needs `git` and `openssh` from your platform section above.

### Git — identity and sane defaults

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --global pull.rebase true

```

Sets who you are on every commit, plus two defaults worth having everywhere: new repos start on `main`, and `pull` rebases instead of creating merge commits.

Sanity check:

```bash
git config --global user.name >/dev/null && git config --global user.email >/dev/null \
  && echo "OK      git identity set" \
  || echo "MISSING run 'git config --global user.name/user.email'"

```

### SSH key — skip this block if `~/.ssh/id_ed25519.pub` already exists

```bash
ssh-keygen -t ed25519 -C "you@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

```

Copy `~/.ssh/id_ed25519.pub` and add it on GitHub/GitLab under Settings → SSH keys, as an **Authentication key**. This is what lets `git clone git@github.com:...` and `git push` work without typing a password.

Sanity check:

```bash
ssh -T git@github.com

```

"Hi \<username\>! You've successfully authenticated" means it worked — GitHub's SSH endpoint always exits 1 and refuses a shell, that part is normal.

### SSH config — two hardening lines

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo 'Host *
    IdentitiesOnly yes
    HashKnownHosts yes' >> ~/.ssh/config
chmod 600 ~/.ssh/config

```

`IdentitiesOnly` stops ssh from offering every key in `~/.ssh/` to every host it connects to; `HashKnownHosts` keeps `~/.ssh/known_hosts` from listing which servers you've connected to in plain text.

Sanity check:

```bash
grep -q IdentitiesOnly ~/.ssh/config 2>/dev/null && grep -q HashKnownHosts ~/.ssh/config 2>/dev/null \
  && echo "OK      ~/.ssh/config hardened" \
  || echo "MISSING run the block above"

```

### Commit signing — reuses the SSH key above, no new tool

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true

```

Add the same public key to GitHub a **second time**, this time as a **Signing key** (a separate role from the Authentication key above, same Settings → SSH keys page) — without that, commits sign locally but still show up unverified.

Sanity check:

```bash
test "$(git config --global --get commit.gpgsign)" = true \
  && echo "OK      commits sign automatically" \
  || echo "MISMATCH commit.gpgsign is not true"

```

---

## Shell, prompt, and tool configuration

Run this after completing your platform section above — it assumes `fish`, `starship`, `git-delta`, `lnav`, `topgrade`, `neovim`, and `git` are already installed.

### fish — ~/.config/fish/config.fish

```fish
mkdir -p ~/.config/fish
echo '# --- PATH -------------------------------------------------------------------
fish_add_path -g $HOME/.local/bin $HOME/.local/share/mise/shims
if test -d /opt/homebrew/bin
    eval (/opt/homebrew/bin/brew shellenv)
end

# --- vi keybinds (starship vi-mode indicator) -------------------------------
set -g fish_key_bindings fish_vi_key_bindings

# --- quiet greeting -----------------------------------------------------------
set -g fish_greeting ""

# --- man pages through bat: already installed, no new dependency -----------
set -gx MANPAGER "sh -c \"col -bx | bat -l man -p\""
set -gx PAGER "bat --plain"

# --- runtimes / tools / navigation (each executes only if binary exists) ----
type -q mise     && mise activate fish | source
type -q zoxide   && zoxide init fish | source
type -q starship && starship init fish | source

# --- fzf (Ctrl-T, Ctrl-R, Alt-C) --------------------------------------------
type -q fzf && fzf --fish | source

# --- WSL: notify-send has no native implementation, wsl-notify-send.exe fills the gap ---
if set -q WSL_DISTRO_NAME
    alias notify-send "wsl-notify-send.exe"
end

# --- cross-platform notifications: unified command name across all 3 machines ---
function notify
    if type -q terminal-notifier
        terminal-notifier -title (test -n "$argv[1]"; and echo $argv[1]; or echo "Shell") -message $argv[2]
    else if type -q notify-send
        notify-send $argv[1] $argv[2]
    end
end

# --- aliases: direct and safe drop-in replacements only ----------------------
alias ls "eza --icons --group-directories-first"
alias ll "eza -l --icons --group-directories-first --git"
alias cat "bat --paging=never"
alias vim "nvim"

# --- local, machine-specific overrides: never touched or overwritten by this guide ---
if test -f ~/.config/fish/local.fish
    source ~/.config/fish/local.fish
end' > ~/.config/fish/config.fish

```

Re-running this block overwrites `config.fish` wholesale — put any personal or machine-specific tweaks in `~/.config/fish/local.fish` instead, which this loads but never creates or touches.

Sanity check:

```bash
test -s ~/.config/fish/config.fish && echo "OK      config.fish written" || echo "MISSING config.fish is empty or absent"
fish -n ~/.config/fish/config.fish && echo "OK      config.fish is syntactically valid" || echo "MISMATCH fish -n reported a syntax error above"

```

### starship (preset)

```bash
starship preset nerd-font-symbols -o ~/.config/starship.toml

```

Sanity check:

```bash
test -s ~/.config/starship.toml && echo "OK      starship.toml written" || echo "MISSING starship.toml is empty or absent"

```

### Ghostty — point it at the Nerd Font (Fedora KDE & macOS only — skip on WSL, Ghostty doesn't run there)

The font is installed above so starship's icons render, but nothing tells Ghostty to use it yet:

```bash
mkdir -p ~/.config/ghostty
echo 'font-family = "JetBrainsMono Nerd Font"' >> ~/.config/ghostty/config

```

Sanity check:

```bash
grep -q "JetBrainsMono Nerd Font" ~/.config/ghostty/config 2>/dev/null \
  && echo "OK      ghostty font-family set" \
  || echo "MISSING run this step (or ignore if you're on WSL)"

```

### git — delta as the diff/merge pager

`git-delta` is installed above as a CLI tool, but git won't use it until told to:

```bash
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"

```

Sanity check:

```bash
test "$(git config --global --get core.pager)" = delta \
  && echo "OK      git core.pager is delta" \
  || echo "MISMATCH git core.pager is not delta"

```

### lnav — regex log highlighting

```bash
mkdir -p ~/.lnav/formats/installed
echo '{
  "custom-highlights": {
    "highlights": {
      "error": { "pattern": "(?i)error|fail(ed|ure)?", "color": "Red" },
      "warn":  { "pattern": "(?i)warn(ing)?",           "color": "Yellow" },
      "ok":    { "pattern": "(?i)success|done|✓",        "color": "Green" }
    }
  }
}' > ~/.lnav/formats/installed/custom-highlights.json

```

Sanity check:

```bash
test -s ~/.lnav/formats/installed/custom-highlights.json \
  && echo "OK      custom-highlights.json written" \
  || echo "MISSING custom-highlights.json is empty or absent"

```

### topgrade — system-wide upgrades (dnf/brew + mise + flatpak)

```bash
mkdir -p ~/.config
echo '[misc]
assume_yes = false
no_retry = false

[git]
max_concurrency = 5' > ~/.config/topgrade.toml

```

Run `topgrade` for components it detects natively (dnf/brew, flatpak, git repositories). It does not officially confirm full native support for `mise` — run `mise upgrade` independently until verified in your local setup (`topgrade --dry-run` displays all detected routines).

Sanity check:

```bash
test -s ~/.config/topgrade.toml && echo "OK      topgrade.toml written" || echo "MISSING topgrade.toml is empty or absent"

```

### LazyVim — terminal editor, designated role: non-GUI editing environments

```bash
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
git clone https://github.com/LazyVim/starter ~/.config/nvim
git -C ~/.config/nvim checkout 803bc181d7c0d6d5eeba9274d9be49b287294d99
rm -rf ~/.config/nvim/.git
mkdir -p ~/.config/nvim/lua/plugins
echo 'return {
  { "folke/tokyonight.nvim", opts = { style = "night" } },
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },
}' > ~/.config/nvim/lua/plugins/colorscheme.lua
nvim   # plugins install automatically on first startup

```

Pinned to a specific commit instead of tracking `HEAD` — the `.git` removal a few lines up would otherwise silently freeze you at whatever commit existed on setup day, with no record of which one. Bump it deliberately by checking https://github.com/LazyVim/starter for a newer commit and updating the SHA above.

`lazygit` handles Git operations (stage/diff/branch); LazyVim handles file editing when a GUI is unavailable; Zed handles primary development tasks.

Sanity check — run once `nvim` has finished installing plugins and you've quit it:

```bash
test -f ~/.config/nvim/lua/plugins/colorscheme.lua && echo "OK      colorscheme.lua in place" || echo "MISSING colorscheme.lua"
test -d ~/.local/share/nvim/lazy/LazyVim && echo "OK      LazyVim plugin installed" || echo "MISSING LazyVim plugin — reopen nvim to retry"

```

### Performance — measure shell startup cost

Every integration above (`mise activate`, `zoxide init`, `starship init`, `fzf --fish`) runs on every new shell. None of it is free — this is how to see what it's actually costing you, instead of assuming:

```bash
time fish -i -c exit

```

`real` is the number that matters — it's what you feel every time a new terminal opens. No hard budget is set here yet; run it after finishing setup and again after adding anything to `local.fish`, and treat a sudden jump as a signal to find out which integration caused it (comment one out at a time in `config.fish` and re-run to isolate it).

---

## Final verification (all platforms)

```fish
for bin in mise starship nvim lazygit eza bat rg fd delta fish fzf lnav topgrade zoxide jq btop kubectl k9s
    printf '%-10s ' $bin
    type -q $bin; and $bin --version 2>/dev/null | head -n1; or echo MISSING
end

```
