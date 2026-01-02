TUI scaffold (Go + bubbletea)

This directory will contain a Go-based TUI that interacts with agents, dotman, and search functions.

Suggested layout:
- go-term/
  - cmd/term/main.go
  - internal/ui/* (bubbletea models)
  - Makefile

Build: cd go-term && make build
Run: ./go-term/bin/term

Security: TUI must not display plaintext secrets. Decryption streams to a temp file with 600 perms.
