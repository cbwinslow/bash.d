# Architecture — bash.d

## High-level architecture
- CLI (`bashd`) handles lifecycle and developer workflows
- Plugins: Connectors and integrations for data ingestion and export
- Data pipeline: Ingest → normalize → index → publish
- Platform: Blog engine, data portal, and public APIs
- Infrastructure: IaC and Cloudflare for hosting

## Components
- CLI: shell scripts and small Go/Python microservices for heavy tasks
- Plugins: self-contained directories under `plugins/` with tests and docs
- Data: `data/` stores normalized data and intermediate caches
- Infrastructure: Terraform/Pulumi scripts in `infrastructure/`

## Design decisions
- Use modular CLI for discoverability and scripting
- Prefer shell-first approach for portability and simplicity
- Use R2 for static content and small file storage
- Leverage OCIs and container tooling for reproducible tests and deployments

## Data flow
1. Connector harvests raw data and writes to `data/`.
2. Normalizer cleans and converts to canonical schemas.
3. Indexer builds the searchable index and stores it in R2 or DB.
4. API reads from the index and serves clients.

## Scaling strategy
- Horizontally scale ingestion workers
- Use queue/backing store for reliability (e.g., Redis/Cloud tasks)
- Caching at the edge via Cloudflare

## Observability
- Use centralized logs and metrics (Prometheus + Grafana)
- Alerts for failures and SLA breaches
- Structured logs for traceability
