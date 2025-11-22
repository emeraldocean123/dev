#!/bin/bash
# --- Git Bash Configuration (Windows) ---
# Prefer user scripts
export PATH="$HOME/bin:$PATH"

# History settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups  # Ignore duplicates and commands starting with space
export HISTTIMEFORMAT='%F %T  '  # Add timestamps
shopt -s histappend  # Append to history file, don't overwrite

# Color support
export CLICOLOR=1
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Oh My Posh (Windows)
if [[ $- == *i* ]]; then
  if [ -n "$LOCALAPPDATA" ] && [ -d "$LOCALAPPDATA/Programs/oh-my-posh/bin" ]; then
    PATH="$LOCALAPPDATA/Programs/oh-my-posh/bin:$PATH"
  fi
  if command -v oh-my-posh.exe >/dev/null 2>&1; then
    eval "$(oh-my-posh.exe init bash)"
  fi
fi

# Fastfetch (Windows) if available
if command -v fastfetch.exe >/dev/null 2>&1; then
  fastfetch.exe
fi

# Git helpers (matches PowerShell aliases)
alias gs='git status'
alias ga='git add'
alias gcom='git commit'
alias gp='git push'
alias gl='git --no-pager log --oneline -n 10'
alias gd='git --no-pager diff'

# Wake-on-LAN functions
if [ -f "$HOME/Documents/dev/wake-on-lan/wake-servers.sh" ]; then
    wake() { "$HOME/Documents/dev/wake-on-lan/wake-servers.sh" all; }
    wake-all() { "$HOME/Documents/dev/wake-on-lan/wake-servers.sh" all; }
    wake-1250p() { "$HOME/Documents/dev/wake-on-lan/wake-servers.sh" 1250p; }
    wake-n6005() { "$HOME/Documents/dev/wake-on-lan/wake-servers.sh" n6005; }
    wake-synology() { "$HOME/Documents/dev/wake-on-lan/wake-servers.sh" synology; }
    wake-proxmox() { "$HOME/Documents/dev/wake-on-lan/wake-servers.sh" proxmox; }
fi

# Directory navigation (matches PowerShell aliases)
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Directory listing (matches PowerShell aliases)
alias ll='ls -lah'
alias la='ls -lah'
alias l='ls -lh'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Useful functions
# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1" || return
}

# Extract various archive formats
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.tar.xz)    tar xJf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick file search
alias ff='find . -type f -name'

# Disk usage helpers
alias du1='du -h --max-depth=1'
alias ducks='du -cks * | sort -rn | head'