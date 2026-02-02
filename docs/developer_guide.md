# Developer Guide — bash.d

This guide helps developers get productive with the project quickly.

## Local setup
1. Clone the repo
2. Run `./scripts/unified_install.sh` to install recommended tooling
3. Use the integrated CLI `./bashd` to interact with the platform

## Testing
- Unit tests: use the `tests/` folder and run locally
- Add tests with clear inputs and expected results
- Integrations should run in a containerized or sandbox environment

## Contributing
- See `CONTRIBUTING.md` for workflow details
- Keep PRs small and testable
- Update docs for any behavior changes

## Helpful tips
- Use shellcheck and linting for scripts
- Keep shared logic in `src/` and document it
- Use feature branches for all work
