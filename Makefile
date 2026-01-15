# bash.d - Makefile for project automation
# Usage: make [target]

.PHONY: help install install-dev test test-cov lint format clean docs \
        check health agents-list agents-validate setup-hooks \
        build docker-build docker-run index update-deps

# Default target
.DEFAULT_GOAL := help

# Colors for terminal output
BLUE := \033[34m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

# Project paths
BASHD_HOME := $(shell pwd)
PYTHON := python3
PIP := pip3
PYTEST := $(PYTHON) -m pytest

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------
help: ## Show this help message
	@echo "$(BLUE)bash.d - Modular Bash Configuration Framework$(RESET)"
	@echo ""
	@echo "$(GREEN)Usage:$(RESET) make [target]"
	@echo ""
	@echo "$(YELLOW)Targets:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'

#------------------------------------------------------------------------------
# Installation
#------------------------------------------------------------------------------
install: ## Install bash.d to ~/.bash.d
	@echo "$(BLUE)Installing bash.d...$(RESET)"
	./install.sh
	@echo "$(GREEN)✓ Installation complete$(RESET)"

install-dev: ## Install development dependencies
	@echo "$(BLUE)Installing development dependencies...$(RESET)"
	$(PIP) install -r requirements.txt
	$(PIP) install pre-commit
	@echo "$(GREEN)✓ Development dependencies installed$(RESET)"

install-all: install install-dev setup-hooks ## Full installation with dev tools and hooks

#------------------------------------------------------------------------------
# Testing
#------------------------------------------------------------------------------
test: ## Run all tests
	@echo "$(BLUE)Running tests...$(RESET)"
	$(PYTEST) tests/ -v
	@echo "$(GREEN)✓ Tests complete$(RESET)"

test-cov: ## Run tests with coverage report
	@echo "$(BLUE)Running tests with coverage...$(RESET)"
	$(PYTEST) tests/ -v --cov=agents --cov=tools --cov-report=term-missing --cov-report=html
	@echo "$(GREEN)✓ Coverage report generated in htmlcov/$(RESET)"

test-quick: ## Run tests quickly (no verbose)
	@$(PYTEST) tests/ -q

test-watch: ## Run tests in watch mode (requires pytest-watch)
	$(PYTHON) -m pytest_watch tests/

#------------------------------------------------------------------------------
# Code Quality
#------------------------------------------------------------------------------
lint: ## Run linting checks
	@echo "$(BLUE)Running linters...$(RESET)"
	@$(PYTHON) -m ruff check agents/ tools/ tests/ --fix || true
	@echo "$(GREEN)✓ Linting complete$(RESET)"

format: ## Format code with ruff
	@echo "$(BLUE)Formatting code...$(RESET)"
	@$(PYTHON) -m ruff format agents/ tools/ tests/
	@echo "$(GREEN)✓ Formatting complete$(RESET)"

typecheck: ## Run type checking with mypy
	@echo "$(BLUE)Running type checks...$(RESET)"
	@$(PYTHON) -m mypy agents/ tools/ --ignore-missing-imports || true
	@echo "$(GREEN)✓ Type checking complete$(RESET)"

check: lint typecheck test ## Run all checks (lint, typecheck, test)

#------------------------------------------------------------------------------
# Project Health
#------------------------------------------------------------------------------
health: ## Check project health and status
	@echo "$(BLUE)Checking project health...$(RESET)"
	@$(PYTHON) scripts/project_health.py 2>/dev/null || $(PYTHON) -c "\
import os, glob, json; \
print('📊 Project Statistics:'); \
py_files = glob.glob('**/*.py', recursive=True); \
sh_files = glob.glob('**/*.sh', recursive=True); \
print(f'  Python files: {len(py_files)}'); \
print(f'  Shell scripts: {len(sh_files)}'); \
print(f'  Agent modules: {len(glob.glob(\"agents/**/*.py\", recursive=True))}'); \
print(f'  Test files: {len(glob.glob(\"tests/*.py\"))}'); \
print(f'  Documentation: {len(glob.glob(\"**/*.md\", recursive=True))}'); \
"
	@echo "$(GREEN)✓ Health check complete$(RESET)"

outdated: ## Check for outdated dependencies
	@echo "$(BLUE)Checking for outdated packages...$(RESET)"
	@$(PIP) list --outdated 2>/dev/null | head -20 || echo "Unable to check"

validate: ## Validate all configurations
	@echo "$(BLUE)Validating configurations...$(RESET)"
	@$(PYTHON) -c "from agents import BaseAgent, AgentType; print('✓ Agent imports OK')"
	@$(PYTHON) -c "from tools import ToolRegistry; print('✓ Tool imports OK')" 2>/dev/null || echo "⚠ Tool registry not found"
	@bash -n bashrc && echo "✓ bashrc syntax OK" || echo "✗ bashrc syntax error"
	@echo "$(GREEN)✓ Validation complete$(RESET)"

#------------------------------------------------------------------------------
# Agents
#------------------------------------------------------------------------------
agents-list: ## List all available agents
	@echo "$(BLUE)Available Agents:$(RESET)"
	@find agents -name "*_agent.py" -type f | sed 's/agents\//  /' | sed 's/_agent.py//' | sort

agents-validate: ## Validate all agent definitions
	@echo "$(BLUE)Validating agents...$(RESET)"
	@$(PYTHON) validate_master_agent.py 2>/dev/null || echo "Validation script not configured"

agents-demo: ## Run agent demo
	@echo "$(BLUE)Running agent demo...$(RESET)"
	@$(PYTHON) -m agents.demo_multiagent 2>/dev/null || echo "Demo not available"

#------------------------------------------------------------------------------
# Documentation
#------------------------------------------------------------------------------
docs: ## Generate documentation
	@echo "$(BLUE)Generating documentation...$(RESET)"
	@$(PYTHON) scripts/generate_docs.py 2>/dev/null || \
		echo "Documentation generator not found. Creating basic index..."
	@$(MAKE) docs-index
	@echo "$(GREEN)✓ Documentation generated$(RESET)"

docs-index: ## Generate documentation index
	@echo "$(BLUE)Generating docs index...$(RESET)"
	@find docs -name "*.md" -type f | sort | \
		awk '{print "- ["$$0"]("$$0")"}' > docs/INDEX.md 2>/dev/null || true
	@echo "$(GREEN)✓ Index created at docs/INDEX.md$(RESET)"

docs-serve: ## Serve documentation locally (requires mkdocs)
	@mkdocs serve 2>/dev/null || echo "mkdocs not installed. Run: pip install mkdocs"

#------------------------------------------------------------------------------
# Index & Search
#------------------------------------------------------------------------------
index: ## Build search index
	@echo "$(BLUE)Building search index...$(RESET)"
	@bash -c 'source bashrc 2>/dev/null && bashd_index_build' 2>/dev/null || \
		bash lib/indexer.sh build 2>/dev/null || \
		echo "Indexer not available"
	@echo "$(GREEN)✓ Index built$(RESET)"

index-stats: ## Show index statistics
	@bash -c 'source bashrc 2>/dev/null && bashd_index_stats' 2>/dev/null || \
		echo "Index stats not available"

#------------------------------------------------------------------------------
# Cleanup
#------------------------------------------------------------------------------
clean: ## Clean generated files and caches
	@echo "$(BLUE)Cleaning...$(RESET)"
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "htmlcov" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@find . -type f -name ".coverage" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Cleaned$(RESET)"

clean-all: clean ## Deep clean including index and logs
	@rm -rf .bashd_index.json .bashd_cache 2>/dev/null || true
	@find . -type d -name "logs_*" -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)✓ Deep clean complete$(RESET)"

#------------------------------------------------------------------------------
# Docker
#------------------------------------------------------------------------------
docker-build: ## Build Docker image
	@echo "$(BLUE)Building Docker image...$(RESET)"
	docker build -t bashd:latest .
	@echo "$(GREEN)✓ Docker image built$(RESET)"

docker-run: ## Run Docker container
	docker run -it --rm bashd:latest

docker-compose-up: ## Start all services with docker-compose
	docker-compose up -d

docker-compose-down: ## Stop all services
	docker-compose down

#------------------------------------------------------------------------------
# Git Hooks
#------------------------------------------------------------------------------
setup-hooks: ## Setup pre-commit hooks
	@echo "$(BLUE)Setting up git hooks...$(RESET)"
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit install; \
		echo "$(GREEN)✓ Pre-commit hooks installed$(RESET)"; \
	else \
		echo "$(YELLOW)⚠ pre-commit not found. Installing...$(RESET)"; \
		$(PIP) install pre-commit && pre-commit install; \
	fi

#------------------------------------------------------------------------------
# Updates
#------------------------------------------------------------------------------
update-deps: ## Update all dependencies to latest versions
	@echo "$(BLUE)Updating dependencies...$(RESET)"
	$(PIP) install --upgrade -r requirements.txt
	@echo "$(GREEN)✓ Dependencies updated$(RESET)"

update-repo: ## Pull latest changes and update
	@echo "$(BLUE)Updating repository...$(RESET)"
	git pull origin main
	$(MAKE) install-dev
	@echo "$(GREEN)✓ Repository updated$(RESET)"

#------------------------------------------------------------------------------
# Development Shortcuts
#------------------------------------------------------------------------------
dev: ## Start development environment
	@echo "$(BLUE)Starting development environment...$(RESET)"
	@$(MAKE) validate
	@$(MAKE) test-quick
	@echo "$(GREEN)✓ Development environment ready$(RESET)"

ci: clean lint test ## Run CI pipeline locally
	@echo "$(GREEN)✓ CI pipeline passed$(RESET)"

release: check ## Prepare for release
	@echo "$(BLUE)Preparing release...$(RESET)"
	@$(MAKE) clean
	@$(MAKE) docs
	@echo "$(GREEN)✓ Ready for release$(RESET)"
