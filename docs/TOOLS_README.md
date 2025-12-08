# Comprehensive AI Agent Tool Suite

> A complete collection of 140+ OpenAI-compatible tools with MCP protocol support, Bitwarden secret management, and multi-format schema export.

## 🚀 Quick Start

### Installation

```bash
# Clone repository (if not already done)
git clone https://github.com/cbwinslow/bash.d.git
cd bash.d

# Run setup script
./setup_tools.sh

# Activate virtual environment
source venv/bin/activate

# Verify installation
python -m tools.registry stats
```

### First Steps

```python
# Import and use tools
from tools.registry import get_tool
import asyncio

async def main():
    # Get a tool
    reader = get_tool("read_file_content")
    
    # Execute it
    result = await reader.execute(file_path="test.txt")
    
    # Use the result
    if result.success:
        print(result.data["content"])

asyncio.run(main())
```

## 📦 What's Included

### Complete Tool Categories

1. **File System (20 tools)** - File and directory operations
2. **Text Processing (20 tools)** - Text manipulation and analysis
3. **API & HTTP (20 tools)** - HTTP client and API operations
4. **Bitwarden (13 tools)** - Secure secret management
5. **Git (15 tools)** - Version control operations
6. **Data (20 tools)** - Data transformation and processing
7. **Docker (15 tools)** - Container management
8. **System (15 tools)** - System monitoring and process management

**Total: 140+ tools** across all categories

### Multiple Export Formats

All tools support three schema formats:

- **OpenAI Function Calling Format** - Direct integration with OpenAI API
- **MCP (Model Context Protocol)** - Standard protocol for agent-tool interaction
- **Generic JSON** - Universal format for any platform

### Bitwarden Integration

Comprehensive secret management system allowing AI agents to:

- Securely retrieve API keys
- Access credentials
- Query vault items
- Manage sessions

See [BITWARDEN_INTEGRATION.md](BITWARDEN_INTEGRATION.md) for detailed setup.

## 🎯 Key Features

### ✨ Production-Ready

- Full async/await support
- Comprehensive error handling
- Parameter validation
- Type safety with Pydantic
- Extensive logging

### 🔒 Security First

- Bitwarden integration for secrets
- No hardcoded credentials
- Environment variable support
- Secure session management

### 📊 Observable

- Execution metrics
- Performance tracking
- Tool usage statistics
- Health monitoring

### 🔌 Extensible

- Easy to add new tools
- Plugin architecture
- Auto-discovery system
- Category-based organization

## 📚 Documentation

### Core Documentation

- [TOOLS_OVERVIEW.md](TOOLS_OVERVIEW.md) - Complete overview and examples
- [BITWARDEN_INTEGRATION.md](BITWARDEN_INTEGRATION.md) - Secret management guide
- Generated tool docs in `schemas/TOOLS.md` (after export)

### Quick Reference

```bash
# List all tools
python -m tools.registry list

# Search for tools
python -m tools.registry search "file"

# Get statistics
python -m tools.registry stats

# Export schemas
python -m tools.registry export openai schemas/openai.json

# Generate docs
python -m tools.registry docs schemas/TOOLS.md
```

## 🛠️ Usage Examples

### Example 1: File Operations

```python
import asyncio
from tools.registry import get_tool

async def file_workflow():
    # Read file
    reader = get_tool("read_file_content")
    result = await reader.execute(file_path="input.txt")
    content = result.data["content"]
    
    # Process text
    counter = get_tool("count_words")
    stats = await counter.execute(text=content)
    print(f"Word count: {stats.data['words']}")
    
    # Write output
    writer = get_tool("write_file_content")
    await writer.execute(
        file_path="output.txt",
        content=f"Stats: {stats.data}"
    )

asyncio.run(file_workflow())
```

### Example 2: Git Operations

```python
async def git_workflow():
    repo = "/path/to/repo"
    
    # Check status
    status = get_tool("git_status")
    result = await status.execute(repository_path=repo)
    
    # Stage changes
    add = get_tool("git_add")
    await add.execute(repository_path=repo, files=["."])
    
    # Commit
    commit = get_tool("git_commit")
    await commit.execute(
        repository_path=repo,
        message="Update files"
    )
    
    # Push
    push = get_tool("git_push")
    await push.execute(repository_path=repo)
```

### Example 3: API Integration

```python
async def api_workflow():
    # Get API key from Bitwarden
    bw_tool = get_tool("bitwarden_get_api_key")
    key_result = await bw_tool.execute(service_name="OpenAI")
    api_key = key_result.data["api_key"]
    
    # Make API request
    http_tool = get_tool("http_post")
    result = await http_tool.execute(
        url="https://api.openai.com/v1/chat/completions",
        json_data={"model": "gpt-4", "messages": [...]},
        headers={"Authorization": f"Bearer {api_key}"}
    )
    
    return result.data
```

### Example 4: Data Processing

```python
async def data_pipeline(csv_data):
    # Parse CSV
    parser = get_tool("parse_csv")
    result = await parser.execute(csv_string=csv_data)
    rows = result.data["rows"]
    
    # Filter data
    filter_tool = get_tool("filter_array")
    result = await filter_tool.execute(
        data=rows,
        field="status",
        operator="equals",
        value="active"
    )
    filtered = result.data["filtered_data"]
    
    # Group by category
    group_tool = get_tool("group_by")
    result = await group_tool.execute(
        data=filtered,
        field="category"
    )
    
    # Aggregate
    agg_tool = get_tool("aggregate_data")
    for category, items in result.data["groups"].items():
        stats = await agg_tool.execute(
            data=items,
            field="amount",
            operations=["sum", "avg", "count"]
        )
        print(f"{category}: {stats.data['results']}")
```

## 🔧 Advanced Usage

### With OpenAI Function Calling

```python
import openai
from tools.registry import export_tool_schemas, get_tool
import json

# Get all tool schemas
functions = export_tool_schemas(format="openai")

# Use with OpenAI
response = openai.ChatCompletion.create(
    model="gpt-4",
    messages=[
        {"role": "user", "content": "Read the file config.json"}
    ],
    functions=functions,
    function_call="auto"
)

# Execute the requested function
if response.choices[0].message.get("function_call"):
    fn_call = response.choices[0].message["function_call"]
    tool = get_tool(fn_call["name"])
    args = json.loads(fn_call["arguments"])
    result = await tool.execute(**args)
```

### Custom Tool Development

```python
from tools.base import BaseTool, ToolCategory, ToolParameter

class MyCustomTool(BaseTool):
    def __init__(self):
        super().__init__(
            name="my_custom_tool",
            category=ToolCategory.DATA,
            description="Does something amazing",
            parameters=[
                ToolParameter(
                    name="input",
                    type="string",
                    description="Input data",
                    required=True
                )
            ],
            tags=["custom", "example"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        input_data = kwargs["input"]
        # Your logic here
        return {
            "result": "processed data"
        }

# Register the tool
from tools.registry import get_registry
registry = get_registry()
registry.register_tool(MyCustomTool())
```

## 🌐 MCP Server Integration

The repository includes MCP server configuration for seamless integration:

### Configuration (`mcp_server_config.json`)

```json
{
  "mcpServers": {
    "bash-tools": {
      "name": "Bash.d Comprehensive Tools Server",
      "command": "python",
      "args": ["-m", "tools.mcp_server"],
      "capabilities": {
        "tools": true
      }
    }
  }
}
```

### Using with MCP Clients

The tool suite integrates with any MCP-compatible client:

- Claude Desktop
- Custom MCP applications
- Agent frameworks supporting MCP

## 📊 Tool Statistics

After setup, view statistics:

```bash
python -m tools.registry stats
```

Example output:
```
Tool Statistics:
  Total Tools: 143
  Categories: 8
  Tools with Tags: 143
  Average Parameters: 2.8

By Category:
  filesystem: 20
  text: 20
  api: 20
  security: 13
  build: 45
  data: 20
  monitoring: 15
```

## 🔐 Security Best Practices

### 1. Use Bitwarden for Secrets

```python
# ✅ Good - retrieve from Bitwarden
bw = get_tool("bitwarden_get_api_key")
result = await bw.execute(service_name="OpenAI")
api_key = result.data["api_key"]

# ❌ Bad - hardcoded
api_key = "sk-xxxxx"  # Never do this!
```

### 2. Environment Variables

```bash
# .env file (never commit)
BW_EMAIL=your-email@example.com
BW_PASSWORD=your-master-password
OPENAI_API_KEY=  # Leave empty, get from Bitwarden
```

### 3. Validate Inputs

All tools automatically validate inputs, but you can do additional checks:

```python
tool = get_tool("run_command")
# Be careful with user input
validated_cmd = validate_command(user_input)
result = await tool.execute(command=validated_cmd)
```

## 🚀 Performance Tips

### 1. Batch Operations

```python
# Run multiple tools concurrently
results = await asyncio.gather(
    tool1.execute(**params1),
    tool2.execute(**params2),
    tool3.execute(**params3)
)
```

### 2. Cache Tool Instances

```python
# Good - reuse tool instance
reader = get_tool("read_file_content")
for file in files:
    result = await reader.execute(file_path=file)

# Less efficient - recreate each time
for file in files:
    reader = get_tool("read_file_content")
    result = await reader.execute(file_path=file)
```

### 3. Export Schemas Once

```bash
# At build time
python tools/export_schemas.py

# Use exported schemas instead of generating each time
cat schemas/openai_tools.json
```

## 🐛 Troubleshooting

### Common Issues

**1. Import errors**
```bash
# Make sure virtual environment is activated
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

**2. Bitwarden CLI not found**
```bash
# Install Bitwarden CLI
npm install -g @bitwarden/cli

# Verify installation
bw --version
```

**3. Permission errors**
```bash
# Make setup script executable
chmod +x setup_tools.sh

# Run with proper permissions
./setup_tools.sh
```

**4. Tool not found**
```python
# List available tools
from tools.registry import get_registry
registry = get_registry()
all_tools = [tool.name for tool in registry.get_all_tools()]
print(all_tools)
```

## 🤝 Contributing

To add new tools:

1. Create tool class inheriting from `BaseTool`
2. Add to appropriate tool module
3. Run export script
4. Test the tool
5. Update documentation

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed guidelines.

## 📝 License

MIT License - See [LICENSE](../LICENSE) for details.

## 🙏 Acknowledgments

- OpenAI for function calling specification
- Model Context Protocol (MCP) community
- Bitwarden for excellent CLI
- All contributors and users

## 📧 Support

- **Documentation**: Check docs/ directory
- **Issues**: GitHub Issues
- **Examples**: See docs/TOOLS_OVERVIEW.md
- **Updates**: Check CHANGELOG.md

---

**Built with ❤️ for AI agents and developers**
