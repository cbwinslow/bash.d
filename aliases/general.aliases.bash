#!/bin/bash
# General utilities aliases for bash.d

cite about-alias
about-alias 'General utility aliases'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# Listing
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -lAh'
alias l='ls -CF'
alias lt='ls -lhtr'

# File operations
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias mkdir='mkdir -pv'

# Grep with color
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Disk usage
alias df='df -h'
alias du='du -h'
alias dus='du -sh'

# Process management
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias ports='netstat -tulanp'

# Network
alias myip='curl -s ifconfig.me'
alias localip='hostname -I | cut -d" " -f1'
alias ping='ping -c 5'

# System
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowdate='date +"%Y-%m-%d"'

# Safety aliases
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# Quick edit
alias bashrc='${EDITOR:-vim} ~/.bashrc'
alias reload='source ~/.bashrc'
