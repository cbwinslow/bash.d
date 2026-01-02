#!/usr/bin/env bash
# AI Tools Functions - Function-based approach

# Directory where AI tools are located
export AI_TOOLS_DIR="/home/cbwinslow/bash_functions.d/ai_coding_tools"

# Direct functions for AI tools (using npx)
forgecode() {
  npx forgecode@latest "$@"
}

qwen-code() {
  npx @qwen-code/qwen-code@latest "$@"
}

gemini-cli() {
  npx @google/gemini-cli@latest "$@"
}

codex() {
  npx @openai/codex@latest "$@"
}

kilo-code() {
  npx @kilocode/cli@latest "$@"
}

cline() {
  npx cline@latest "$@"
}

# Installation functions
forgecode-install() {
  source "$AI_TOOLS_DIR/forgecode_latest.sh"
  forgecode_install "$@"
}

qwen-code-install() {
  source "$AI_TOOLS_DIR/qwen_code_latest.sh"
  qwen_code_install "$@"
}

roo-code-install() {
  source "$AI_TOOLS_DIR/roo_code_latest.sh"
  roo_code_install "$@"
}

gemini-cli-install() {
  source "$AI_TOOLS_DIR/gemini_cli_latest.sh"
  gemini_cli_install "$@"
}

codex-install() {
  source "$AI_TOOLS_DIR/codex_latest.sh"
  codex_install "$@"
}

kilo-code-install() {
  source "$AI_TOOLS_DIR/kilo_code_latest.sh"
  kilo_code_install "$@"
}

cline-install() {
  source "$AI_TOOLS_DIR/cline_latest.sh"
  cline_install "$@"
}

# Master installer
ai-tools() {
  source "$AI_TOOLS_DIR/ai_tools_install.sh"
  ai_tools_install "$@"
}

echo "[AI Tools] AI coding tools functions loaded. Use forgecode, qwen-code, codex, kilo-code, cline, or ai-tools"