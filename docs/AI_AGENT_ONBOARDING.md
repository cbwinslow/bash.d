# 🚀 AI Agent Onboarding Guide
## Welcome to bash.d Development!

**Purpose:** Help AI agents quickly understand the project and start contributing  
**Last Updated:** 2026-02-13

---

## 🎯 Your Mission

Help build bash.d - a comprehensive, modular bash configuration framework with:
- 100+ specialized AI agents
- 100+ MCP-compatible tools
- Advanced bash functions and completions
- Full CI/CD and automation
- Production-ready infrastructure

---

## ⚡ Quick Start (5 Minutes)

### Step 1: Understand the System (2 min)
```bash
# Read these in order:
1. README.md                    # Project overview
2. MASTER_TASK_LIST.md         # All available tasks (skim)
3. docs/TASK_TRACKING.md       # Current sprint focus
4. docs/QUICK_REFERENCE.md     # Navigation guide
```

### Step 2: Pick Your First Task (2 min)
```bash
# Easy starter tasks:
- MASTER-1.1.1: Create completions directory (15 min)
- MASTER-1.2.1: Audit existing aliases (30 min)
- MASTER-10.1.4: Create FAQ (1 hour)

# Medium impact tasks:
- MASTER-3.1.2: Create agent registry (4 hours)
- MASTER-1.3.1: Audit existing functions (2 hours)
- MASTER-6.1.2: Create CI workflow (3 hours)
```

### Step 3: Start Working (1 min)
```bash
# Use the tools available to you:
1. Read task details from MASTER_TASK_LIST.md
2. Check dependencies in docs/TASK_TRACKING.md
3. Implement following the criteria
4. Test using the provided test command
5. Mark complete in all documents
```

---

## 📚 Essential Reading

### Must Read (15 minutes)
1. **[README.md](README.md)** - What bash.d is
2. **[MASTER_TASK_LIST.md](MASTER_TASK_LIST.md)** - What needs to be done
3. **[docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)** - How to find things

### Should Read (30 minutes)
4. **[docs/TASK_TRACKING.md](docs/TASK_TRACKING.md)** - Current sprint
5. **[docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md)** - Code organization
6. **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines

### Nice to Read (1 hour)
7. **[docs/tasks.md](docs/tasks.md)** - Agent system details
8. **[agents/README.md](agents/README.md)** - Agent architecture
9. **[tools/README.md](tools/README.md)** - Tool system

---

## 🗺️ Project Architecture

### High-Level Structure
```
bash.d/
├── Core System
│   ├── bashrc                 # Main entry point
│   ├── bash_functions.d/      # Modular functions
│   ├── aliases/               # Alias definitions
│   ├── completions/           # Tab completions
│   └── bash_secrets.d/        # Secure secrets
│
├── AI System
│   ├── agents/                # 100+ AI agents
│   ├── tools/                 # 100+ MCP tools
│   └── ai/                    # AI utilities
│
├── Infrastructure
│   ├── scripts/               # Utility scripts
│   ├── tests/                 # Test suite
│   ├── .github/               # GitHub automation
│   └── docs/                  # Documentation
│
└── Configuration
    ├── configs/               # Config files
    ├── crewai_config/         # CrewAI configs
    └── external/              # External deps
```

### Key Components

#### 1. Bash Functions (`bash_functions.d/`)
- Modular bash functions organized by category
- Core functions for system, git, docker, network, etc.
- AI integration functions
- Over 200 functions currently

#### 2. AI Agents (`agents/`)
- Python-based AI agents using Pydantic
- Specialized agents for different tasks
- Agent registry and discovery system
- Communication via A2A protocol

#### 3. Tools (`tools/`)
- MCP-compatible tools
- Filesystem, git, docker, API tools
- Tool registry and validation
- Integration with agents

#### 4. Automation (`.github/workflows/`)
- CI/CD pipelines
- Documentation generation
- Testing automation
- Release management

---

## 🎯 Task System Explained

### Three Documents, One System

```
┌─────────────────────────────────────────┐
│ MASTER_TASK_LIST.md                     │
│ • 500+ microtasks                       │
│ • 20 phases                             │
│ • Complete roadmap                      │
│ • Each task has:                        │
│   - ID (e.g., MASTER-1.1.1)            │
│   - Description                         │
│   - Success criteria                    │
│   - Files to create/modify             │
│   - Test command                        │
│   - Dependencies                        │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│ docs/TASK_TRACKING.md                   │
│ • Current sprint tasks                  │
│ • Weekly planning                       │
│ • Progress tracking                     │
│ • Task selection guide                  │
│ • Status updates                        │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│ GitHub Issues                           │
│ • Individual task tracking              │
│ • Discussion and questions              │
│ • Implementation details                │
│ • Code review                           │
└─────────────────────────────────────────┘
```

### Task Lifecycle

```
1. Select      → Browse MASTER_TASK_LIST.md
                 Pick uncompleted task
                 
2. Verify      → Check docs/TASK_TRACKING.md
                 Ensure dependencies met
                 
3. Create      → Open GitHub issue (optional)
                 Use task template
                 
4. Implement   → Follow task criteria
                 Create/modify files
                 
5. Test        → Run test command
                 Verify success criteria
                 
6. Document    → Update relevant docs
                 Add usage examples
                 
7. Complete    → Mark [x] in MASTER_TASK_LIST.md
                 Update docs/TASK_TRACKING.md
                 Commit with proper message
                 
8. Report      → Update progress
                 Close issue (if created)
```

---

## 💻 Development Workflow

### Setting Up
```bash
# 1. You're already in the repository
cd /home/runner/work/bash.d/bash.d

# 2. Check current branch
git branch

# 3. Check status
git status

# 4. List available tasks
grep "^- \[ \]" MASTER_TASK_LIST.md | head -20
```

### Implementing a Task
```bash
# Example: Task 1.1.1 - Create completions directory

# 1. Read task details
grep -A 10 "Task 1.1.1" MASTER_TASK_LIST.md

# 2. Implement
mkdir -p completions
cat > completions/README.md << 'EOF'
# Bash Completions

This directory contains bash completion scripts.
EOF
touch completions/.gitkeep

# 3. Test
[ -d completions ] && [ -f completions/README.md ] && echo "✅ PASS" || echo "❌ FAIL"

# 4. Mark complete
# Edit MASTER_TASK_LIST.md: Change [ ] to [x] for Task 1.1.1

# 5. Update tracking
# Edit docs/TASK_TRACKING.md: Update progress percentage

# 6. Commit
git add completions/
git add MASTER_TASK_LIST.md
git add docs/TASK_TRACKING.md
git commit -m "[MASTER-1.1.1] Create completions directory structure

- Completed Task 1.1.1: Create /completions/ directory structure
- Files: completions/README.md, completions/.gitkeep
- Test: Directory and README verified
- Status: Complete"
```

### Commit Message Format
```
[TASK-ID] Brief description (50 chars max)

- Completed Task X.Y.Z: Full task name
- Files: List of files created/modified
- Test: How it was tested
- Status: Complete/Partial/Blocked
- Notes: Any additional context (optional)
```

---

## 🧪 Testing Your Changes

### Running Tests
```bash
# Test bash functions
bash -n bash_functions.d/**/*.sh  # Syntax check

# Test Python code
python -m pytest tests/           # Run test suite

# Test specific module
python -m agents.base             # Test agents
python -m tools.registry          # Test tools

# Test installations
./install.sh --help               # Check installer
```

### Validation Checklist
- [ ] Syntax is correct (no bash/python errors)
- [ ] Test command passes
- [ ] No existing functionality broken
- [ ] Documentation updated
- [ ] Follows code style
- [ ] Secrets not committed

---

## 📖 Code Style Guide

### Bash Style
```bash
#!/bin/bash
# Description: What this script does
# Usage: script_name [options]

# Global variables in UPPERCASE
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Functions with bashd_ prefix
bashd_example_function() {
    # Local variables in lowercase
    local input="$1"
    local output
    
    # Always quote variables
    output=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    
    # Return value
    echo "$output"
}

# Export functions
export -f bashd_example_function
```

### Python Style
```python
"""Module description.

This module provides functionality for...
"""

from typing import List, Optional
from pydantic import BaseModel, Field

class AgentConfig(BaseModel):
    """Configuration for an AI agent.
    
    Attributes:
        name: Unique agent identifier
        description: Human-readable description
        tools: List of tool names
    """
    
    name: str = Field(..., description="Agent name")
    description: str = Field(..., description="Agent description")
    tools: List[str] = Field(default_factory=list)

def create_agent(config: AgentConfig) -> Agent:
    """Create a new agent instance.
    
    Args:
        config: Agent configuration object
        
    Returns:
        Initialized agent instance
        
    Raises:
        ValueError: If configuration is invalid
    """
    if not config.name:
        raise ValueError("Agent name required")
    return Agent(config)
```

---

## 🎓 Learning Resources

### Bash Resources
- [Bash Reference Manual](https://www.gnu.org/software/bash/manual/)
- [ShellCheck](https://www.shellcheck.net/) - Bash linter
- [Bash Guide](https://mywiki.wooledge.org/BashGuide)

### Python Resources
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [Python Type Hints](https://docs.python.org/3/library/typing.html)
- [Python Style Guide (PEP 8)](https://peps.python.org/pep-0008/)

### AI/ML Resources
- [MCP Protocol](https://modelcontextprotocol.io/)
- [CrewAI Documentation](https://docs.crewai.com/)
- [OpenRouter API](https://openrouter.ai/docs)

---

## 🤝 Collaboration

### Working with Other Agents
- Check task assignments in docs/TASK_TRACKING.md
- Avoid duplicate work on same task
- Parallel tasks are marked with ||
- Dependent tasks are marked with →

### Communication
- Create GitHub issues for questions
- Update task status regularly
- Document decisions in commit messages
- Share learnings in discussions

---

## 🚨 Common Pitfalls

### ❌ Don't Do This
```bash
# Don't commit secrets
export API_KEY="sk-123456"  # ❌

# Don't use unquoted variables
rm -rf $DIR/*  # ❌ Dangerous!

# Don't skip testing
# (just assume it works)  # ❌

# Don't break existing functionality
# rm -rf bash_functions.d/  # ❌
```

### ✅ Do This Instead
```bash
# Store secrets properly
echo "export API_KEY='sk-123456'" > bash_secrets.d/api.env  # ✅

# Always quote variables
rm -rf "${DIR:?}/"*  # ✅ Safe!

# Always test
[ -d completions ] && echo "✅ PASS"  # ✅

# Preserve existing functionality
# Add new files, don't delete unless specifically required  # ✅
```

---

## 🎯 Success Metrics

### Your Impact
Track your contributions:
- Tasks completed
- Tests added
- Documentation written
- Bugs fixed
- Features added

### Quality Indicators
- All tests passing ✅
- Documentation complete ✅
- No regressions ✅
- Code reviewed ✅
- Follows style guide ✅

---

## 📞 Getting Help

### Stuck on Something?

1. **Search first**
   ```bash
   grep -r "search term" docs/
   grep -r "function_name" bash_functions.d/
   ```

2. **Check examples**
   - Look at similar existing code
   - Review completed tasks
   - Check test files

3. **Ask for help**
   - Create GitHub issue with [QUESTION] tag
   - Use discussion for general questions
   - Mark task as "Blocked" in tracking

### Questions to Ask
- "Where can I find examples of X?"
- "How do I test Y?"
- "What's the pattern for Z?"
- "Is task A.B.C complete?"

---

## 🎉 Your First Contribution

### Recommended Path
1. **Start Small** (Day 1)
   - Pick easy task (MASTER-1.1.1 or similar)
   - Read task carefully
   - Implement and test
   - Commit with proper format

2. **Build Confidence** (Day 2-3)
   - Try medium complexity task
   - Add more comprehensive tests
   - Improve documentation
   - Help other agents

3. **Tackle Bigger Challenges** (Week 1+)
   - Work on high-impact tasks
   - Implement multiple related tasks
   - Improve architecture
   - Create new features

---

## 📈 Leveling Up

### Beginner → Intermediate
- Complete 5+ easy tasks
- Understand project structure
- Write good tests
- Follow style guide

### Intermediate → Advanced
- Complete 10+ medium tasks
- Contribute to architecture
- Help other agents
- Improve documentation

### Advanced → Expert
- Lead feature development
- Review other contributions
- Optimize performance
- Mentor new agents

---

## 🏆 Recognition

### Your Contributions Matter!
- Every task completed moves the project forward
- Good documentation helps future contributors
- Quality code reduces maintenance burden
- Helping others builds community

---

## 🚀 Ready to Start?

### Next Steps
1. ✅ You've read this guide
2. 📖 Open MASTER_TASK_LIST.md
3. 🎯 Pick your first task
4. 💻 Start coding!

### Remember
- Read task criteria carefully
- Test before marking complete
- Document as you go
- Ask when stuck
- Have fun coding! 🎉

---

**Welcome to the team! Let's build something amazing together! 🚀**

---

**Maintained By:** bash.d Development Team  
**Questions?** Create a [discussion](https://github.com/cbwinslow/bash.d/discussions) or [issue](https://github.com/cbwinslow/bash.d/issues)
