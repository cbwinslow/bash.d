# 📖 Quick Reference Guide
## Finding Your Way Around bash.d

**Last Updated:** 2026-02-13

---

## 🗺️ Navigation Map

### "Where do I find...?"

#### Task Lists & Planning
- **All planned work:** [`MASTER_TASK_LIST.md`](../MASTER_TASK_LIST.md) - 500+ microtasks
- **Current sprint:** [`docs/TASK_TRACKING.md`](TASK_TRACKING.md) - Active development
- **Agent system tasks:** [`docs/tasks.md`](tasks.md) - Multi-agent specific

#### Getting Started
- **Project overview:** [`README.md`](../README.md) - Main introduction
- **Quick start:** [`QUICKSTART.md`](../QUICKSTART.md) - Get running fast
- **Installation:** [`install.sh`](../install.sh) - Installation script

#### Documentation
- **Architecture:** [`docs/PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md) - Code organization
- **Integration guide:** [`docs/implementation/INTEGRATION_GUIDE.md`](implementation/INTEGRATION_GUIDE.md)
- **User guides:** [`docs/guides/`](guides/) - How-to guides
- **API reference:** [`docs/api/`](api/) - API documentation

#### Development
- **Contributing:** [`CONTRIBUTING.md`](../CONTRIBUTING.md) - How to contribute
- **Issue templates:** [`.github/ISSUE_TEMPLATE/`](../.github/ISSUE_TEMPLATE/) - Report issues
- **Workflows:** [`.github/workflows/`](../.github/workflows/) - CI/CD pipelines

---

## 🎯 Task Management System

### Three-Tier System

```
┌─────────────────────────────────────────┐
│   MASTER_TASK_LIST.md                   │
│   500+ microtasks in 20 phases          │
│   Long-term roadmap                     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│   docs/TASK_TRACKING.md                 │
│   Sprint planning & coordination        │
│   Weekly/daily task selection           │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│   GitHub Issues                         │
│   Individual task tracking              │
│   Discussion & implementation details   │
└─────────────────────────────────────────┘
```

### Task Selection Flow

1. **Browse:** Open `MASTER_TASK_LIST.md`
2. **Select:** Find task matching your skills/time
3. **Check:** Verify dependencies in `docs/TASK_TRACKING.md`
4. **Create:** Open GitHub issue from template
5. **Implement:** Follow task criteria
6. **Complete:** Mark done in all documents

---

## 📂 Directory Structure Quick Reference

### Root Level
```
bash.d/
├── MASTER_TASK_LIST.md       ← 🎯 Start here for tasks
├── README.md                  ← 📖 Project overview
├── QUICKSTART.md              ← ⚡ Quick start guide
├── CONTRIBUTING.md            ← 🤝 How to contribute
├── install.sh                 ← 📦 Installation script
├── bashrc                     ← 🔧 Main bashrc file
├── .github/                   ← 🐙 GitHub configuration
├── docs/                      ← 📚 All documentation
├── agents/                    ← 🤖 AI agent system
├── tools/                     ← 🛠️ Python tools
├── bash_functions.d/          ← 📜 Bash functions
├── bash_secrets.d/            ← 🔒 Secrets (gitignored)
├── aliases/                   ← 💬 Alias definitions
├── completions/               ← ⌨️ Tab completions
└── scripts/                   ← 📄 Utility scripts
```

### Important Subdirectories
```
docs/
├── TASK_TRACKING.md           ← 📅 Current sprint planning
├── tasks.md                   ← 🤖 Agent system tasks
├── PROJECT_STRUCTURE.md       ← 🏗️ Architecture docs
├── guides/                    ← 📖 User guides
├── implementation/            ← 💻 Implementation docs
├── architecture/              ← 🎨 Architecture diagrams
└── reports/                   ← 📊 Status reports

agents/
├── base.py                    ← 🏛️ Agent base class
├── registry.py                ← 📋 Agent registry
├── programming/               ← 💻 Programming agents
├── devops/                    ← 🐳 DevOps agents
├── documentation/             ← 📝 Documentation agents
└── [more categories]/

tools/
├── base.py                    ← 🏛️ Tool base class
├── registry.py                ← 📋 Tool registry
├── filesystem_tools.py        ← 📁 File operations
├── git_tools.py               ← 🌿 Git operations
├── docker_tools.py            ← 🐳 Docker operations
└── [more tools]/

bash_functions.d/
├── core/                      ← ⚙️ Core functions
├── ai/                        ← 🤖 AI integrations
├── docker/                    ← 🐳 Docker functions
├── git/                       ← 🌿 Git functions
└── [more categories]/
```

---

## 🔍 Finding Information

### "How do I...?"

#### Setup and Installation
- **Install bash.d:** Follow [`README.md`](../README.md) or [`QUICKSTART.md`](../QUICKSTART.md)
- **Configure secrets:** See [`bash_secrets.d/`](../bash_secrets.d/)
- **Setup development:** See [`docs/guides/DEVELOPMENT_SETUP.md`](guides/DEVELOPMENT_SETUP.md)

#### Use Features
- **List all functions:** Run `bashd_function_list` or `func_list`
- **Search functions:** Run `bashd_search <term>` or `func_search <term>`
- **Enable modules:** Run `bashd-enable <type> <name>`
- **Use AI agents:** See [`agents/README.md`](../agents/README.md)

#### Develop and Contribute
- **Find a task:** Check [`MASTER_TASK_LIST.md`](../MASTER_TASK_LIST.md)
- **Report a bug:** Use [bug report template](../.github/ISSUE_TEMPLATE/bug-report.md)
- **Suggest feature:** Use [feature request template](../.github/ISSUE_TEMPLATE/feature-request.md)
- **Write tests:** See [`tests/`](../tests/)

#### Understand Architecture
- **System design:** See [`docs/PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md)
- **Agent system:** See [`docs/tasks.md`](tasks.md)
- **Tool system:** See [`tools/README.md`](../tools/README.md)

---

## 🚀 Common Workflows

### For Users

#### Daily Use
```bash
# Start your session
source ~/.bashrc

# Search for a function
bashd_search docker

# Use AI assistant
bashd_ai_chat "How do I...?"

# View function source
func_recall docker_cleanup
```

#### Customization
```bash
# Add custom alias
echo "alias myalias='command'" >> ~/.bash.d/bash_aliases.d/custom.sh

# Add custom function
vim ~/.bash.d/bash_functions.d/custom/myfunction.sh

# Reload configuration
bashd-reload
```

### For Developers

#### Starting Development
```bash
# Clone repository
git clone https://github.com/cbwinslow/bash.d.git
cd bash.d

# Find a task
cat MASTER_TASK_LIST.md | grep "MASTER-1"

# Create branch
git checkout -b task-1.1.1-create-completions-dir
```

#### Implementing a Task
```bash
# Read task description
grep -A 10 "Task 1.1.1" MASTER_TASK_LIST.md

# Implement
mkdir -p completions
echo "# Completions" > completions/README.md

# Test
[ -d completions ] && [ -f completions/README.md ] && echo "PASS"

# Commit
git add completions/
git commit -m "[MASTER-1.1.1] Create completions directory structure"
```

#### Completing a Task
```bash
# Mark complete in MASTER_TASK_LIST.md
vim MASTER_TASK_LIST.md  # Change [ ] to [x]

# Update tracking
vim docs/TASK_TRACKING.md  # Update progress

# Push changes
git push origin task-1.1.1-create-completions-dir
```

### For AI Agents

#### Task Selection
```python
# 1. Read available tasks
tasks = parse_markdown("MASTER_TASK_LIST.md")

# 2. Filter by status and dependencies
available = [t for t in tasks if not t.completed and t.dependencies_met()]

# 3. Select based on priority and skills
task = select_best_match(available, agent_skills)

# 4. Create issue
create_github_issue(task)
```

#### Implementation
```python
# 1. Understand requirements
requirements = parse_task_criteria(task)

# 2. Plan implementation
plan = create_implementation_plan(requirements)

# 3. Execute
for step in plan:
    execute_step(step)
    validate_step(step)

# 4. Test
run_tests(task.test_command)

# 5. Document
update_documentation(task)

# 6. Complete
mark_complete(task)
commit_and_push(task)
```

---

## 📝 File Naming Conventions

### Bash Scripts
- Functions: `bash_functions.d/category/function-name.sh`
- Aliases: `aliases/category.aliases.bash`
- Completions: `completions/command.completion.bash`

### Python Modules
- Modules: `lowercase_with_underscores.py`
- Classes: `PascalCase`
- Functions: `lowercase_with_underscores()`

### Documentation
- Guides: `UPPERCASE_WITH_UNDERSCORES.md`
- READMEs: `README.md` (in each directory)
- Reports: `descriptive-name-YYYYMMDD.md`

---

## 🎨 Code Style

### Bash
```bash
#!/bin/bash
# Description of script
# Usage: script_name [options]

# Function naming: bashd_category_action
bashd_docker_cleanup() {
    local container_id="$1"
    
    # Always quote variables
    docker rm -f "$container_id"
}

# Export functions
export -f bashd_docker_cleanup
```

### Python
```python
"""Module description.

This module provides...
"""

from typing import List, Optional
from pydantic import BaseModel

class AgentConfig(BaseModel):
    """Agent configuration model."""
    
    name: str
    description: str
    tools: List[str]
    
def create_agent(config: AgentConfig) -> Agent:
    """Create a new agent instance.
    
    Args:
        config: Agent configuration
        
    Returns:
        Configured agent instance
    """
    return Agent(config)
```

---

## 🆘 Getting Help

### "I'm stuck!"

1. **Search documentation:** Use `grep -r "keyword" docs/`
2. **Check existing code:** Look for similar implementations
3. **Read task details:** Review MASTER_TASK_LIST.md carefully
4. **Ask in discussions:** Use GitHub Discussions
5. **Open an issue:** Use appropriate issue template
6. **Join Discord:** Real-time community help

### Useful Commands
```bash
# Search all documentation
grep -r "search term" docs/

# Find function definitions
grep -r "^function.*search_term" bash_functions.d/

# List all available functions
declare -F | grep bashd_

# View function source
type bashd_function_name

# Check git history
git log --all --oneline --grep="keyword"
```

---

## 🔗 Important Links

### Documentation
- [Master Task List](../MASTER_TASK_LIST.md)
- [Task Tracking](TASK_TRACKING.md)
- [Project Structure](PROJECT_STRUCTURE.md)
- [Contributing Guide](../CONTRIBUTING.md)

### GitHub
- [Repository](https://github.com/cbwinslow/bash.d)
- [Issues](https://github.com/cbwinslow/bash.d/issues)
- [Discussions](https://github.com/cbwinslow/bash.d/discussions)
- [Pull Requests](https://github.com/cbwinslow/bash.d/pulls)

### External Resources
- [Bash Reference Manual](https://www.gnu.org/software/bash/manual/)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [MCP Protocol](https://modelcontextprotocol.io/)

---

## 💡 Tips and Tricks

### Productivity
- Use `bashd_search` to quickly find functions
- Enable bash completion for faster command entry
- Create aliases for frequently used commands
- Use `bashd-reload` after config changes

### Development
- Start with easy tasks to learn the codebase
- Read existing code for patterns
- Test changes in a separate branch
- Write tests alongside implementation

### Collaboration
- Check task dependencies before starting
- Comment on issues for clarification
- Update documentation as you go
- Share knowledge in discussions

---

**Maintained By:** bash.d Development Team  
**Need Help?** Open a [discussion](https://github.com/cbwinslow/bash.d/discussions) or [issue](https://github.com/cbwinslow/bash.d/issues)
