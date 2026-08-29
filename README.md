# zen-dots — guia de setup (Fedora WSL2 / Fedora KDE / macOS)

Sem script executável. Siga a seção da sua máquina.

## Prioridade de instalação: gerenciador nativo primeiro, mise só como fallback

Pra qualquer ferramenta: tente `dnf` (Fedora) ou `brew` (macOS) primeiro. `mise` entra **só** para o que o gerenciador nativo não tem — confirmado ausente dos repositórios oficiais do Fedora: `starship`, `lazygit`, `yazi`, `topgrade`. `eza` e `lnav` têm histórico mais instável — o guia tenta o dnf e cai pro mise se falhar.

No macOS o `brew` já cobre tudo isso nativamente — `mise` fica reservado só para runtimes (`node`/`python`/`rust`/`go`).

Duas coisas continuam fora do mise por motivo técnico, não preferência: **shell de login** (`fish`, precisa de caminho absoluto em `/etc/shells`, não um shim) e **apps GUI** (`Zed`, `Ghostty`, precisam de integração com o desktop).

---

## Comum às 3 máquinas

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

Se `python@3.13` ainda cair pra compilar do zero e falhar (mesmo erro do `python-build`), force binário precompilado em vez de source: `mise settings set python.compile false` e rode `mise install` de novo — ou troque pra uma versão patch específica (ex: `3.13.2`) se `3.13` sozinho não achar um build pronto.

### fish — ~/.config/fish/config.fish

```fish
mkdir -p ~/.config/fish
echo '# --- PATH -------------------------------------------------------------------
fish_add_path -g $HOME/.local/bin $HOME/.local/share/mise/shims
if test -d /opt/homebrew/bin
    eval (/opt/homebrew/bin/brew shellenv)
end

# --- vi keybinds (indicador vi-mode do starship) ----------------------------
set -g fish_key_bindings fish_vi_key_bindings

# --- runtimes / ferramentas / navegação (cada um só roda se existir) -------
type -q mise     && mise activate fish | source
type -q zoxide   && zoxide init fish | source
type -q starship && starship init fish | source

# --- fzf (Ctrl-T, Ctrl-R, Alt-C) --------------------------------------------
type -q fzf && fzf --fish | source

# --- notificação cross-platform: mesmo nome de comando nas 3 máquinas ------
function notify
    if type -q terminal-notifier
        terminal-notifier -title (test -n "$argv[1]"; and echo $argv[1]; or echo "Shell") -message $argv[2]
    else if type -q notify-send
        notify-send $argv[1] $argv[2]
    end
end

# --- aliases: só substitutos diretos e seguros ------------------------------
alias ls "eza --icons --group-directories-first"
alias ll "eza -l --icons --group-directories-first"
alias cat "bat --paging=never"
alias vim "nvim"' > ~/.config/fish/config.fish
```

### starship (preset)

```bash
starship preset nerd-font-symbols -o ~/.config/starship.toml
```

### lnav — highlight de log por regex

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

### topgrade — atualização de tudo (dnf/brew + mise + flatpak)

```bash
mkdir -p ~/.config
echo '[misc]
assume_yes = false
no_retry = false

[git]
max_concurrency = 5' > ~/.config/topgrade.toml
```

Rode `topgrade` para o que ele detecta nativamente (dnf/brew, flatpak, git repos). Ele ainda não tem confirmação de suporte a `mise` — rode `mise upgrade` separadamente até validar isso no seu ambiente (`topgrade --dry-run` mostra os passos detectados).

### LazyVim — editor de terminal, papel específico: edição sem GUI disponível

```bash
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
mkdir -p ~/.config/nvim/lua/plugins
echo 'return {
  { "folke/tokyonight.nvim", opts = { style = "night" } },
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },
}' > ~/.config/nvim/lua/plugins/colorscheme.lua
nvim   # plugins instalam sozinhos no primeiro start
```

`lazygit` cobre git (stage/diff/branch); LazyVim cobre edição de arquivo quando não há GUI disponível; Zed cobre o resto.

---

## Fedora WSL2 (distro oficial)

### 1. Instalar

```powershell
wsl --list --online
wsl --install FedoraLinux-44
```

### 2. Pacotes de sistema + toolchain de build (equivalente ao base-devel do Arch)

O Fedora não tem um meta-pacote único — é um grupo do dnf. Dois relatos conflitantes sobre a sintaxe: nome de exibição entre aspas funciona em alguns testes recentes, mas falha em outros com "No match for argument" — o ID em minúsculo é a forma mais confiável, use ele:

```bash
sudo dnf upgrade --refresh -y
sudo dnf group install -y development-tools
sudo dnf install -y git curl wget unzip fish fzf man-db less openssh-clients \
  wl-clipboard fontconfig libnotify
```

### 3. CLI tools — dnf primeiro, um por um (evita que um pacote ausente derrube o lote inteiro)

```bash
sudo dnf install -y bat ripgrep fd-find zoxide git-delta neovim eza lnav

mise use -g starship lazygit yazi topgrade
```

### 4. Shell padrão → fish

```bash
grep -qxF /usr/bin/fish /etc/shells || echo /usr/bin/fish | sudo tee -a /etc/shells
chsh -s /usr/bin/fish
```

`chsh` só vale a partir do próximo login. Pra trocar na sessão atual agora, sem fechar o terminal:

```bash
exec fish
```

### 5. Notificação (toast do Windows)

```bash
mkdir -p ~/.local/bin
# baixe wsl-notify-send.exe: https://github.com/stuartleeks/wsl-notify-send/releases
echo 'alias notify-send="wsl-notify-send.exe"' >> ~/.config/fish/config.fish
```

### 6. Zed, Ghostty, fonte — ficam no lado Windows

Ghostty não roda em Windows — o WSL segue usando Windows Terminal. Zed: instale no Windows e conecte na distro Fedora como alvo remoto (mesmo padrão do VS Code Remote-WSL). Fonte também é instalada no Windows.

---

## Fedora KDE (bare-metal / VM)

### 1. Pacotes de sistema + toolchain de build

```bash
sudo dnf upgrade --refresh -y
sudo dnf group install -y development-tools
sudo dnf install -y git curl wget unzip fish fzf man-db less openssh-clients \
  wl-clipboard fontconfig libnotify
```

### 2. CLI tools — mesmo padrão do WSL acima

```bash
sudo dnf install -y bat ripgrep fd-find zoxide git-delta neovim eza lnav

mise use -g starship lazygit yazi topgrade
```

### 3. Shell padrão → fish

```bash
grep -qxF /usr/bin/fish /etc/shells || echo /usr/bin/fish | sudo tee -a /etc/shells
chsh -s /usr/bin/fish
```

`chsh` só vale a partir do próximo login. Pra trocar agora, na sessão atual:

```bash
exec fish
```

### 4. Fonte

```bash
mkdir -p ~/.local/share/fonts
curl -Lo /tmp/jbmono.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
unzip -oq /tmp/jbmono.zip -d ~/.local/share/fonts && rm -f /tmp/jbmono.zip
fc-cache -f ~/.local/share/fonts
```

### 5. Ghostty e Zed — via terra (nenhum dos dois está nos repos oficiais do Fedora)

```bash
sudo dnf install --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra$(rpm -E %fedora)" -y terra-release
sudo dnf install -y ghostty zed
```

### 6. Notificação

Já nativa via `libnotify`, instalado no passo 1.

---

## macOS

### 1. Homebrew — cobre tudo nativamente aqui, mise fica só com os runtimes

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

brew install git curl fzf fish openssh eza bat ripgrep fd zoxide git-delta \
  starship lazygit neovim topgrade yazi lnav terminal-notifier
brew install --cask zed ghostty font-jetbrains-mono-nerd-font
```

### 2. Shell padrão → fish

```bash
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish
```

`chsh` só vale a partir do próximo login. Pra trocar agora, na sessão atual:

```bash
exec fish
```

### 3. Notificação

Já resolvida pelo `terminal-notifier` instalado acima — a função `notify` do `config.fish` detecta e usa automaticamente.

---

## Verificação final (qualquer máquina)

```fish
for bin in mise starship nvim lazygit eza bat rg fd delta fish fzf lnav topgrade
    printf '%-10s ' $bin
    type -q $bin; and $bin --version 2>/dev/null | head -n1; or echo MISSING
end
```
