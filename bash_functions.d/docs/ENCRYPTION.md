# Encryption System Documentation

## Overview
The bash_functions.d system uses **Age** for encrypting sensitive secrets like API tokens and keys. Age is a modern, secure encryption tool written in Go.

## Components
- **Age Tool**: Installed from https://github.com/FiloSottile/age
- **Key Pair**: Generated with `age-keygen`
  - Public key: Used for encryption
  - Private key: `~/.bash_secrets.d/age_key.txt` (securely stored)
- **Encrypted Files**:
  - `~/.bash_secrets.d/github/token.age` - GitHub PAT
  - `~/.bash_secrets.d/gitlab/token.age` - GitLab PAT
  - `~/.bash_secrets.d/openrouter/token.age` - OpenRouter API Key

## How It Works
1. **Encryption**: Tokens are encrypted using the public key: `echo "token" | age -r <public_key> > token.age`
2. **Decryption**: Scripts decrypt on-demand: `age -d -i ~/.bash_secrets.d/age_key.txt token.age`
3. **Automatic**: Plugins and API scripts handle decryption transparently

## Security
- Private key is encrypted and protected (600 permissions)
- Tokens never stored in plain text
- Decryption happens in memory only when needed
- Fallback to Bitwarden if encrypted files missing

## Setup
- Keys generated automatically by `setup_secrets.sh`
- Tokens encrypted when stored
- No manual key management required

## Usage
Tokens are automatically available to scripts. No user intervention needed.

## Backup
- Backup `~/.bash_secrets.d/age_key.txt` securely (this is your decryption key)
- Encrypted files can be safely backed up
- Never share the private key

## Alternatives Considered
- **YADM**: Dotfiles manager with GPG encryption. Not used because:
  - Requires GPG key setup
  - Adds complexity for secrets-only use case
  - Age provides simpler, direct encryption
- **GPG Directly**: Age is preferred for its simplicity and Go-based implementation
