#!/usr/bin/env bash
# Define convenient aliases for installed/wrapper CLIs.
# This file is sourced automatically by source_all.sh via setup.sh's managed block.

_alias_have() { command -v "$1" >/dev/null 2>&1; }
_alias_defined() { alias "$1" >/dev/null 2>&1; }
_alias_safe() {
  # Usage: _alias_safe name command...
  local name="$1"; shift
  # Don't override existing alias or function/command names
  if _alias_defined "$name" || _alias_have "$name"; then return 0; fi
  alias "$name"="$*"
}

# Forgecode helpers
_alias_safe forgecode-latest forgecode_latest
_alias_safe forgecode-install forgecode_install_latest

# Roo Code helpers
_alias_safe roocode-latest roo_code_latest
_alias_safe roocode-install roo_code_install_latest

# Qwen Code helpers
_alias_safe qwen-code-latest qwen_code_install_latest
_alias_safe qwen-code-update qwen_code_update

# Prefer friendly short aliases if they aren't real commands already
# forgecode
if _alias_have forgecode; then :; else _alias_safe forgecode forgecode_latest; fi

# roocode / roo-code / roo
if _alias_have roocode; then
  _alias_safe roo roocode
elif _alias_have roo-code; then
  _alias_safe roocode roo-code
  _alias_safe roo roo-code
else
  # Fallback to the npx wrapper if none installed yet
  _alias_safe roocode roo_code_latest
  _alias_safe roo roo_code_latest
fi

# qwen-code / qwen / qwencode
if _alias_have qwen-code; then
  _alias_safe qwen qwen-code
elif _alias_have qwen; then
  _alias_safe qwen-code qwen
elif _alias_have qwencode; then
  _alias_safe qwen qwen_code
  _alias_safe qwen-code qwen_code
else
  # Fallback to wrapper
  _alias_safe qwen qwen_code
  _alias_safe qwen-code qwen_code
fi

# Pass-through aliases (only if not already real commands in the shell),
# provide intuitive names for potentially ambiguous tools.
_alias_have codex    || _alias_safe codex    codex
_alias_have cline    || _alias_safe cline    cline
_alias_have kilocode || _alias_safe kilocode kilocode
_alias_have opencode || _alias_safe opencode opencode
_alias_have gemini   || _alias_safe gemini   gemini-cli

# Cleanup helpers
unset -f _alias_have _alias_defined _alias_safe 2>/dev/null || true
