# Vector DB Tools Plugin Init
export OPENROUTER_API_KEY="$(age -d -i ~/.bash_secrets.d/age_key.txt ~/.bash_secrets.d/openrouter/token.age 2>/dev/null || echo '')"
alias vec-add='python3 ~/bash_functions.d/plugins/vector-db/bin/vec_add.py'
alias vec-query='python3 ~/bash_functions.d/plugins/vector-db/bin/vec_query.py'
