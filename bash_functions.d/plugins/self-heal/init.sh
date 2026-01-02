# Self-Heal Plugin Init
export OPENROUTER_API_KEY="$(age -d -i ~/.bash_secrets.d/age_key.txt ~/.bash_secrets.d/openrouter/token.age 2>/dev/null || echo '')"
alias self-heal='python3 ~/bash_functions.d/plugins/self-heal/bin/self_heal.py'
