# User Guide — bash.d

This guide provides instructions for end-users interacting with the platform.

## Getting started
- Install prerequisites and run `./scripts/unified_install.sh`
- Initialize your profile with `./bashd init --email=<you@example.com>`

## Common workflows
- Create a blog post: `./bashd blog create "Title"`
- Sync a data source: `./bashd data sync --source=congress`
- Deploy platform: `./bashd platform deploy`

## Troubleshooting
- Check logs in `platform/logs/` and use `./bashd infra status`
- Run tests locally using `./bashd test`
- If issues persist, open an issue and tag maintainers listed in `CONTRIBUTING.md`
