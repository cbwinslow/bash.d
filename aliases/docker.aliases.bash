#!/bin/bash
# Docker aliases for bash.d
# Common docker shortcuts and utilities

cite about-alias
about-alias 'Docker shortcuts and utilities'

# Basic docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dstop='docker stop'
alias dstart='docker start'
alias drestart='docker restart'
alias dlogs='docker logs'
alias dlogsf='docker logs -f'
alias dexec='docker exec -it'
alias dbuild='docker build'
alias dpull='docker pull'
alias dpush='docker push'

# Docker compose aliases
alias dcu='docker-compose up'
alias dcud='docker-compose up -d'
alias dcd='docker-compose down'
alias dcr='docker-compose restart'
alias dcl='docker-compose logs'
alias dclf='docker-compose logs -f'
alias dcps='docker-compose ps'
alias dcbuild='docker-compose build'

# Docker cleanup aliases
alias dprune='docker system prune -f'
alias dprunea='docker system prune -af'
alias drmall='docker rm $(docker ps -aq)'
alias drmiall='docker rmi $(docker images -q)'
alias dstopall='docker stop $(docker ps -aq)'

# Docker info functions
daliases() {
    echo "Docker Aliases:"
    echo "==============="
    alias | grep "^alias d" | sed 's/^alias /  /'
}
