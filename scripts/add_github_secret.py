#!/usr/bin/env python3
"""
Add OpenRouter API Key to GitHub Repository using GitHub CLI
"""

import os
import subprocess
import json


def add_secret_with_gh_cli(secret_name, secret_value):
    """Add secret using GitHub CLI."""
    try:
        # Use gh CLI to add secret
        cmd = [
            "gh",
            "secret",
            "set",
            secret_name,
            "--repo",
            "cbwinslow/bash.d",
            "--body",
            secret_value,
        ]

        result = subprocess.run(cmd, capture_output=True, text=True, input=secret_value)

        if result.returncode == 0:
            print(f"✅ Successfully added {secret_name} to repository secrets!")
            return True
        else:
            print(f"❌ Error adding secret: {result.stderr}")
            return False

    except Exception as e:
        print(f"❌ Exception occurred: {str(e)}")
        return False


def get_openrouter_key():
    """Get OpenRouter API key from environment."""
    api_key = os.getenv("OPENROUTER_API_KEY")

    if not api_key:
        print("❌ OPENROUTER_API_KEY not found in environment")
        return None

    if api_key == "your_openrouter_api_key_here":
        print("❌ API key is still placeholder value")
        return None

    return api_key


def main():
    print("🔑 Adding OpenRouter API Key to GitHub Repository")
    print("=" * 50)

    # Get API key
    api_key = get_openrouter_key()
    if not api_key:
        print("\n📝 Please enter your OpenRouter API key:")
        print("(Get free key at: https://openrouter.ai/)")
        api_key = input("OpenRouter API Key: ").strip()

    if not api_key:
        print("❌ No API key provided")
        return

    print(f"✅ API key provided: {api_key[:20]}...")

    # Add secret using GitHub CLI
    success = add_secret_with_gh_cli("OPENROUTER_API_KEY", api_key)

    if success:
        print("\n🎉 Secret added successfully!")
        print("🔄 The GitHub Actions workflow will now use this key")
        print("📝 You can trigger the workflow at:")
        print("https://github.com/cbwinslow/bash.d/actions")
    else:
        print("\n❌ Failed to add secret")
        print("💡 Make sure you have gh CLI installed and authenticated")


if __name__ == "__main__":
    main()
