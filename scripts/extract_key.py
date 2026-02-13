#!/usr/bin/env python3
"""
Secure API Key Extractor from .env file
"""

import os
import re
from pathlib import Path


def extract_api_key():
    """Extract OpenRouter API key from .env file."""
    env_file = Path(".env")

    if not env_file.exists():
        return None

    try:
        with open(env_file, "r", encoding="utf-8") as f:
            content = f.read()

        # Look for OPENROUTER_API_KEY
        match = re.search(
            r'OPENROUTER_API_KEY\s*=\s*["\']?([a-zA-Z0-9_-]+)["\']?', content
        )
        if match:
            return match.group(1)

        return None
    except Exception:
        return None


def main():
    api_key = extract_api_key()

    if api_key:
        print(f"Found OpenRouter API key: {api_key[:20]}...")
        print("Key extracted successfully")
        return api_key
    else:
        print("❌ OPENROUTER_API_KEY not found in .env file")
        print("Make sure .env contains: OPENROUTER_API_KEY=your_key_here")
        return None


if __name__ == "__main__":
    key = main()
