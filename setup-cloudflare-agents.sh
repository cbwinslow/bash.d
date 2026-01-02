#!/bin/bash

# Cloudflare Agents Integration Script for Agent Zero
# This script sets up Cloudflare Agents to enhance Agent Zero capabilities

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
AGENT_NAME="agent-zero-enhanced"
WORKER_NAME="agent-zero-worker"
NAMESPACE="agent-zero"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Node.js and npm
install_nodejs() {
    print_status "Checking Node.js installation..."
    
    if command_exists node && command_exists npm; then
        NODE_VERSION=$(node --version | cut -d'v' -f2)
        print_success "Node.js $NODE_VERSION is already installed!"
        return
    fi
    
    print_status "Installing Node.js..."
    
    # Detect OS and install Node.js
    if command_exists apt-get; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif command_exists yum; then
        curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
        sudo yum install -y nodejs
    elif command_exists brew; then
        brew install node
    else
        print_error "Cannot install Node.js automatically. Please install it manually."
        echo "Visit: https://nodejs.org/"
        exit 1
    fi
    
    print_success "Node.js installed successfully!"
}

# Function to install Wrangler CLI
install_wrangler() {
    print_status "Installing Wrangler CLI..."
    
    if command_exists wrangler; then
        print_success "Wrangler CLI is already installed!"
        return
    fi
    
    npm install -g wrangler
    
    print_success "Wrangler CLI installed successfully!"
}

# Function to authenticate with Cloudflare
authenticate_cloudflare() {
    print_status "Authenticating with Cloudflare..."
    
    if wrangler whoami > /dev/null 2>&1; then
        print_success "Already authenticated with Cloudflare!"
        return
    fi
    
    print_status "Please login to your Cloudflare account:"
    wrangler auth login
    
    print_success "Authenticated with Cloudflare!"
}

# Function to create Cloudflare Agent project
create_agent_project() {
    print_status "Creating Cloudflare Agent project..."
    
    # Create project directory
    mkdir -p "$AGENT_NAME"
    cd "$AGENT_NAME"
    
    # Initialize npm project
    npm init -y
    
    # Install dependencies
    npm install agents
    
    # Create agent class
    cat > src/index.js << 'EOF'
import { Agent } from "agents";

export class AgentZeroEnhanced extends Agent {
  // Agent initialization
  async onStartup() {
    console.log("Agent Zero Enhanced starting up...");
    await this.setState({
      status: "ready",
      capabilities: ["reasoning", "web_browsing", "code_execution"],
      agent_zero_url: process.env.AGENT_ZERO_URL || "http://localhost:50001"
    });
  }

  // Handle incoming messages from Agent Zero
  async onMessage(message) {
    console.log("Received message:", message);
    
    // Process the message and potentially enhance it
    const enhanced = await this.enhanceMessage(message);
    
    // Send back to Agent Zero or handle internally
    return enhanced;
  }

  // Enhance messages with additional capabilities
  async enhanceMessage(message) {
    const state = await this.getState();
    
    // Add reasoning capabilities
    if (message.type === "task") {
      const reasoning = await this.performReasoning(message.content);
      message.enhanced_reasoning = reasoning;
    }
    
    // Add web browsing capabilities if needed
    if (message.requires_web_search) {
      const searchResults = await this.performWebSearch(message.query);
      message.search_results = searchResults;
    }
    
    return message;
  }

  // Perform reasoning using Workers AI
  async performReasoning(content) {
    try {
      const response = await this.ai.run("@cf/meta/llama-3.1-8b-instruct", {
        messages: [
          {
            role: "system",
            content: "You are an AI reasoning assistant. Analyze the following task and provide step-by-step reasoning."
          },
          {
            role: "user",
            content: content
          }
        ]
      });
      
      return response.response;
    } catch (error) {
      console.error("Reasoning failed:", error);
      return "Reasoning unavailable";
    }
  }

  // Perform web search
  async performWebSearch(query) {
    try {
      // This would integrate with a search API
      return {
        query: query,
        results: ["Search result 1", "Search result 2"],
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error("Web search failed:", error);
      return { error: "Search unavailable" };
    }
  }

  // Health check endpoint
  async onFetch(request) {
    const state = await this.getState();
    
    if (request.url.endsWith('/health')) {
      return new Response(JSON.stringify({
        status: state.status,
        capabilities: state.capabilities,
        timestamp: new Date().toISOString()
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    return new Response("Agent Zero Enhanced API");
  }
}

// Export the agent for Durable Objects
export default {
  async fetch(request, env) {
    const id = env.AGENT_ZERO_ENHANCED.idFromName("default");
    const obj = env.AGENT_ZERO_ENHANCED.get(id);
    return obj.fetch(request);
  }
};
EOF
    
    # Create wrangler.toml configuration
    cat > wrangler.toml << EOF
name = "$WORKER_NAME"
main = "src/index.js"
compatibility_date = "2024-01-01"

[env.production]
vars = { ENVIRONMENT = "production" }

[[env.production.durable_objects.bindings]]
name = "AGENT_ZERO_ENHANCED"
class_name = "AgentZeroEnhanced"

[[env.production.migrations]]
tag = "v1"
new_sqlite_classes = ["AgentZeroEnhanced"]

[env.development]
vars = { ENVIRONMENT = "development" }

[[env.development.durable_objects.bindings]]
name = "AGENT_ZERO_ENHANCED"
class_name = "AgentZeroEnhanced"

[[env.development.migrations]]
tag = "v1"
new_sqlite_classes = ["AgentZeroEnhanced"]
EOF
    
    # Create package.json scripts
    npm pkg set scripts.dev="wrangler dev"
    npm pkg set scripts.deploy="wrangler deploy"
    npm pkg set scripts.tail="wrangler tail"
    
    print_success "Cloudflare Agent project created!"
}

# Function to create integration bridge
create_integration_bridge() {
    print_status "Creating integration bridge between Agent Zero and Cloudflare Agents..."
    
    # Create bridge service
    cat > bridge.js << 'EOF'
// Agent Zero + Cloudflare Agents Integration Bridge
const WebSocket = require('ws');

class AgentZeroBridge {
  constructor(cloudflareAgentUrl, agentZeroUrl) {
    this.cloudflareAgentUrl = cloudflareAgentUrl;
    this.agentZeroUrl = agentZeroUrl;
    this.ws = null;
    this.reconnectInterval = 5000;
  }

  // Connect to Cloudflare Agent
  async connect() {
    try {
      this.ws = new WebSocket(this.cloudflareAgentUrl);
      
      this.ws.on('open', () => {
        console.log('Connected to Cloudflare Agent');
        this.startHeartbeat();
      });
      
      this.ws.on('message', async (data) => {
        const message = JSON.parse(data);
        await this.handleMessage(message);
      });
      
      this.ws.on('close', () => {
        console.log('Disconnected from Cloudflare Agent');
        setTimeout(() => this.connect(), this.reconnectInterval);
      });
      
      this.ws.on('error', (error) => {
        console.error('WebSocket error:', error);
      });
      
    } catch (error) {
      console.error('Connection failed:', error);
      setTimeout(() => this.connect(), this.reconnectInterval);
    }
  }

  // Handle incoming messages
  async handleMessage(message) {
    console.log('Received message from Cloudflare Agent:', message);
    
    // Forward to Agent Zero or process
    switch (message.type) {
      case 'enhance_task':
        await this.enhanceAgentZeroTask(message);
        break;
      case 'reasoning_request':
        await this.performReasoning(message);
        break;
      case 'web_search':
        await this.performWebSearch(message);
        break;
      default:
        console.log('Unknown message type:', message.type);
    }
  }

  // Enhance Agent Zero tasks
  async enhanceAgentZeroTask(message) {
    try {
      const response = await fetch(`${this.agentZeroUrl}/api/enhance`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(message)
      });
      
      const result = await response.json();
      this.sendToCloudflareAgent({
        type: 'task_enhanced',
        original: message,
        enhanced: result
      });
      
    } catch (error) {
      console.error('Failed to enhance task:', error);
    }
  }

  // Send message to Cloudflare Agent
  sendToCloudflareAgent(message) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(message));
    }
  }

  // Start heartbeat
  startHeartbeat() {
    setInterval(() => {
      this.sendToCloudflareAgent({
        type: 'heartbeat',
        timestamp: new Date().toISOString()
      });
    }, 30000);
  }
}

// Start the bridge
const bridge = new AgentZeroBridge(
  process.env.CLOUDFLARE_AGENT_URL || 'wss://agent-zero-enhanced.your-subdomain.workers.dev',
  process.env.AGENT_ZERO_URL || 'http://localhost:50001'
);

bridge.connect();
EOF
    
    # Create bridge package.json
    cat > bridge-package.json << 'EOF'
{
  "name": "agent-zero-bridge",
  "version": "1.0.0",
  "description": "Bridge between Agent Zero and Cloudflare Agents",
  "main": "bridge.js",
  "scripts": {
    "start": "node bridge.js",
    "dev": "nodemon bridge.js"
  },
  "dependencies": {
    "ws": "^8.14.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.0"
  }
}
EOF
    
    print_success "Integration bridge created!"
}

# Function to deploy Cloudflare Agent
deploy_agent() {
    print_status "Deploying Cloudflare Agent..."
    
    cd "$AGENT_NAME"
    
    # Deploy to Cloudflare
    wrangler deploy
    
    print_success "Cloudflare Agent deployed!"
    
    # Get the deployed URL
    WORKER_URL=$(wrangler whoami 2>/dev/null | grep -o 'https://[^[:space:]]*' | head -1 || echo "")
    if [ -z "$WORKER_URL" ]; then
        WORKER_URL="https://$WORKER_NAME.your-subdomain.workers.dev"
    fi
    
    print_status "Cloudflare Agent URL: $WORKER_URL"
    
    # Save URL to environment file
    echo "CLOUDFLARE_AGENT_URL=$WORKER_URL" > ../.env.cloudflare
}

# Function to create monitoring dashboard
create_monitoring() {
    print_status "Creating monitoring configuration..."
    
    # Create monitoring script
    cat > monitor.sh << 'EOF'
#!/bin/bash

# Agent Zero + Cloudflare Agents Monitoring Script

CLOUDFLARE_AGENT_URL=${CLOUDFLARE_AGENT_URL:-"https://agent-zero-enhanced.your-subdomain.workers.dev"}
AGENT_ZERO_URL=${AGENT_ZERO_URL:-"http://localhost:50001"}

echo "=== Agent Zero + Cloudflare Agents Monitoring ==="
echo "Timestamp: $(date)"
echo

# Check Cloudflare Agent health
echo "Checking Cloudflare Agent..."
if curl -s "$CLOUDFLARE_AGENT_URL/health" | jq .; then
    echo "✅ Cloudflare Agent is healthy"
else
    echo "❌ Cloudflare Agent is down"
fi
echo

# Check Agent Zero health
echo "Checking Agent Zero..."
if curl -s "$AGENT_ZERO_URL/health" > /dev/null; then
    echo "✅ Agent Zero is healthy"
else
    echo "❌ Agent Zero is down"
fi
echo

# Check Docker containers
echo "Checking Docker containers..."
docker ps --filter "name=agent-zero" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo

# Check system resources
echo "System Resources:"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
echo
EOF
    
    chmod +x monitor.sh
    
    print_success "Monitoring script created!"
}

# Function to show usage information
show_usage() {
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  install     - Install all dependencies"
    echo "  project     - Create Cloudflare Agent project"
    echo "  bridge      - Create integration bridge"
    echo "  deploy      - Deploy Cloudflare Agent"
    echo "  monitor     - Create monitoring tools"
    echo "  full        - Run complete setup"
    echo "  help        - Show this help message"
}

# Main function
main() {
    echo "=========================================="
    echo "Cloudflare Agents Integration for Agent Zero"
    echo "=========================================="
    echo
    
    case "${1:-full}" in
        "install")
            install_nodejs
            install_wrangler
            ;;
        "project")
            create_agent_project
            ;;
        "bridge")
            create_integration_bridge
            ;;
        "deploy")
            authenticate_cloudflare
            deploy_agent
            ;;
        "monitor")
            create_monitoring
            ;;
        "full")
            install_nodejs
            install_wrangler
            authenticate_cloudflare
            create_agent_project
            create_integration_bridge
            deploy_agent
            create_monitoring
            echo
            print_success "Cloudflare Agents integration setup completed!"
            echo
            echo "Next steps:"
            echo "1. Start the bridge: npm install && node bridge.js"
            echo "2. Monitor the system: ./monitor.sh"
            echo "3. Test the integration"
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"