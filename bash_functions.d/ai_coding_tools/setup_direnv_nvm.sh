#!/usr/bin/env bash
# Direnv + NVM Setup for AI Tools
# Simple, clean management for your AI coding tools

echo "🚀 Setting up Direnv + NVM for AI Tools..."

# Check direnv is installed
if ! command -v direnv >/dev/null 2>&1; then
  echo "❌ Direnv not found. Installing..."
  sudo apt install direnv
fi

# Hook direnv into bash (if not already done)
if ! grep -q "direnv hook bash" ~/.bashrc; then
  echo "📝 Adding direnv hook to ~/.bashrc..."
  echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
fi

# Setup NVM if not present
if [[ ! -f "$HOME/.nvm/nvm.sh" ]]; then
  echo "📦 Installing NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
fi

# Allow the .envrc file
cd /home/cbwinslow/bash_functions.d/ai_coding_tools
direnv allow

echo "✅ Setup complete!"
echo ""
echo "📋 How to use:"
echo "1. Restart your terminal or run: source ~/.bashrc"
echo "2. cd to any directory with AI tools"
echo "3. Environment loads automatically!"
echo ""
echo "🎯 Quick test:"
echo "cd /home/cbwinslow/bash_functions.d/ai_coding_tools"
echo "forgecode --version"
echo ""
echo "🔧 Management:"
echo "- AI tools: cd to directory, they're available"
echo "- Node versions: nvm use 20, nvm use 18, etc."
echo "- Clean: direnv deny .envrc (to disable)"