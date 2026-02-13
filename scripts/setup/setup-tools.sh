#!/bin/bash
#
# Comprehensive Tool Suite Setup Script
# Sets up the complete environment for AI agents with 140+ tools
#

set -e

echo "========================================="
echo "  Comprehensive Tool Suite Setup"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}→${NC} $1"
}

# Check if running in the correct directory
if [ ! -f "requirements.txt" ]; then
    print_error "Error: requirements.txt not found. Please run this script from the repository root."
    exit 1
fi

# Step 1: Check Python version
print_info "Checking Python version..."
python_version=$(python3 --version 2>&1 | awk '{print $2}')
required_version="3.11.0"

if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" = "$required_version" ]; then
    print_success "Python $python_version detected"
else
    print_error "Python 3.11+ required. Current version: $python_version"
    exit 1
fi

# Step 2: Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    print_info "Creating Python virtual environment..."
    python3 -m venv venv
    print_success "Virtual environment created"
else
    print_success "Virtual environment already exists"
fi

# Step 3: Activate virtual environment
print_info "Activating virtual environment..."
source venv/bin/activate
print_success "Virtual environment activated"

# Step 4: Upgrade pip
print_info "Upgrading pip..."
pip install --upgrade pip > /dev/null 2>&1
print_success "Pip upgraded"

# Step 5: Install Python dependencies
print_info "Installing Python dependencies..."
pip install -r requirements.txt > /dev/null 2>&1
print_success "Python dependencies installed"

# Step 6: Check Bitwarden CLI
print_info "Checking Bitwarden CLI..."
if command -v bw &> /dev/null; then
    bw_version=$(bw --version)
    print_success "Bitwarden CLI $bw_version detected"
else
    print_error "Bitwarden CLI not found"
    echo "  Install with: npm install -g @bitwarden/cli"
    echo "  Or download from: https://bitwarden.com/download/"
fi

# Step 7: Check Docker
print_info "Checking Docker..."
if command -v docker &> /dev/null; then
    docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
    print_success "Docker $docker_version detected"
else
    print_error "Docker not found"
    echo "  Install from: https://docs.docker.com/get-docker/"
fi

# Step 8: Check Git
print_info "Checking Git..."
if command -v git &> /dev/null; then
    git_version=$(git --version | awk '{print $3}')
    print_success "Git $git_version detected"
else
    print_error "Git not found - required for Git tools"
fi

# Step 9: Create necessary directories
print_info "Creating directory structure..."
mkdir -p schemas
mkdir -p logs
mkdir -p data
print_success "Directory structure created"

# Step 10: Set up .env file
if [ ! -f ".env" ]; then
    print_info "Creating .env file from template..."
    cp .env.example .env
    print_success ".env file created - please configure it with your credentials"
    echo "  Edit .env and add your API keys and Bitwarden credentials"
else
    print_success ".env file already exists"
fi

# Step 11: Export tool schemas
print_info "Exporting tool schemas..."
cd tools
python3 export_schemas.py > /dev/null 2>&1
cd ..
print_success "Tool schemas exported to schemas/ directory"

# Step 12: Test tool registry
print_info "Testing tool registry..."
python3 -m tools.registry stats > /dev/null 2>&1
tool_count=$(python3 -m tools.registry stats 2>/dev/null | grep "Total Tools:" | awk '{print $3}')
print_success "Tool registry initialized with $tool_count tools"

# Step 13: Display summary
echo ""
echo "========================================="
echo "  Setup Complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "  • Python environment: ✓"
echo "  • Dependencies: ✓"
echo "  • Tool registry: ✓ ($tool_count tools)"
echo "  • Schemas exported: ✓"
echo ""

# Check optional dependencies
echo "Optional Dependencies:"
if command -v bw &> /dev/null; then
    echo "  • Bitwarden CLI: ✓"
else
    echo "  • Bitwarden CLI: ✗ (install for secret management)"
fi

if command -v docker &> /dev/null; then
    echo "  • Docker: ✓"
else
    echo "  • Docker: ✗ (install for Docker tools)"
fi

echo ""
echo "Next Steps:"
echo "  1. Edit .env file with your API keys and credentials"
echo "  2. If using Bitwarden: bw login && bw unlock"
echo "  3. Test tools: python3 -m tools.registry list"
echo "  4. View documentation: cat docs/TOOLS_OVERVIEW.md"
echo ""
echo "To activate the environment later, run:"
echo "  source venv/bin/activate"
echo ""

# Deactivate virtual environment
deactivate 2>/dev/null || true
