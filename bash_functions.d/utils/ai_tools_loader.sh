#!/usr/bin/env bash
# Simple AI Tools Loader - Direct approach

# Directory where AI tools are located
export AI_TOOLS_DIR="/home/cbwinslow/bash_functions.d/ai_coding_tools"

# Direct aliases for AI tools (using npx)
alias forgecode='npx forgecode@latest'
alias qwen-code='npx @qwen-code/qwen-code@latest'
alias gemini-cli='npx @google/gemini-cli@latest'
alias codex='npx @openai/codex@latest'
alias kilo-code='npx @kilocode/cli@latest'
alias cline='npx cline@latest'

# Installation aliases
alias forgecode-install='source "$AI_TOOLS_DIR/forgecode_latest.sh" && forgecode_install'
alias qwen-code-install='source "$AI_TOOLS_DIR/qwen_code_latest.sh" && qwen_code_install'
alias roo-code-install='source "$AI_TOOLS_DIR/roo_code_latest.sh" && roo_code_install'
alias gemini-cli-install='source "$AI_TOOLS_DIR/gemini_cli_latest.sh" && gemini_cli_install'
alias codex-install='source "$AI_TOOLS_DIR/codex_latest.sh" && codex_install'
alias kilo-code-install='source "$AI_TOOLS_DIR/kilo_code_latest.sh" && kilo_code_install'
alias cline-install='source "$AI_TOOLS_DIR/cline_latest.sh" && cline_install'

# Master installer
alias ai-tools='source "$AI_TOOLS_DIR/ai_tools_install.sh" && ai_tools_install'

echo "[AI Tools] AI coding tools aliases loaded. Use forgecode, qwen-code, codex, kilo-code, cline, or ai-tools"