# Comprehensive Tool Suite Overview

## Introduction

This repository contains a comprehensive suite of 130+ OpenAI-compatible tools designed for AI agents. All tools follow the Model Context Protocol (MCP) standard and can be exported in multiple formats.

## Quick Start

### Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Export tool schemas
cd tools
python export_schemas.py
```

### Using the Tool Registry

```python
from tools.registry import get_registry, get_tool

# Get all tools
registry = get_registry()
all_tools = registry.get_all_tools()

# Get a specific tool
file_reader = get_tool("read_file_content")

# Execute a tool
result = await file_reader.execute(file_path="/path/to/file.txt")
print(result.data)
```

### Export Schemas

```bash
# Export in OpenAI format
python -m tools.registry export openai schemas/openai_tools.json

# Export in MCP format
python -m tools.registry export mcp schemas/mcp_tools.json

# Export in generic JSON format
python -m tools.registry export json schemas/tools.json

# Generate documentation
python -m tools.registry docs docs/TOOLS.md
```

## Tool Categories

### 1. File System Operations (20 tools)

Tools for comprehensive file and directory operations:

- `read_file_content` - Read file content
- `write_file_content` - Write to file
- `append_file_content` - Append to file
- `list_directory` - List directory contents
- `create_directory` - Create directories
- `delete_file` - Delete files
- `delete_directory` - Delete directories
- `copy_file` - Copy files
- `move_file` - Move/rename files
- `get_file_info` - Get file metadata
- `search_files` - Search for files
- `read_json_file` - Read JSON files
- `write_json_file` - Write JSON files
- `get_directory_size` - Calculate directory size
- `check_path_exists` - Check path existence
- `create_symlink` - Create symbolic links
- `change_permissions` - Change file permissions
- `get_working_directory` - Get current directory
- `change_working_directory` - Change directory

### 2. Text Processing (20 tools)

Comprehensive text manipulation and analysis:

- `count_words` - Count words, chars, lines
- `find_replace` - Find and replace text
- `extract_urls` - Extract URLs from text
- `extract_emails` - Extract email addresses
- `split_text` - Split text by delimiter
- `join_text` - Join text parts
- `trim_whitespace` - Trim whitespace
- `change_case` - Change text case
- `hash_text` - Generate text hash
- `base64_encode` - Encode to Base64
- `base64_decode` - Decode from Base64
- `remove_duplicate_lines` - Remove duplicates
- `sort_lines` - Sort text lines
- `reverse_text` - Reverse text
- `wrap_text` - Wrap text to width
- `extract_numbers` - Extract numbers
- `slugify_text` - Convert to URL slug
- `truncate_text` - Truncate text

### 3. API & HTTP Operations (20 tools)

HTTP client and API interaction tools:

- `http_get` - HTTP GET request
- `http_post` - HTTP POST request
- `http_put` - HTTP PUT request
- `http_delete` - HTTP DELETE request
- `http_patch` - HTTP PATCH request
- `parse_url` - Parse URL components
- `build_url` - Build URL from parts
- `download_file` - Download file from URL
- `check_url_status` - Check URL accessibility
- `make_webhook_call` - Call webhook
- `fetch_json` - Fetch and parse JSON
- `encode_url_params` - Encode URL parameters
- `decode_url_params` - Decode URL parameters
- `validate_json_schema` - Validate JSON against schema
- `rate_limited_request` - Rate-limited HTTP request
- `retry_request` - HTTP request with retry

### 4. Bitwarden Secret Management (13 tools)

Secure credential and secret management:

- `bitwarden_login` - Login to Bitwarden
- `bitwarden_unlock` - Unlock vault
- `bitwarden_search_items` - Search vault items
- `bitwarden_get_item` - Get item details
- `bitwarden_get_api_key` - Get API keys
- `bitwarden_get_password` - Get passwords
- `bitwarden_get_username` - Get usernames
- `bitwarden_get_credentials` - Get username+password
- `bitwarden_get_notes` - Get secure notes
- `bitwarden_list_folders` - List folders
- `bitwarden_sync_vault` - Sync vault
- `bitwarden_check_status` - Check CLI status

See [BITWARDEN_INTEGRATION.md](BITWARDEN_INTEGRATION.md) for detailed usage.

### 5. Git & Version Control (15 tools)

Complete Git operation suite:

- `git_init` - Initialize repository
- `git_clone` - Clone repository
- `git_status` - Get status
- `git_add` - Stage files
- `git_commit` - Commit changes
- `git_push` - Push to remote
- `git_pull` - Pull from remote
- `git_branch` - Manage branches
- `git_checkout` - Switch branches
- `git_log` - View history
- `git_diff` - Show differences
- `git_tag` - Manage tags
- `git_remote` - Manage remotes
- `git_stash` - Stash changes
- `git_merge` - Merge branches

### 6. Data Manipulation (20 tools)

Data transformation and processing:

- `parse_json` - Parse JSON strings
- `stringify_json` - Convert to JSON
- `parse_csv` - Parse CSV data
- `convert_to_csv` - Convert to CSV
- `filter_array` - Filter array elements
- `map_array` - Transform array
- `sort_array` - Sort array
- `group_by` - Group by field
- `aggregate_data` - Calculate aggregates
- `merge_arrays` - Merge multiple arrays
- `flatten_array` - Flatten nested arrays
- `unique_array` - Get unique elements
- `chunk_array` - Split into chunks
- `transpose_matrix` - Transpose 2D array
- `pivot_data` - Pivot data table
- `validate_schema` - Validate data schema
- `convert_date_format` - Convert date formats
- `calculate_time_delta` - Calculate date differences

### 7. Docker & Container Management (15 tools)

Docker and container operations:

- `docker_list_containers` - List containers
- `docker_run_container` - Run container
- `docker_stop_container` - Stop container
- `docker_remove_container` - Remove container
- `docker_logs` - Get container logs
- `docker_inspect` - Inspect container/image
- `docker_list_images` - List images
- `docker_pull_image` - Pull image
- `docker_build_image` - Build image
- `docker_compose_up` - Start Compose services
- `docker_compose_down` - Stop Compose services
- `docker_exec` - Execute in container
- `docker_stats` - Get resource stats

## Architecture

### Base Tool Class

All tools inherit from `BaseTool` which provides:

- Parameter validation
- Multiple schema export formats (OpenAI, MCP, JSON)
- Async execution
- Result standardization
- Error handling

```python
class BaseTool(BaseModel):
    # Core identity
    name: str
    category: ToolCategory
    description: str
    version: str
    
    # Parameters and configuration
    parameters: List[ToolParameter]
    
    # MCP and OpenAI compatibility
    mcp_compatible: bool = True
    openai_compatible: bool = True
    
    # Methods
    async def execute(**kwargs) -> ToolResult
    def get_openai_function_schema() -> Dict
    def get_mcp_schema() -> Dict
```

### Tool Registry

The `ToolRegistry` provides:

- Auto-discovery of tools
- Tool lookup by name or category
- Schema generation and export
- Documentation generation
- Statistics and analytics

### MCP Server Integration

The repository includes MCP server configuration for integration with:

- GitHub MCP Server (official)
- Filesystem MCP Server (official)
- Custom bash.d tools server

Configuration file: `mcp_server_config.json`

## Usage Examples

### Example 1: Read and Process a File

```python
import asyncio
from tools.registry import get_tool

async def process_file():
    # Get tools
    read_tool = get_tool("read_file_content")
    word_count_tool = get_tool("count_words")
    
    # Read file
    result = await read_tool.execute(file_path="document.txt")
    content = result.data["content"]
    
    # Count words
    stats = await word_count_tool.execute(text=content)
    print(f"Words: {stats.data['words']}")
    print(f"Lines: {stats.data['lines']}")

asyncio.run(process_file())
```

### Example 2: Git Workflow

```python
async def git_workflow():
    repo_path = "/path/to/repo"
    
    # Check status
    status_tool = get_tool("git_status")
    status = await status_tool.execute(repository_path=repo_path)
    
    # Add files
    add_tool = get_tool("git_add")
    await add_tool.execute(repository_path=repo_path, files=["."])
    
    # Commit
    commit_tool = get_tool("git_commit")
    await commit_tool.execute(
        repository_path=repo_path,
        message="Update files"
    )
    
    # Push
    push_tool = get_tool("git_push")
    await push_tool.execute(repository_path=repo_path)
```

### Example 3: Bitwarden Secrets

```python
async def get_api_keys():
    # Unlock vault
    unlock_tool = get_tool("bitwarden_unlock")
    result = await unlock_tool.execute()
    session_token = result.data["session_token"]
    
    # Get OpenAI API key
    api_key_tool = get_tool("bitwarden_get_api_key")
    result = await api_key_tool.execute(
        service_name="OpenAI",
        session_token=session_token
    )
    openai_key = result.data["api_key"]
    
    return openai_key
```

### Example 4: Data Processing Pipeline

```python
async def process_data(csv_data):
    # Parse CSV
    parse_tool = get_tool("parse_csv")
    result = await parse_tool.execute(csv_string=csv_data)
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
    groups = result.data["groups"]
    
    # Aggregate
    agg_tool = get_tool("aggregate_data")
    for category, items in groups.items():
        result = await agg_tool.execute(
            data=items,
            field="amount",
            operations=["sum", "avg", "count"]
        )
        print(f"{category}: {result.data['results']}")
```

## OpenAI Function Calling

All tools are compatible with OpenAI's function calling:

```python
import openai
from tools.registry import export_tool_schemas

# Get tool schemas in OpenAI format
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

# Execute the function
if response.choices[0].message.get("function_call"):
    function_name = response.choices[0].message["function_call"]["name"]
    arguments = json.loads(response.choices[0].message["function_call"]["arguments"])
    
    tool = get_tool(function_name)
    result = await tool.execute(**arguments)
```

## Best Practices

### 1. Error Handling

Always check the `success` field in results:

```python
result = await tool.execute(**params)
if result.success:
    data = result.data
else:
    error = result.error
    # Handle error
```

### 2. Parameter Validation

Tools automatically validate parameters, but you can check before calling:

```python
tool = get_tool("some_tool")
tool._validate_parameters({"param1": "value1"})
```

### 3. Async Execution

All tools use async execution for better performance:

```python
# Single tool
result = await tool.execute(**params)

# Multiple tools concurrently
results = await asyncio.gather(
    tool1.execute(**params1),
    tool2.execute(**params2),
    tool3.execute(**params3)
)
```

### 4. Schema Export

Export schemas once and reuse:

```bash
# Export at build time
python tools/export_schemas.py

# Use exported schemas
cat schemas/openai_tools.json
```

## Contributing

To add a new tool:

1. Create a new tool class inheriting from `BaseTool`
2. Implement `_execute_impl` method
3. Add to appropriate tool module
4. Tool will be auto-discovered by registry
5. Re-export schemas

Example:

```python
class MyNewTool(BaseTool):
    def __init__(self):
        super().__init__(
            name="my_new_tool",
            category=ToolCategory.DATA,
            description="Description of what it does",
            parameters=[
                ToolParameter(
                    name="input",
                    type="string",
                    description="Input parameter",
                    required=True
                )
            ],
            tags=["tag1", "tag2"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        input_value = kwargs["input"]
        # Do something
        return {
            "result": "output"
        }
```

## Performance Considerations

- Tools use async execution for I/O operations
- Registry caches tool instances
- Schema export is done once at build time
- Bitwarden session tokens are reused
- HTTP requests support rate limiting and retries

## Security

- Bitwarden integration for secure secrets
- No secrets stored in code
- Environment variable support
- Session token management
- Input validation on all tools

## Future Enhancements

- [ ] Database operation tools (SQL, NoSQL)
- [ ] Cloud provider tools (AWS, Azure, GCP)
- [ ] Testing and QA tools
- [ ] Code analysis tools
- [ ] System monitoring tools
- [ ] Kubernetes tools
- [ ] Terraform tools
- [ ] CI/CD integration tools

## License

MIT License - See LICENSE file for details

## Support

For issues or questions:
- Check the documentation
- Review tool schemas
- Check examples
- Open an issue on GitHub
