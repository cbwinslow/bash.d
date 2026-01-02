# Auto-Tasks Plugin Init
export OPENROUTER_API_KEY="$(age -d -i ~/.bash_secrets.d/age_key.txt ~/.bash_secrets.d/openrouter/token.age 2>/dev/null || echo '')"
alias auto-tasks='python3 ~/bash_functions.d/plugins/auto-tasks/bin/auto_tasks.py'
