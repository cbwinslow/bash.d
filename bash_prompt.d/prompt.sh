# Lightweight prompt when Oh My Bash is unavailable
if [[ -z "$OSH_THEME" ]]; then
  if ! command -v __git_ps1 >/dev/null 2>&1; then
    __git_ps1() { return 0; }
  fi
  PS1='[\u@\h \W$(__git_ps1 " (%s)")]\\$ '
fi
