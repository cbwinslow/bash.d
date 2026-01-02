#!/bin/bash

# Enhanced Cloudflare Features Script for Agent Zero
# This script adds advanced Cloudflare features to enhance Agent Zero deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
DOMAIN=""
ZONE_ID=""
API_TOKEN=""
AGENT_ZERO_URL="http://localhost:50001"

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

# Function to load configuration
load_config() {
    if [ -f .env ]; then
        source .env
        DOMAIN=${CLOUDFLARE_DOMAIN:-$DOMAIN}
        AGENT_ZERO_URL=${AGENT_ZERO_URL:-"http://localhost:50001"}
    fi
    
    if [ -f .env.cloudflare ]; then
        source .env.cloudflare
    fi
}

# Function to validate configuration
validate_config() {
    if [ -z "$DOMAIN" ]; then
        print_error "Domain not configured. Please set CLOUDFLARE_DOMAIN in .env file."
        exit 1
    fi
    
    if [ -z "$API_TOKEN" ]; then
        print_error "Cloudflare API token not configured."
        print_status "Please set CLOUDFLARE_API_TOKEN in .env file or as environment variable."
        exit 1
    fi
    
    # Get Zone ID
    ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" | jq -r '.result[0].id')
    
    if [ -z "$ZONE_ID" ] || [ "$ZONE_ID" = "null" ]; then
        print_error "Could not retrieve Zone ID for domain: $DOMAIN"
        print_error "Please verify your domain and API token permissions."
        exit 1
    fi
    
    print_success "Configuration validated for domain: $DOMAIN"
    print_status "Zone ID: $ZONE_ID"
}

# Function to setup AI Gateway
setup_ai_gateway() {
    print_status "Setting up Cloudflare AI Gateway..."
    
    # Create AI Gateway configuration
    GATEWAY_CONFIG=$(cat << EOF
{
    "name": "agent-zero-gateway",
    "description": "AI Gateway for Agent Zero deployment",
    "enabled": true,
    "settings": {
        "cache": {
            "enabled": true,
            "ttl": 3600
        },
        "rate_limiting": {
            "enabled": true,
            "requests_per_minute": 100
        },
        "request_logging": {
            "enabled": true,
            "log_body": false
        },
        "model_fallback": {
            "enabled": true,
            "fallback_models": ["gpt-3.5-turbo", "claude-instant"]
        }
    }
}
EOF
    )
    
    # Create AI Gateway
    GATEWAY_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/ai-gateway/configurations" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$GATEWAY_CONFIG")
    
    GATEWAY_ID=$(echo "$GATEWAY_RESPONSE" | jq -r '.result.id')
    
    if [ -n "$GATEWAY_ID" ] && [ "$GATEWAY_ID" != "null" ]; then
        print_success "AI Gateway created with ID: $GATEWAY_ID"
        echo "AI_GATEWAY_ID=$GATEWAY_ID" >> .env.cloudflare
        echo "AI_GATEWAY_URL=https://gateway.ai.cloudflare.com/v1/$GATEWAY_ID" >> .env.cloudflare
    else
        print_error "Failed to create AI Gateway"
        echo "Response: $GATEWAY_RESPONSE"
    fi
}

# Function to setup Vectorize for memory
setup_vectorize() {
    print_status "Setting up Cloudflare Vectorize for Agent Zero memory..."
    
    # Create Vectorize index
    VECTORIZE_CONFIG=$(cat << EOF
{
    "name": "agent-zero-memory",
    "description": "Vector database for Agent Zero memory and knowledge",
    "dimensions": 1536,
    "metric": "cosine",
    "binding": "AGENT_ZERO_MEMORY"
}
EOF
    )
    
    # Create Vectorize index
    VECTORIZE_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/vectorize/indexes" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$VECTORIZE_CONFIG")
    
    VECTORIZE_ID=$(echo "$VECTORIZE_RESPONSE" | jq -r '.result.id')
    
    if [ -n "$VECTORIZE_ID" ] && [ "$VECTORIZE_ID" != "null" ]; then
        print_success "Vectorize index created with ID: $VECTORIZE_ID"
        echo "VECTORIZE_ID=$VECTORIZE_ID" >> .env.cloudflare
    else
        print_error "Failed to create Vectorize index"
        echo "Response: $VECTORIZE_RESPONSE"
    fi
}

# Function to setup Workers AI integration
setup_workers_ai() {
    print_status "Setting up Workers AI integration..."
    
    # Create Worker for AI processing
    WORKER_SCRIPT=$(cat << 'EOF'
// Agent Zero Workers AI Integration Worker
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    // Handle different endpoints
    if (url.pathname === '/enhance') {
      return await enhanceRequest(request, env);
    } else if (url.pathname === '/reason') {
      return await performReasoning(request, env);
    } else if (url.pathname === '/embed') {
      return await createEmbedding(request, env);
    }
    
    return new Response('Agent Zero AI Worker', { status: 200 });
  }
};

async function enhanceRequest(request, env) {
  try {
    const { task, context } = await request.json();
    
    // Use Workers AI to enhance the task
    const aiResponse = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
      messages: [
        {
          role: 'system',
          content: 'You are an AI assistant that enhances user tasks for Agent Zero. Provide step-by-step guidance and suggest improvements.'
        },
        {
          role: 'user',
          content: `Task: ${task}\nContext: ${context || 'None'}\n\nPlease enhance this task with detailed steps and suggestions.`
        }
      ]
    });
    
    return new Response(JSON.stringify({
      original_task: task,
      enhanced_task: aiResponse.response,
      suggestions: extractSuggestions(aiResponse.response)
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

async function performReasoning(request, env) {
  try {
    const { problem, options } = await request.json();
    
    const reasoningResponse = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
      messages: [
        {
          role: 'system',
          content: 'You are a reasoning engine. Analyze problems and provide logical conclusions.'
        },
        {
          role: 'user',
          content: `Problem: ${problem}\nOptions: ${JSON.stringify(options)}\n\nProvide detailed reasoning and recommend the best solution.`
        }
      ]
    });
    
    return new Response(JSON.stringify({
      problem,
      reasoning: reasoningResponse.response,
      confidence: calculateConfidence(reasoningResponse.response)
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

async function createEmbedding(request, env) {
  try {
    const { text } = await request.json();
    
    const embeddingResponse = await env.AI.run('@cf/baai/bge-base-en-v1.5', {
      text: text
    });
    
    return new Response(JSON.stringify({
      text,
      embedding: embeddingResponse.data[0],
      dimensions: embeddingResponse.data[0].length
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

function extractSuggestions(response) {
  // Extract actionable suggestions from AI response
  const suggestions = [];
  const lines = response.split('\n');
  
  lines.forEach(line => {
    if (line.includes('suggest') || line.includes('recommend') || line.includes('should')) {
      suggestions.push(line.trim());
    }
  });
  
  return suggestions;
}

function calculateConfidence(response) {
  // Simple confidence calculation based on response characteristics
  const wordCount = response.split(' ').length;
  const hasNumbers = /\d/.test(response);
  const hasStructure = response.includes('\n') || response.includes('1.') || response.includes('-');
  
  let confidence = 0.5; // Base confidence
  
  if (wordCount > 50) confidence += 0.2;
  if (hasNumbers) confidence += 0.1;
  if (hasStructure) confidence += 0.2;
  
  return Math.min(confidence, 1.0);
}
EOF
    )
    
    # Create Worker directory and files
    mkdir -p agent-zero-ai-worker
    echo "$WORKER_SCRIPT" > agent-zero-ai-worker/index.js
    
    # Create wrangler.toml
    cat > agent-zero-ai-worker/wrangler.toml << EOF
name = "agent-zero-ai-worker"
main = "index.js"
compatibility_date = "2024-01-01"

[env.production.ai]
binding = "AI"

[env.production.vectorize]
binding = "AGENT_ZERO_MEMORY"
index_name = "agent-zero-memory"
EOF
    
    print_success "Workers AI integration created in agent-zero-ai-worker directory"
}

# Function to setup Cloudflare Access
setup_cloudflare_access() {
    print_status "Setting up Cloudflare Access for Zero Trust security..."
    
    # Create Access policy
    ACCESS_POLICY=$(cat << EOF
{
    "name": "Agent Zero Access Policy",
    "description": "Zero Trust access policy for Agent Zero",
    "precedence": 1,
    "decision": "allow",
    "require": {
        "auth_method": "email"
    },
    "include": [
        {
            "email": {
                "email": ["*@$DOMAIN"]
            }
        }
    ]
}
EOF
    )
    
    # Create Access application
    ACCESS_APP_CONFIG=$(cat << EOF
{
    "name": "Agent Zero",
    "domain": "agent-zero.$DOMAIN",
    "type": "self_hosted",
    "policies": [
        {
            "name": "Agent Zero Access Policy",
            "decision": "allow",
            "require": {
                "auth_method": "email"
            }
        }
    ],
    "self_hosted_domains": [
        "agent-zero.$DOMAIN"
    ],
    "cookie_lifespan": 86400,
    "session_duration": 86400
}
EOF
    )
    
    # Create Access application
    ACCESS_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/access/apps" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$ACCESS_APP_CONFIG")
    
    ACCESS_APP_ID=$(echo "$ACCESS_RESPONSE" | jq -r '.result.id')
    
    if [ -n "$ACCESS_APP_ID" ] && [ "$ACCESS_APP_ID" != "null" ]; then
        print_success "Cloudflare Access application created"
        print_status "Application ID: $ACCESS_APP_ID"
        print_status "Access URL: https://agent-zero.$DOMAIN"
        echo "CLOUDFLARE_ACCESS_APP_ID=$ACCESS_APP_ID" >> .env.cloudflare
    else
        print_error "Failed to create Cloudflare Access application"
        echo "Response: $ACCESS_RESPONSE"
    fi
}

# Function to setup Rate Limiting
setup_rate_limiting() {
    print_status "Setting up rate limiting rules..."
    
    # Create rate limiting rule
    RATE_LIMIT_RULE=$(cat << EOF
{
    "description": "Agent Zero rate limiting",
    "expression": "(http.request.uri.path contains \"/api\")",
    "action": "timeout",
    "ratelimit": {
        "characteristics": [
            "cf.colo.id",
            "ip.src"
        ],
        "period": 60,
        "requests_per_period": 100,
        "timeout": 300
    }
}
EOF
    )
    
    # Create rate limiting rule
    RATE_LIMIT_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$RATE_LIMIT_RULE")
    
    if echo "$RATE_LIMIT_RESPONSE" | jq -e '.result.id' > /dev/null; then
        print_success "Rate limiting rule created"
    else
        print_error "Failed to create rate limiting rule"
        echo "Response: $RATE_LIMIT_RESPONSE"
    fi
}

# Function to setup Page Rules for caching
setup_page_rules() {
    print_status "Setting up page rules for performance optimization..."
    
    # Create page rules for static assets
    PAGE_RULES=(
        {
            "targets": [
                {
                    "target": "url",
                    "constraint": {
                        "operator": "matches",
                        "value": "*$DOMAIN/static/*"
                    }
                }
            ],
            "actions": [
                {
                    "id": "cache_level",
                    "value": "cache_everything"
                },
                {
                    "id": "edge_cache_ttl",
                    "value": 86400
                }
            ]
        }
        {
            "targets": [
                {
                    "target": "url",
                    "constraint": {
                        "operator": "matches",
                        "value": "*$DOMAIN/api/*"
                    }
                }
            ],
            "actions": [
                {
                    "id": "cache_level",
                    "value": "cache_everything"
                },
                {
                    "id": "edge_cache_ttl",
                    "value": 300
                }
            ]
        }
    )
    
    for rule in "${PAGE_RULES[@]}"; do
        PAGE_RULE_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/pagerules" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$rule")
        
        if echo "$PAGE_RULE_RESPONSE" | jq -e '.result.id' > /dev/null; then
            print_success "Page rule created"
        else
            print_error "Failed to create page rule"
            echo "Response: $PAGE_RULE_RESPONSE"
        fi
    done
}

# Function to setup Analytics and Monitoring
setup_analytics() {
    print_status "Setting up enhanced analytics and monitoring..."
    
    # Create GraphQL analytics query
    ANALYTICS_QUERY=$(cat << 'EOF'
query AgentZeroAnalytics($zoneTag: string!, $since: string!, $until: string!) {
  viewer {
    zones(filter: {zoneTag: $zoneTag}) {
      httpRequests1dGroups(
        filter: {since: $since, until: $until}
        orderBy: [datetime_ASC]
        limit: 30
      ) {
        dimensions {
          datetime
        }
        sum {
          bytes
          requests
          pageViews
          threats
        }
        avg {
          sampleInterval
        }
      }
      firewallEventsAdaptiveGroups(
        filter: {since: $since, until: $until}
        limit: 10
        orderBy: [eventsCount_DESC]
      ) {
        dimensions {
          action
          clientIPASNDescription
          clientCountryName
        }
        count
      }
    }
  }
}
EOF
    )
    
    # Create analytics script
    cat > analytics.sh << EOF
#!/bin/bash

# Agent Zero Analytics Script
ZONE_ID="$ZONE_ID"
API_TOKEN="$API_TOKEN"
DOMAIN="$DOMAIN"

# Get analytics for the last 7 days
SINCE=\$(date -d '7 days ago' -Iseconds)
UNTIL=\$(date -Iseconds)

# Run GraphQL query
curl -s -X POST "https://api.cloudflare.com/client/v4/graphql" \\
  -H "Authorization: Bearer \$API_TOKEN" \\
  -H "Content-Type: application/json" \\
  -d '{
    "query": "$ANALYTICS_QUERY",
    "variables": {
      "zoneTag": "\$ZONE_ID",
      "since": "\$SINCE",
      "until": "\$UNTIL"
    }
  }' | jq .
EOF
    
    chmod +x analytics.sh
    print_success "Analytics script created: analytics.sh"
}

# Function to setup Web Application Firewall (WAF)
setup_waf() {
    print_status "Setting up Web Application Firewall rules..."
    
    # Create WAF rules for Agent Zero
    WAF_RULES=(
        {
            "description": "Block SQL Injection",
            "expression": "(http.request.uri.query contains \"SELECT\" or http.request.uri.query contains \"INSERT\" or http.request.uri.query contains \"DELETE\" or http.request.uri.query contains \"UPDATE\" or http.request.uri.query contains \"DROP\")",
            "action": "block"
        }
        {
            "description": "Block XSS attempts",
            "expression": "(http.request.uri.query contains \"<script\" or http.request.uri.query contains \"javascript:\")",
            "action": "block"
        }
        {
            "description": "Rate limit API endpoints",
            "expression": "(http.request.uri.path contains \"/api\")",
            "action": "rate_limit",
            "ratelimit": {
                "characteristics": ["ip.src"],
                "period": 60,
                "requests_per_period": 100,
                "timeout": 300
            }
        }
    )
    
    for rule in "${WAF_RULES[@]}"; do
        WAF_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/firewall/rules" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$rule")
        
        if echo "$WAF_RESPONSE" | jq -e '.result.id' > /dev/null; then
            print_success "WAF rule created: $(echo "$rule" | jq -r '.description')"
        else
            print_error "Failed to create WAF rule"
            echo "Response: $WAF_RESPONSE"
        fi
    done
}

# Function to setup Bot Management
setup_bot_management() {
    print_status "Setting up bot management..."
    
    # Create bot fight mode rule
    BOT_RULE=$(cat << EOF
{
    "description": "Agent Zero Bot Management",
    "expression": "(cf.bot_management.score < 30)",
    "action": "block",
    "enabled": true
}
EOF
    )
    
    # Create bot rule
    BOT_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/firewall/rules" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$BOT_RULE")
    
    if echo "$BOT_RESPONSE" | jq -e '.result.id' > /dev/null; then
        print_success "Bot management rule created"
    else
        print_error "Failed to create bot management rule"
        echo "Response: $BOT_RESPONSE"
    fi
}

# Function to create comprehensive monitoring dashboard
create_monitoring_dashboard() {
    print_status "Creating comprehensive monitoring dashboard..."
    
    # Create monitoring dashboard HTML
    cat > monitoring-dashboard.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Agent Zero Monitoring Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .status { display: flex; align-items: center; margin-bottom: 10px; }
        .status-indicator { width: 12px; height: 12px; border-radius: 50%; margin-right: 10px; }
        .status-online { background: #4CAF50; }
        .status-offline { background: #f44336; }
        .status-warning { background: #ff9800; }
        h2 { margin-top: 0; color: #333; }
        .metric { font-size: 24px; font-weight: bold; color: #2196F3; }
        .metric-label { color: #666; font-size: 14px; }
        .chart-container { position: relative; height: 200px; }
        .refresh-btn { background: #2196F3; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; margin-bottom: 20px; }
        .refresh-btn:hover { background: #1976D2; }
    </style>
</head>
<body>
    <h1>Agent Zero Monitoring Dashboard</h1>
    <button class="refresh-btn" onclick="refreshData()">Refresh Data</button>
    
    <div class="dashboard">
        <!-- Agent Zero Status -->
        <div class="card">
            <h2>Agent Zero Status</h2>
            <div class="status">
                <div class="status-indicator" id="agent-zero-status"></div>
                <span id="agent-zero-status-text">Checking...</span>
            </div>
            <div class="metric" id="response-time">--</div>
            <div class="metric-label">Response Time (ms)</div>
        </div>

        <!-- Cloudflare Tunnel Status -->
        <div class="card">
            <h2>Cloudflare Tunnel</h2>
            <div class="status">
                <div class="status-indicator" id="tunnel-status"></div>
                <span id="tunnel-status-text">Checking...</span>
            </div>
            <div class="metric" id="tunnel-uptime">--</div>
            <div class="metric-label">Uptime (%)</div>
        </div>

        <!-- Request Statistics -->
        <div class="card">
            <h2>Request Statistics</h2>
            <div class="metric" id="total-requests">--</div>
            <div class="metric-label">Total Requests (24h)</div>
            <div class="chart-container">
                <canvas id="request-chart"></canvas>
            </div>
        </div>

        <!-- Security Overview -->
        <div class="card">
            <h2>Security Overview</h2>
            <div class="metric" id="threats-blocked">--</div>
            <div class="metric-label">Threats Blocked (24h)</div>
            <div class="chart-container">
                <canvas id="security-chart"></canvas>
            </div>
        </div>

        <!-- Resource Usage -->
        <div class="card">
            <h2>Resource Usage</h2>
            <div class="metric" id="cpu-usage">--</div>
            <div class="metric-label">CPU Usage (%)</div>
            <div class="metric" id="memory-usage">--</div>
            <div class="metric-label">Memory Usage (%)</div>
            <div class="chart-container">
                <canvas id="resource-chart"></canvas>
            </div>
        </div>

        <!-- AI Gateway Stats -->
        <div class="card">
            <h2>AI Gateway</h2>
            <div class="metric" id="ai-requests">--</div>
            <div class="metric-label">AI Requests (24h)</div>
            <div class="metric" id="ai-cache-hit-rate">--</div>
            <div class="metric-label">Cache Hit Rate (%)</div>
        </div>
    </div>

    <script>
        // Configuration
        const config = {
            agentZeroUrl: 'http://localhost:50001',
            cloudflareApiToken: 'YOUR_API_TOKEN',
            zoneId: 'YOUR_ZONE_ID',
            refreshInterval: 30000 // 30 seconds
        };

        // Chart instances
        let requestChart, securityChart, resourceChart;

        // Initialize charts
        function initCharts() {
            // Request chart
            const requestCtx = document.getElementById('request-chart').getContext('2d');
            requestChart = new Chart(requestCtx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Requests per minute',
                        data: [],
                        borderColor: '#2196F3',
                        backgroundColor: 'rgba(33, 150, 243, 0.1)',
                        tension: 0.4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: { beginAtZero: true }
                    }
                }
            });

            // Security chart
            const securityCtx = document.getElementById('security-chart').getContext('2d');
            securityChart = new Chart(securityCtx, {
                type: 'doughnut',
                data: {
                    labels: ['Allowed', 'Blocked', 'Challenged'],
                    datasets: [{
                        data: [0, 0, 0],
                        backgroundColor: ['#4CAF50', '#f44336', '#ff9800']
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false
                }
            });

            // Resource chart
            const resourceCtx = document.getElementById('resource-chart').getContext('2d');
            resourceChart = new Chart(resourceCtx, {
                type: 'bar',
                data: {
                    labels: ['CPU', 'Memory', 'Disk'],
                    datasets: [{
                        label: 'Usage %',
                        data: [0, 0, 0],
                        backgroundColor: ['#2196F3', '#4CAF50', '#ff9800']
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: { beginAtZero: true, max: 100 }
                    }
                }
            });
        }

        // Check Agent Zero status
        async function checkAgentZeroStatus() {
            try {
                const startTime = Date.now();
                const response = await fetch(config.agentZeroUrl + '/health');
                const responseTime = Date.now() - startTime;

                const statusElement = document.getElementById('agent-zero-status');
                const statusTextElement = document.getElementById('agent-zero-status-text');
                const responseTimeElement = document.getElementById('response-time');

                if (response.ok) {
                    statusElement.className = 'status-indicator status-online';
                    statusTextElement.textContent = 'Online';
                    responseTimeElement.textContent = responseTime;
                } else {
                    statusElement.className = 'status-indicator status-warning';
                    statusTextElement.textContent = 'Degraded';
                    responseTimeElement.textContent = responseTime;
                }
            } catch (error) {
                const statusElement = document.getElementById('agent-zero-status');
                const statusTextElement = document.getElementById('agent-zero-status-text');
                
                statusElement.className = 'status-indicator status-offline';
                statusTextElement.textContent = 'Offline';
                document.getElementById('response-time').textContent = '--';
            }
        }

        // Check Cloudflare Tunnel status
        async function checkTunnelStatus() {
            try {
                // This would typically call a Cloudflare API endpoint
                // For demo purposes, we'll simulate the status
                const statusElement = document.getElementById('tunnel-status');
                const statusTextElement = document.getElementById('tunnel-status-text');
                const uptimeElement = document.getElementById('tunnel-uptime');

                // Simulated data - replace with actual API call
                statusElement.className = 'status-indicator status-online';
                statusTextElement.textContent = 'Connected';
                uptimeElement.textContent = '99.9';
            } catch (error) {
                const statusElement = document.getElementById('tunnel-status');
                const statusTextElement = document.getElementById('tunnel-status-text');
                
                statusElement.className = 'status-indicator status-offline';
                statusTextElement.textContent = 'Disconnected';
                document.getElementById('tunnel-uptime').textContent = '--';
            }
        }

        // Fetch Cloudflare analytics
        async function fetchCloudflareAnalytics() {
            try {
                // This would make an actual API call to Cloudflare
                // For demo purposes, we'll use simulated data
                updateRequestChart();
                updateSecurityChart();
                updateResourceChart();
                updateMetrics();
            } catch (error) {
                console.error('Failed to fetch Cloudflare analytics:', error);
            }
        }

        // Update request chart
        function updateRequestChart() {
            const now = new Date();
            const labels = [];
            const data = [];

            for (let i = 23; i >= 0; i--) {
                const time = new Date(now - i * 60 * 60 * 1000);
                labels.push(time.getHours() + ':00');
                data.push(Math.floor(Math.random() * 100) + 50);
            }

            requestChart.data.labels = labels;
            requestChart.data.datasets[0].data = data;
            requestChart.update();

            document.getElementById('total-requests').textContent = data.reduce((a, b) => a + b, 0).toLocaleString();
        }

        // Update security chart
        function updateSecurityChart() {
            const allowed = Math.floor(Math.random() * 1000) + 500;
            const blocked = Math.floor(Math.random() * 50) + 10;
            const challenged = Math.floor(Math.random() * 20) + 5;

            securityChart.data.datasets[0].data = [allowed, blocked, challenged];
            securityChart.update();

            document.getElementById('threats-blocked').textContent = blocked.toLocaleString();
        }

        // Update resource chart
        function updateResourceChart() {
            const cpu = Math.floor(Math.random() * 30) + 20;
            const memory = Math.floor(Math.random() * 40) + 30;
            const disk = Math.floor(Math.random() * 20) + 10;

            resourceChart.data.datasets[0].data = [cpu, memory, disk];
            resourceChart.update();

            document.getElementById('cpu-usage').textContent = cpu;
            document.getElementById('memory-usage').textContent = memory;
        }

        // Update metrics
        function updateMetrics() {
            // AI Gateway metrics
            document.getElementById('ai-requests').textContent = (Math.floor(Math.random() * 500) + 200).toLocaleString();
            document.getElementById('ai-cache-hit-rate').textContent = (Math.floor(Math.random() * 30) + 70);
        }

        // Refresh all data
        async function refreshData() {
            await Promise.all([
                checkAgentZeroStatus(),
                checkTunnelStatus(),
                fetchCloudflareAnalytics()
            ]);
        }

        // Initialize dashboard
        function initDashboard() {
            initCharts();
            refreshData();
            
            // Set up auto-refresh
            setInterval(refreshData, config.refreshInterval);
        }

        // Start dashboard when page loads
        document.addEventListener('DOMContentLoaded', initDashboard);
    </script>
</body>
</html>
EOF
    
    print_success "Monitoring dashboard created: monitoring-dashboard.html"
    print_status "Open this file in your browser to view the dashboard"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  ai-gateway      - Setup AI Gateway for monitoring and control"
    echo "  vectorize       - Setup Vectorize for memory management"
    echo "  workers-ai      - Setup Workers AI integration"
    echo "  access          - Setup Cloudflare Access for Zero Trust"
    echo "  rate-limit      - Setup rate limiting rules"
    echo "  page-rules      - Setup caching page rules"
    echo "  analytics       - Setup enhanced analytics"
    echo "  waf             - Setup Web Application Firewall"
    echo "  bot-management  - Setup bot management"
    echo "  dashboard       - Create monitoring dashboard"
    echo "  all             - Setup all features"
    echo "  help            - Show this help message"
}

# Main function
main() {
    echo "=========================================="
    echo "Enhanced Cloudflare Features for Agent Zero"
    echo "=========================================="
    echo
    
    # Load configuration
    load_config
    
    case "${1:-help}" in
        "ai-gateway")
            validate_config
            setup_ai_gateway
            ;;
        "vectorize")
            validate_config
            setup_vectorize
            ;;
        "workers-ai")
            setup_workers_ai
            ;;
        "access")
            validate_config
            setup_cloudflare_access
            ;;
        "rate-limit")
            validate_config
            setup_rate_limiting
            ;;
        "page-rules")
            validate_config
            setup_page_rules
            ;;
        "analytics")
            validate_config
            setup_analytics
            ;;
        "waf")
            validate_config
            setup_waf
            ;;
        "bot-management")
            validate_config
            setup_bot_management
            ;;
        "dashboard")
            create_monitoring_dashboard
            ;;
        "all")
            validate_config
            setup_ai_gateway
            setup_vectorize
            setup_workers_ai
            setup_cloudflare_access
            setup_rate_limiting
            setup_page_rules
            setup_analytics
            setup_waf
            setup_bot_management
            create_monitoring_dashboard
            echo
            print_success "All enhanced Cloudflare features have been setup!"
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