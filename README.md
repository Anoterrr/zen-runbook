[HIGH CONFIDENCE]

Here is your setup guide translated into English, maintaining exact technical commands, paths, and logic while updating code block shell labels where applicable.

---

# zen-dots — setup guide (Fedora WSL2 / Fedora KDE / macOS)

No executable scripts. Follow the section for your specific machine.

## Installation priority: native package manager first, mise strictly as fallback

For any tool: try `dnf` (Fedora) or `brew` (macOS) first. `mise` is used **only** for packages missing from official native package managers — confirmed missing from Fedora official repositories: `starship`, `lazygit`, `yazi`, `topgrade`. `eza` and `lnav` have a less consistent package history — the guide attempts installation via dnf first and falls back to mise if it fails.

On macOS, `brew` covers all of these natively — `mise` is reserved exclusively for language runtimes (`node`/`python`/`rust`/`go`).

Two components remain outside of mise due to technical constraints rather than preference: **login shell** (`fish`, requires an absolute binary path registered in `/etc/shells`, not a shim) and **GUI applications** (`Zed`, `Ghostty`, which require desktop environment integration).

---

## Common to all 3 machines

### mise — runtimes + fallback

```bash
curl https://mise.run | sh
mkdir -p ~/.config/mise
echo '[tools]
node = "lts"
python = "3.13"
rust = "latest"
go = "latest"
uv = "latest"

[settings]
experimental = true
python.uv_venv_auto = "create|source"' > ~/.config/mise/config.toml
~/.local/bin/mise install

```

If `python@3.13` falls back to building from source and fails (similar to `python-build` errors), force precompiled binaries instead: run `mise settings set python.compile false` and execute `mise install` again — or target a specific patch version (e.g., `3.13.2`) if `3.13` fails to find a pre-built binary.

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

# --- runtimes / tools / navigation (each executes only if binary exists) ----
type -q mise     && mise activate fish | source
type -q zoxide   && zoxide init fish | source
type -q starship && starship init fish | source

# --- fzf (Ctrl-T, Ctrl-R, Alt-C) --------------------------------------------
type -q fzf && fzf --fish | source

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
alias ll "eza -l --icons --group-directories-first"
alias cat "bat --paging=never"
alias vim "nvim"' > ~/.config/fish/config.fish

```

### starship (preset)

```bash
starship preset nerd-font-symbols -o ~/.config/starship.toml

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

### LazyVim — terminal editor, designated role: non-GUI editing environments

```bash
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
mkdir -p ~/.config/nvim/lua/plugins
echo 'return {
  { "folke/tokyonight.nvim", opts = { style = "night" } },
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },
}' > ~/.config/nvim/lua/plugins/colorscheme.lua
nvim   # plugins install automatically on first startup

```

`lazygit` handles Git operations (stage/diff/branch); LazyVim handles file editing when a GUI is unavailable; Zed handles primary development tasks.

---

## Fedora WSL2 (official distribution)

### 1. Install

```powershell
wsl --list --online
wsl --install FedoraLinux-44

```

### 2. System packages + build toolchain (equivalent to Arch base-devel)

Fedora lacks a single meta-package — build tools are packaged as a DNF group. Using lowercase group IDs avoids execution failures seen with quoted display names ("No match for argument"):

```bash
sudo dnf upgrade --refresh -y
sudo dnf group install -y development-tools
sudo dnf install -y git curl wget unzip fish fzf man-db less openssh-clients \
  wl-clipboard fontconfig libnotify

```

### 3. CLI tools — dnf first, installed individually to prevent missing packages from breaking the batch

```bash
sudo dnf install -y bat ripgrep fd-find zoxide git-delta neovim eza lnav

mise use -g starship lazygit yazi topgrade

```

### 4. Default shell → fish

```bash
grep -qxF /usr/bin/fish /etc/shells || echo /usr/bin/fish | sudo tee -a /etc/shells
chsh -s /usr/bin/fish

```

`chsh` takes effect starting at the next login. To switch immediately in the current active shell:

```bash
exec fish

```

### 5. Notifications (Windows Toast integration)

```bash
mkdir -p ~/.local/bin
# download wsl-notify-send.exe: https://github.com/stuartleeks/wsl-notify-send/releases
echo 'alias notify-send="wsl-notify-send.exe"' >> ~/.config/fish/config.fish

```

### 6. Zed, Ghostty, Fonts — installed on host Windows side

Ghostty does not support Windows directly — WSL relies on Windows Terminal. Zed: install natively on Windows and connect to the Fedora WSL instance as a remote target (identical to the VS Code Remote-WSL pattern). Fonts must also be installed directly on Windows.

---

## Fedora KDE (bare-metal / VM)

### 1. System packages + build toolchain

```bash
sudo dnf upgrade --refresh -y
sudo dnf group install -y development-tools
sudo dnf install -y git curl wget unzip fish fzf man-db less openssh-clients \
  wl-clipboard fontconfig libnotify

```

### 2. CLI tools — same methodology as WSL above

```bash
sudo dnf install -y bat ripgrep fd-find zoxide git-delta neovim eza lnav

mise use -g starship lazygit yazi topgrade

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

### 4. Fonts

```bash
mkdir -p ~/.local/share/fonts
curl -Lo /tmp/jbmono.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
unzip -oq /tmp/jbmono.zip -d ~/.local/share/fonts && rm -f /tmp/jbmono.zip
fc-cache -f ~/.local/share/fonts

```

### 5. Ghostty and Zed — via Terra repository (neither binary exists in Fedora official repositories)

```bash
sudo dnf install --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra$(rpm -E %fedora)" -y terra-release
sudo dnf install -y ghostty zed

```

### 6. Notifications

Natively supported via `libnotify` installed in Step 1.

---

## macOS

### 1. Homebrew — natively covers CLI tools on macOS; mise handles runtimes only

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

brew install git curl fzf fish openssh eza bat ripgrep fd zoxide git-delta \
  starship lazygit neovim topgrade yazi lnav terminal-notifier
brew install --cask zed ghostty font-jetbrains-mono-nerd-font

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

### 3. Notifications

Handled via `terminal-notifier` installed in Step 1 — the `notify` function defined in `config.fish` automatically detects and uses this binary.

---

## Final verification (all platforms)

```fish
for bin in mise starship nvim lazygit eza bat rg fd delta fish fzf lnav topgrade
    printf '%-10s ' $bin
    type -q $bin; and $bin --version 2>/dev/null | head -n1; or echo MISSING
end

```
