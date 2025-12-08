# Quick Start: Autonomous Application Builder

Get started building applications with AI agents in under 5 minutes!

## 🚀 Super Quick Start (30 seconds)

```bash
# 1. Start the system
./scripts/start_app_builder.sh

# 2. Open your browser
open http://localhost:8080

# 3. Fill in your app idea and click "GO"!
```

That's it! Watch the AI agents build your application autonomously.

## 📋 What You Need

- **Docker** (for running services)
- **Python 3.11+** (for the builder system)
- **5 minutes** of your time

## 🎯 Three Ways to Build

### 1. Web Interface (Easiest)

Perfect for: Visual learners and quick prototyping

```bash
./scripts/start_app_builder.sh
# Open http://localhost:8080
```

**Steps:**
1. Enter your application title
2. Describe what it should do
3. Add requirements (optional)
4. Click "🚀 GO - Build My Application"
5. Watch the progress in real-time!

### 2. Command Line (Most Flexible)

Perfect for: Terminal enthusiasts and automation

**Interactive Mode:**
```bash
python scripts/build_app.py interactive
```

The CLI will guide you through:
- Application title
- Description
- Target users
- Requirements (one by one)
- Success criteria

**Direct Build:**
```bash
python scripts/build_app.py build \
  --title "My API" \
  --description "RESTful API for tasks" \
  --requirement "User auth" \
  --requirement "CRUD operations"
```

**From JSON File:**
```bash
python scripts/build_app.py from-file examples/task-manager-api.json
```

### 3. Python API (Most Powerful)

Perfect for: Integration and customization

```python
from agents.orchestrator import AgentOrchestrator
from agents.application_builder import ApplicationBuilder, ApplicationIdea

# Initialize
orchestrator = AgentOrchestrator()
builder = ApplicationBuilder(orchestrator)

# Define your app
idea = ApplicationIdea(
    title="Task Manager",
    description="Manage tasks with priorities",
    requirements=[
        "User authentication",
        "CRUD for tasks",
        "Priority levels"
    ]
)

# Build it!
result = await builder.build_application(idea, autonomous=True)
print(f"Done! Built in {result['phases_completed']} phases")
```

## 🎬 See It In Action

### Run the Demo

```bash
python demo_autonomous_builder.py
```

This shows:
- ✅ Democratic voting between agents
- ✅ Task decomposition
- ✅ All 11 phases in action
- ✅ Testing and automatic debugging
- ✅ Beautiful progress visualization

Takes ~2 minutes to complete.

## 📖 Example: Build a Blog Platform

### Web Interface

1. **Title:** Modern Blog Platform
2. **Description:** Full-featured blog with editor, comments, and admin dashboard
3. **Requirements:**
   - Rich text editor
   - User authentication
   - Comments system
   - Admin panel
4. Click **GO**!

### Command Line

```bash
python scripts/build_app.py build \
  --title "Modern Blog Platform" \
  --description "Full-featured blog with editor and comments" \
  --requirement "Rich text editor" \
  --requirement "User authentication" \
  --requirement "Comments system" \
  --requirement "Admin panel"
```

### Python API

```python
idea = ApplicationIdea(
    title="Modern Blog Platform",
    description="Full-featured blog with editor, comments, and admin dashboard",
    requirements=[
        "Rich text editor with markdown",
        "User authentication and profiles",
        "Comments with nested replies",
        "Admin dashboard",
        "SEO optimization"
    ],
    target_users="Bloggers and content creators",
    success_criteria=[
        "Fast page loads (<2s)",
        "Mobile responsive",
        "90%+ test coverage"
    ]
)

result = await builder.build_application(idea)
```

## 🎯 What Gets Built

The system creates:

### For APIs:
- ✅ Complete backend code (FastAPI, Express, Django, etc.)
- ✅ Database schema and migrations
- ✅ Authentication system
- ✅ API documentation (OpenAPI/Swagger)
- ✅ Test suite (unit, integration, E2E)
- ✅ Docker configuration
- ✅ CI/CD pipeline

### For Web Apps:
- ✅ Frontend UI (React, Vue, or vanilla JS)
- ✅ Backend API
- ✅ Database setup
- ✅ Authentication flow
- ✅ Responsive design
- ✅ Complete test suite
- ✅ Build configuration
- ✅ Deployment scripts

### For Microservices:
- ✅ Service code (Go, Python, Node.js, etc.)
- ✅ gRPC/REST APIs
- ✅ Database per service
- ✅ Docker containers
- ✅ Kubernetes manifests
- ✅ Service mesh configuration
- ✅ Complete tests

## ⏱️ How Long Does It Take?

Depends on complexity:

- **Simple API:** ~3-5 minutes
- **Web Application:** ~8-12 minutes
- **Microservices:** ~15-20 minutes
- **Complex Platform:** ~30-45 minutes

All **fully autonomous** - no intervention needed!

## 🔍 Monitoring Progress

### Web Interface
- Real-time progress bar
- Phase-by-phase status
- Live logs
- Agent activities

### Command Line
```bash
# Check build status
python scripts/build_app.py status

# View all builds
python scripts/build_app.py status
```

### API
```bash
# Get build status
curl http://localhost:8000/api/v1/builds/{build_id}

# List all builds
curl http://localhost:8000/api/v1/builds
```

### WebSocket (Real-time)
```javascript
const ws = new WebSocket('ws://localhost:8000/ws');
ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    console.log('Progress:', data);
};
```

## 🛠️ Customization

### Use Your Own Agents

```python
from agents.base import BaseAgent, AgentType, AgentCapability

class MyCustomAgent(BaseAgent):
    def __init__(self):
        super().__init__(
            name="My Agent",
            type=AgentType.PROGRAMMING,
            description="Custom functionality"
        )
    
    async def execute_task(self, task):
        # Your custom logic
        return {"status": "completed"}

# Register it
orchestrator.register_agent(MyCustomAgent())
```

### Add Custom Phases

```python
class ExtendedBuilder(ApplicationBuilder):
    async def _execute_custom_phase(self, plan):
        # Your custom phase logic
        return {"status": "completed"}
```

See [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) for details.

## 📚 Next Steps

- **Read the full guide:** [AUTONOMOUS_APP_BUILDER.md](AUTONOMOUS_APP_BUILDER.md)
- **Learn to extend:** [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)
- **Try examples:** Check `examples/` directory
- **Explore agents:** See `agents/` directory

## 🆘 Troubleshooting

### System won't start

```bash
# Check Docker is running
docker ps

# Check Python version
python3 --version  # Should be 3.11+

# Reinstall dependencies
pip install -r requirements.txt
```

### Build fails

```bash
# Check API logs
docker compose logs agent_orchestrator

# Check system health
curl http://localhost:8000/health
```

### Can't access web UI

```bash
# Verify it's running
curl http://localhost:8080

# Check if port is in use
lsof -i :8080
```

## 🎉 Success!

You now have:
- ✅ A working autonomous application builder
- ✅ Multiple ways to build applications
- ✅ Real-time progress monitoring
- ✅ Complete documentation

**Start building amazing applications with AI! 🚀**

---

## 📞 Need Help?

- **Documentation:** See README files in this directory
- **Examples:** Check `examples/` directory
- **Issues:** Report on GitHub
- **Demo:** Run `python demo_autonomous_builder.py`

## 🌟 Example Applications to Try

Start with these:

1. **Task Manager API** (`examples/task-manager-api.json`)
   - RESTful API with authentication
   - CRUD operations
   - Real-time notifications

2. **Blog Platform** (`examples/blog-platform.json`)
   - Full-stack web app
   - Rich text editor
   - Comments system

3. **Chat Application** (`examples/chat-application.json`)
   - Real-time messaging
   - WebSocket communication
   - File sharing

4. **E-commerce Platform** (`examples/ecommerce-platform.json`)
   - Complete online store
   - Payment integration
   - Order management

Try them:
```bash
python scripts/build_app.py from-file examples/task-manager-api.json
```

Happy building! 🎊
