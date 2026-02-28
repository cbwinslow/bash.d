# bash.d Tasks & Roadmap

This document captures all tasks, features, and future work for the bash.d ecosystem.

## Session: 2026-02-28

### Completed This Session:

- [x] Clean up disk space (freed ~101GB)
  - Removed Docker build cache, NPM cache, PIP cache
  - Removed unused Docker images
  - Deleted crashing epstein-worker container

- [x] Set up PostgreSQL telemetry database
  - Created Docker container `telemetry-postgres` on port 5433
  - Fixed SQLAlchemy bugs in telemetry code
  - Database now collects hardware metrics (CPU, RAM, disk, GPU)

- [x] Build system process analyzer (`scripts/system_analyzer.sh`)
  - Shows top memory/CPU consumers
  - Identifies duplicate processes
  - Finds zombie processes
  - Lists long-running processes

- [x] Build continuous monitor (`scripts/monitor.sh`)
  - Alerts at 85%+ memory threshold
  - Detects memory spikes
  - Logs to `/tmp/system_monitor.log`

- [x] Build AI system agent (`scripts/ai_sys_agent.sh`)
  - Uses Ollama for analysis
  - Can provide recommendations
  - Interactive process killing

- [x] Add aliases to bashrc
  - `sys-analyze` - Run system analyzer
  - `sysmon` - Run continuous monitor
  - `ai-sys` - AI system agent

- [x] Build Menu Launcher (`scripts/menu.sh`)
- [x] Build Test Framework (`tests/test_framework.py`)
- [x] Build Debug Agent (`scripts/debug_agent.sh`)
- [x] Build RAG System (`telemetry/rag.py`)

---

## Pending Tasks (From Original Session Goals)

### Phase 1: Core Infrastructure ✅ (Mostly Complete)
- [x] Inventory system (`scripts/inventory.sh`)
- [x] Backup system (`scripts/backup.sh`)
- [x] API manager (GitHub, Cloudflare)
- [x] AI agents using Ollama
- [x] Conversation logging
- [x] PostgreSQL telemetry database

### Phase 2: Monitoring & Observability 🔄 (In Progress)
- [x] Process analyzer
- [x] System monitor with alerts
- [x] **RAG database for logs/conversations** ✅ COMPLETE
- [x] **ETL pipeline for data processing** ✅ COMPLETE
- [x] **AI agent with sub-agents for system control** ✅ COMPLETE

### Phase 3: UI & Interface 📋 (To Do)
- [x] **Menu Launcher** (`scripts/menu.sh`)
- [x] **TUI Launcher** (`telemetry/tui_launcher.py` - requires Textual)
- [ ] **Web dashboard**
- [ ] **Terminal dashboard (Textual)**

### Phase 4: Advanced Features 📋 (To Do)
- [x] OpenTelemetry integration ✅ COMPLETE
- [x] Automated remediation agents ✅ COMPLETE

---

## Testing System

### Test Framework (`tests/test_framework.py`)
- Reusable Python classes: `ShellTest`, `ScriptTest`, `DockerTest`, `DatabaseTest`, `TestSuite`
- Run: `python3 tests/test_framework.py`

### Debug Agent (`scripts/debug_agent.sh`)
- AI-powered debugging with Ollama
- Smoke tests, E2E tests, system health feedback

**Usage:**
```bash
python3 tests/test_framework.py    # Run smoke tests
debug smoke                        # Run via debug agent
debug test all                    # Run E2E tests
debug analyze                     # AI analyze system
debug feedback                    # Get AI feedback
```

---

## RAG System (`telemetry/rag.py`)

- Uses ChromaDB vector database (you have epstein-chroma running!)
- Stores conversations, logs, documentation
- Semantic search across all data

**Install:**
```bash
pip install chromadb
```

**Usage:**
```bash
rag-stats                    # View RAG stats
rag-search "memory error"    # Search
python3 rag.py add-conv <tool> <prompt> <response>
```

---

## Quick Reference: Available Commands

| Alias | Command | Description |
|-------|---------|-------------|
| `menu` | `scripts/menu.sh` | Launch menu |
| `sys-analyze` | `scripts/system_analyzer.sh` | Analyze system |
| `sysmon` | `scripts/monitor.sh` | Continuous monitor |
| `ai-sys` | `scripts/ai_sys_agent.sh` | AI system analysis |
| `debug` | `scripts/debug_agent.sh` | Debug & test agent |
| `inventory` | `scripts/inventory.sh` | System inventory |
| `backup` | `scripts/backup.sh` | Backup system |
| `ai` | `scripts/ai_agent.sh` | AI agent |
| `rag-stats` | `rag.py stats` | RAG stats |
| `rag-search` | `rag.py search` | RAG search |
| `etl-run` | `etl.py --once` | Run ETL once |
| `etl-start` | `etl.py` | Start ETL continuous |
| `multi-agent` | `multi_agent.py` | Multi-agent system |
| `otel-init` | `otel.py --init` | Initialize OpenTelemetry |
| `otel-status` | `otel.py --status` | Check OpenTelemetry status |

---

## Running Services

### Docker Containers
- `telemetry-postgres` - PostgreSQL (port 5433)
- `epstein-redis` - Redis cache
- `epstein-chroma` - ChromaDB vector DB (port 8000)
- `epstein-neo4j` - Neo4j graph DB
- `agent-zero` - AI agent framework

### System Services (Memory Heavy)
- ClamAV antivirus (~1.1GB)
- Multiple Kilo instances (~2.2GB)
- Multiple Cline instances (~1.2GB)
- Brave browser tabs (~2GB)

---

## Notes

- Memory at 77% - consider closing extra Kilo/Cline instances
- Zombie Brave processes accumulating - restart browser periodically
- Telemetry collecting hardware metrics every 10s
- ChromaDB running - RAG system ready to use!
