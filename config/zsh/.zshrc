# PATH: mise's own binary lives in ~/.local/bin
typeset -U path
path=($HOME/.local/bin $path)

# macOS only: Homebrew, Rancher Desktop's docker/kubectl, and the Linux name for notify-send
if [[ $OSTYPE == darwin* ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    path=($HOME/.rd/bin $path)
    notify-send() { terminal-notifier -title "$1" -message "$2" }
fi

# history: zsh keeps none on disk until told where
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space

# completion: full check once a day, cached dump otherwise
autoload -Uz compinit
zdump=(~/.zcompdump(N.mh-24))
if (( $#zdump )); then compinit -C; else compinit && touch ~/.zcompdump; fi
unset zdump

# vi mode
bindkey -v
bindkey -M viins '^?' backward-delete-char   # backspace past where insert mode started

# man pages with syntax highlighting
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# tools
eval "$(mise activate zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
source <(fzf --zsh)

alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first --git'
alias cat='bat --paging=never'
alias vim='nvim'

# machine-specific overrides, never written by this guide
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# plugins last: syntax-highlighting has to load after every widget above
source ${HOMEBREW_PREFIX:-/usr}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source ${HOMEBREW_PREFIX:-/usr}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
