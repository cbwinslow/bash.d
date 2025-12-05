#!/usr/bin/env python3
"""
Agent Generator Script

Generates 100 specialized AI agents with comprehensive configurations,
docstrings, and OpenAI compatibility.
"""

import json
import os
from pathlib import Path
from typing import List, Dict, Any


# Agent definitions with specialized configurations
AGENT_DEFINITIONS = [
    # Programming Agents (20)
    {
        "name": "Python Backend Developer",
        "type": "programming",
        "description": "Expert in Python backend development, FastAPI, Django, Flask, and async programming",
        "specialization": "python_backend",
        "capabilities": ["api_development", "database_integration", "async_programming", "testing"],
        "tools": ["python_analyzer", "pytest", "mypy", "black"],
    },
    {
        "name": "JavaScript Full Stack Developer",
        "type": "programming",
        "description": "Full-stack JavaScript developer specializing in React, Node.js, and TypeScript",
        "specialization": "javascript_fullstack",
        "capabilities": ["frontend_development", "backend_development", "api_integration", "testing"],
        "tools": ["eslint", "prettier", "jest", "webpack"],
    },
    {
        "name": "TypeScript Architect",
        "type": "programming",
        "description": "TypeScript expert focusing on type-safe architecture and design patterns",
        "specialization": "typescript",
        "capabilities": ["type_system_design", "interface_design", "generic_programming"],
        "tools": ["tsc", "eslint", "prettier"],
    },
    {
        "name": "Rust Systems Programmer",
        "type": "programming",
        "description": "Systems programming expert in Rust with focus on performance and safety",
        "specialization": "rust",
        "capabilities": ["systems_programming", "memory_management", "concurrency"],
        "tools": ["cargo", "clippy", "rustfmt"],
    },
    {
        "name": "Go Microservices Developer",
        "type": "programming",
        "description": "Go developer specialized in building scalable microservices and distributed systems",
        "specialization": "go",
        "capabilities": ["microservices", "grpc", "distributed_systems"],
        "tools": ["go_build", "go_test", "golangci-lint"],
    },
    {
        "name": "Java Enterprise Developer",
        "type": "programming",
        "description": "Java expert for enterprise applications, Spring Boot, and JPA",
        "specialization": "java",
        "capabilities": ["spring_framework", "jpa", "enterprise_patterns"],
        "tools": ["maven", "gradle", "junit"],
    },
    {
        "name": "C++ Performance Engineer",
        "type": "programming",
        "description": "C++ specialist focusing on high-performance computing and optimization",
        "specialization": "cpp",
        "capabilities": ["performance_optimization", "template_programming", "memory_management"],
        "tools": ["cmake", "gdb", "valgrind"],
    },
    {
        "name": "Ruby on Rails Developer",
        "type": "programming",
        "description": "Ruby on Rails expert for rapid web application development",
        "specialization": "ruby",
        "capabilities": ["rails_development", "active_record", "mvc_pattern"],
        "tools": ["bundler", "rspec", "rubocop"],
    },
    {
        "name": "PHP Laravel Developer",
        "type": "programming",
        "description": "PHP developer specializing in Laravel framework and modern PHP practices",
        "specialization": "php",
        "capabilities": ["laravel", "eloquent", "blade_templates"],
        "tools": ["composer", "phpunit", "phpstan"],
    },
    {
        "name": "Swift iOS Developer",
        "type": "programming",
        "description": "iOS development expert using Swift and SwiftUI",
        "specialization": "swift",
        "capabilities": ["ios_development", "swiftui", "core_data"],
        "tools": ["xcode", "swift_package_manager"],
    },
    {
        "name": "Kotlin Android Developer",
        "type": "programming",
        "description": "Android developer expert in Kotlin and Jetpack Compose",
        "specialization": "kotlin",
        "capabilities": ["android_development", "jetpack_compose", "coroutines"],
        "tools": ["gradle", "android_studio"],
    },
    {
        "name": "Scala Functional Programmer",
        "type": "programming",
        "description": "Functional programming expert using Scala, Akka, and Cats",
        "specialization": "scala",
        "capabilities": ["functional_programming", "akka_actors", "cats_library"],
        "tools": ["sbt", "scalafmt"],
    },
    {
        "name": "Elixir Concurrent Systems Developer",
        "type": "programming",
        "description": "Elixir and Phoenix developer for highly concurrent systems",
        "specialization": "elixir",
        "capabilities": ["concurrency", "otp", "phoenix_framework"],
        "tools": ["mix", "credo"],
    },
    {
        "name": "Haskell Pure Functional Developer",
        "type": "programming",
        "description": "Pure functional programming expert in Haskell",
        "specialization": "haskell",
        "capabilities": ["pure_functional", "type_classes", "monads"],
        "tools": ["cabal", "stack", "hlint"],
    },
    {
        "name": "R Statistical Programmer",
        "type": "programming",
        "description": "R programming expert for statistical analysis and data science",
        "specialization": "r",
        "capabilities": ["statistical_analysis", "data_visualization", "tidyverse"],
        "tools": ["rstudio", "rmarkdown"],
    },
    {
        "name": "SQL Database Developer",
        "type": "programming",
        "description": "SQL expert for database design, optimization, and complex queries",
        "specialization": "sql",
        "capabilities": ["database_design", "query_optimization", "stored_procedures"],
        "tools": ["psql", "mysql", "sql_formatter"],
    },
    {
        "name": "Shell Script Automation Expert",
        "type": "programming",
        "description": "Bash and shell scripting expert for automation and DevOps",
        "specialization": "shell",
        "capabilities": ["bash_scripting", "automation", "system_administration"],
        "tools": ["shellcheck", "shfmt"],
    },
    {
        "name": "WebAssembly Developer",
        "type": "programming",
        "description": "WebAssembly expert for high-performance web applications",
        "specialization": "wasm",
        "capabilities": ["wasm_development", "emscripten", "performance"],
        "tools": ["wasm_pack", "emscripten"],
    },
    {
        "name": "GraphQL API Developer",
        "type": "programming",
        "description": "GraphQL expert for modern API development",
        "specialization": "graphql",
        "capabilities": ["graphql_schema", "resolvers", "subscriptions"],
        "tools": ["graphql_codegen", "apollo"],
    },
    {
        "name": "Smart Contract Developer",
        "type": "programming",
        "description": "Blockchain and smart contract developer using Solidity",
        "specialization": "blockchain",
        "capabilities": ["solidity", "web3", "smart_contracts"],
        "tools": ["truffle", "hardhat", "ganache"],
    },
    
    # DevOps Agents (15)
    {
        "name": "Kubernetes Orchestration Specialist",
        "type": "devops",
        "description": "Kubernetes expert for container orchestration and cluster management",
        "specialization": "kubernetes",
        "capabilities": ["k8s_deployment", "helm_charts", "cluster_management"],
        "tools": ["kubectl", "helm", "kustomize"],
    },
    {
        "name": "Docker Container Expert",
        "type": "devops",
        "description": "Docker containerization specialist for building and optimizing containers",
        "specialization": "docker",
        "capabilities": ["dockerfile_creation", "image_optimization", "docker_compose"],
        "tools": ["docker", "docker_compose", "hadolint"],
    },
    {
        "name": "Terraform Infrastructure Engineer",
        "type": "devops",
        "description": "Infrastructure as Code expert using Terraform",
        "specialization": "terraform",
        "capabilities": ["iac", "cloud_provisioning", "state_management"],
        "tools": ["terraform", "terragrunt", "tflint"],
    },
    {
        "name": "CI/CD Pipeline Architect",
        "type": "devops",
        "description": "Continuous Integration and Deployment pipeline expert",
        "specialization": "cicd",
        "capabilities": ["pipeline_design", "automation", "deployment_strategies"],
        "tools": ["jenkins", "github_actions", "gitlab_ci"],
    },
    {
        "name": "AWS Cloud Architect",
        "type": "devops",
        "description": "AWS cloud infrastructure and services expert",
        "specialization": "aws",
        "capabilities": ["ec2", "s3", "lambda", "vpc_design"],
        "tools": ["aws_cli", "cloudformation", "sam"],
    },
    {
        "name": "Azure DevOps Engineer",
        "type": "devops",
        "description": "Microsoft Azure cloud services and DevOps specialist",
        "specialization": "azure",
        "capabilities": ["azure_services", "devops_pipelines", "arm_templates"],
        "tools": ["az_cli", "azure_devops"],
    },
    {
        "name": "GCP Cloud Engineer",
        "type": "devops",
        "description": "Google Cloud Platform infrastructure expert",
        "specialization": "gcp",
        "capabilities": ["gke", "cloud_functions", "gcp_networking"],
        "tools": ["gcloud", "terraform"],
    },
    {
        "name": "Ansible Automation Specialist",
        "type": "devops",
        "description": "Configuration management and automation using Ansible",
        "specialization": "ansible",
        "capabilities": ["playbook_development", "role_creation", "inventory_management"],
        "tools": ["ansible", "ansible_lint"],
    },
    {
        "name": "Prometheus Monitoring Expert",
        "type": "devops",
        "description": "Monitoring and alerting specialist using Prometheus and Grafana",
        "specialization": "monitoring",
        "capabilities": ["metrics_collection", "alerting", "dashboard_creation"],
        "tools": ["prometheus", "grafana", "alertmanager"],
    },
    {
        "name": "ELK Stack Log Engineer",
        "type": "devops",
        "description": "Log aggregation and analysis using Elasticsearch, Logstash, and Kibana",
        "specialization": "logging",
        "capabilities": ["log_aggregation", "parsing", "visualization"],
        "tools": ["elasticsearch", "logstash", "kibana"],
    },
    {
        "name": "HashiCorp Vault Security Engineer",
        "type": "devops",
        "description": "Secrets management and security using HashiCorp Vault",
        "specialization": "secrets",
        "capabilities": ["secrets_management", "encryption", "access_control"],
        "tools": ["vault", "consul"],
    },
    {
        "name": "GitOps Workflow Specialist",
        "type": "devops",
        "description": "GitOps methodologies and tools expert",
        "specialization": "gitops",
        "capabilities": ["argocd", "flux", "git_workflows"],
        "tools": ["argocd", "flux", "git"],
    },
    {
        "name": "Service Mesh Architect",
        "type": "devops",
        "description": "Service mesh implementation using Istio or Linkerd",
        "specialization": "service_mesh",
        "capabilities": ["traffic_management", "observability", "security"],
        "tools": ["istio", "linkerd"],
    },
    {
        "name": "Load Balancer Specialist",
        "type": "devops",
        "description": "Load balancing and traffic management expert",
        "specialization": "load_balancing",
        "capabilities": ["nginx", "haproxy", "traffic_routing"],
        "tools": ["nginx", "haproxy", "traefik"],
    },
    {
        "name": "Backup and Disaster Recovery Specialist",
        "type": "devops",
        "description": "Backup strategies and disaster recovery planning expert",
        "specialization": "backup",
        "capabilities": ["backup_automation", "recovery_testing", "rpo_rto"],
        "tools": ["velero", "restic", "rclone"],
    },
    
    # Documentation Agents (10)
    {
        "name": "Technical Writer",
        "type": "documentation",
        "description": "Technical documentation specialist for software projects",
        "specialization": "technical_writing",
        "capabilities": ["documentation_creation", "api_docs", "user_guides"],
        "tools": ["markdown", "asciidoc", "docusaurus"],
    },
    {
        "name": "API Documentation Expert",
        "type": "documentation",
        "description": "API documentation using OpenAPI/Swagger and other standards",
        "specialization": "api_docs",
        "capabilities": ["openapi", "swagger", "postman"],
        "tools": ["swagger_editor", "redocly", "stoplight"],
    },
    {
        "name": "Code Commenting Specialist",
        "type": "documentation",
        "description": "Inline code documentation and commenting expert",
        "specialization": "code_comments",
        "capabilities": ["docstring_generation", "comment_standards", "jsdoc"],
        "tools": ["pydoc", "jsdoc", "godoc"],
    },
    {
        "name": "Tutorial Creator",
        "type": "documentation",
        "description": "Creating step-by-step tutorials and learning materials",
        "specialization": "tutorials",
        "capabilities": ["tutorial_writing", "example_creation", "learning_paths"],
        "tools": ["markdown", "jupyter", "codesandbox"],
    },
    {
        "name": "Architecture Documentation Specialist",
        "type": "documentation",
        "description": "System architecture diagrams and documentation expert",
        "specialization": "architecture_docs",
        "capabilities": ["uml_diagrams", "c4_model", "architecture_decision_records"],
        "tools": ["mermaid", "plantuml", "draw_io"],
    },
    {
        "name": "README Generator",
        "type": "documentation",
        "description": "Comprehensive README file creation for projects",
        "specialization": "readme",
        "capabilities": ["readme_structure", "badges", "getting_started"],
        "tools": ["markdown", "shields_io"],
    },
    {
        "name": "Changelog Maintainer",
        "type": "documentation",
        "description": "Maintaining changelogs and release notes",
        "specialization": "changelog",
        "capabilities": ["changelog_format", "semantic_versioning", "release_notes"],
        "tools": ["conventional_commits", "semantic_release"],
    },
    {
        "name": "Knowledge Base Curator",
        "type": "documentation",
        "description": "Organizing and maintaining knowledge bases",
        "specialization": "knowledge_base",
        "capabilities": ["wiki_management", "content_organization", "search_optimization"],
        "tools": ["confluence", "notion", "gitbook"],
    },
    {
        "name": "Localization Documentation Specialist",
        "type": "documentation",
        "description": "Multi-language documentation and localization expert",
        "specialization": "localization",
        "capabilities": ["translation_management", "i18n", "multi_language_docs"],
        "tools": ["crowdin", "transifex"],
    },
    {
        "name": "Video Tutorial Creator",
        "type": "documentation",
        "description": "Creating video tutorials and screencasts",
        "specialization": "video_tutorials",
        "capabilities": ["screencast_creation", "video_editing", "voiceover"],
        "tools": ["obs", "camtasia", "screen_to_gif"],
    },
    
    # Testing Agents (10)
    {
        "name": "Unit Test Developer",
        "type": "testing",
        "description": "Unit testing specialist across multiple languages and frameworks",
        "specialization": "unit_testing",
        "capabilities": ["test_creation", "mocking", "coverage_analysis"],
        "tools": ["pytest", "jest", "junit"],
    },
    {
        "name": "Integration Test Engineer",
        "type": "testing",
        "description": "Integration and API testing expert",
        "specialization": "integration_testing",
        "capabilities": ["api_testing", "database_testing", "service_integration"],
        "tools": ["postman", "rest_assured", "supertest"],
    },
    {
        "name": "End-to-End Test Specialist",
        "type": "testing",
        "description": "E2E testing using Selenium, Cypress, and Playwright",
        "specialization": "e2e_testing",
        "capabilities": ["browser_automation", "user_flow_testing", "visual_regression"],
        "tools": ["cypress", "playwright", "selenium"],
    },
    {
        "name": "Performance Test Engineer",
        "type": "testing",
        "description": "Load testing and performance benchmarking expert",
        "specialization": "performance_testing",
        "capabilities": ["load_testing", "stress_testing", "benchmarking"],
        "tools": ["k6", "jmeter", "locust"],
    },
    {
        "name": "Security Test Specialist",
        "type": "testing",
        "description": "Security testing and vulnerability assessment expert",
        "specialization": "security_testing",
        "capabilities": ["penetration_testing", "vulnerability_scanning", "owasp"],
        "tools": ["owasp_zap", "burp_suite", "nmap"],
    },
    {
        "name": "Test Automation Architect",
        "type": "testing",
        "description": "Test automation framework design and implementation",
        "specialization": "test_automation",
        "capabilities": ["framework_design", "ci_integration", "reporting"],
        "tools": ["selenium_grid", "test_ng", "allure"],
    },
    {
        "name": "Mutation Testing Specialist",
        "type": "testing",
        "description": "Mutation testing for test quality assessment",
        "specialization": "mutation_testing",
        "capabilities": ["mutation_analysis", "test_effectiveness", "pitest"],
        "tools": ["pitest", "stryker", "mutpy"],
    },
    {
        "name": "Contract Testing Expert",
        "type": "testing",
        "description": "Consumer-driven contract testing specialist",
        "specialization": "contract_testing",
        "capabilities": ["pact_testing", "consumer_contracts", "provider_verification"],
        "tools": ["pact", "spring_cloud_contract"],
    },
    {
        "name": "Accessibility Testing Specialist",
        "type": "testing",
        "description": "Web accessibility and WCAG compliance testing",
        "specialization": "accessibility_testing",
        "capabilities": ["wcag_compliance", "screen_reader_testing", "color_contrast"],
        "tools": ["axe", "wave", "pa11y"],
    },
    {
        "name": "Mobile App Test Engineer",
        "type": "testing",
        "description": "Mobile application testing for iOS and Android",
        "specialization": "mobile_testing",
        "capabilities": ["appium", "device_farms", "mobile_automation"],
        "tools": ["appium", "espresso", "xcuitest"],
    },
    
    # Security Agents (10)
    {
        "name": "Vulnerability Scanner",
        "type": "security",
        "description": "Automated vulnerability scanning and assessment",
        "specialization": "vulnerability_scanning",
        "capabilities": ["dependency_scanning", "code_scanning", "infrastructure_scanning"],
        "tools": ["snyk", "trivy", "grype"],
    },
    {
        "name": "Code Security Reviewer",
        "type": "security",
        "description": "Security-focused code review specialist",
        "specialization": "code_review",
        "capabilities": ["static_analysis", "security_patterns", "owasp_top_10"],
        "tools": ["sonarqube", "semgrep", "bandit"],
    },
    {
        "name": "Secrets Detection Specialist",
        "type": "security",
        "description": "Detecting and preventing secret leaks in code",
        "specialization": "secrets_detection",
        "capabilities": ["secret_scanning", "credential_detection", "key_rotation"],
        "tools": ["gitleaks", "trufflehog", "detect_secrets"],
    },
    {
        "name": "Container Security Expert",
        "type": "security",
        "description": "Container and Kubernetes security specialist",
        "specialization": "container_security",
        "capabilities": ["image_scanning", "runtime_security", "policy_enforcement"],
        "tools": ["falco", "aqua", "sysdig"],
    },
    {
        "name": "Cloud Security Architect",
        "type": "security",
        "description": "Cloud infrastructure security and compliance expert",
        "specialization": "cloud_security",
        "capabilities": ["iam_policies", "encryption", "compliance"],
        "tools": ["cloudtrail", "config", "guard_duty"],
    },
    {
        "name": "Network Security Analyst",
        "type": "security",
        "description": "Network security monitoring and threat detection",
        "specialization": "network_security",
        "capabilities": ["firewall_rules", "intrusion_detection", "traffic_analysis"],
        "tools": ["wireshark", "nmap", "metasploit"],
    },
    {
        "name": "Application Security Engineer",
        "type": "security",
        "description": "Application security testing and hardening",
        "specialization": "appsec",
        "capabilities": ["secure_coding", "threat_modeling", "security_testing"],
        "tools": ["owasp_zap", "burp_suite", "arachni"],
    },
    {
        "name": "Compliance Auditor",
        "type": "security",
        "description": "Security compliance and regulatory requirements expert",
        "specialization": "compliance",
        "capabilities": ["gdpr", "hipaa", "pci_dss", "sox"],
        "tools": ["compliance_as_code", "audit_reports"],
    },
    {
        "name": "Incident Response Specialist",
        "type": "security",
        "description": "Security incident detection and response expert",
        "specialization": "incident_response",
        "capabilities": ["threat_hunting", "forensics", "incident_management"],
        "tools": ["elk_stack", "splunk", "osquery"],
    },
    {
        "name": "Cryptography Expert",
        "type": "security",
        "description": "Encryption and cryptographic implementation specialist",
        "specialization": "cryptography",
        "capabilities": ["encryption_design", "key_management", "tls_ssl"],
        "tools": ["openssl", "libsodium", "bouncycastle"],
    },
    
    # Data Agents (10)
    {
        "name": "ETL Pipeline Developer",
        "type": "data",
        "description": "Extract, Transform, Load pipeline specialist",
        "specialization": "etl",
        "capabilities": ["data_extraction", "transformation", "loading"],
        "tools": ["airflow", "dbt", "spark"],
    },
    {
        "name": "Data Warehouse Architect",
        "type": "data",
        "description": "Data warehouse design and implementation expert",
        "specialization": "data_warehouse",
        "capabilities": ["dimensional_modeling", "star_schema", "snowflake_schema"],
        "tools": ["redshift", "snowflake", "bigquery"],
    },
    {
        "name": "Data Quality Engineer",
        "type": "data",
        "description": "Data quality assurance and validation specialist",
        "specialization": "data_quality",
        "capabilities": ["data_validation", "quality_metrics", "anomaly_detection"],
        "tools": ["great_expectations", "deequ", "soda"],
    },
    {
        "name": "Stream Processing Engineer",
        "type": "data",
        "description": "Real-time data streaming and processing expert",
        "specialization": "stream_processing",
        "capabilities": ["kafka", "flink", "spark_streaming"],
        "tools": ["kafka", "flink", "kinesis"],
    },
    {
        "name": "Data Scientist",
        "type": "data",
        "description": "Machine learning and statistical analysis expert",
        "specialization": "data_science",
        "capabilities": ["ml_modeling", "statistical_analysis", "feature_engineering"],
        "tools": ["scikit_learn", "pandas", "jupyter"],
    },
    {
        "name": "Business Intelligence Analyst",
        "type": "data",
        "description": "BI reporting and dashboard creation specialist",
        "specialization": "business_intelligence",
        "capabilities": ["dashboard_creation", "reporting", "data_visualization"],
        "tools": ["tableau", "power_bi", "looker"],
    },
    {
        "name": "Data Governance Specialist",
        "type": "data",
        "description": "Data governance policies and implementation expert",
        "specialization": "data_governance",
        "capabilities": ["data_catalog", "lineage", "access_control"],
        "tools": ["collibra", "alation", "amundsen"],
    },
    {
        "name": "Big Data Engineer",
        "type": "data",
        "description": "Large-scale data processing using Hadoop and Spark",
        "specialization": "big_data",
        "capabilities": ["hadoop", "spark", "hive"],
        "tools": ["spark", "hadoop", "hive"],
    },
    {
        "name": "Time Series Analyst",
        "type": "data",
        "description": "Time series data analysis and forecasting expert",
        "specialization": "time_series",
        "capabilities": ["forecasting", "trend_analysis", "seasonality"],
        "tools": ["prophet", "arima", "influxdb"],
    },
    {
        "name": "Graph Data Specialist",
        "type": "data",
        "description": "Graph database and network analysis expert",
        "specialization": "graph_data",
        "capabilities": ["graph_modeling", "network_analysis", "graph_algorithms"],
        "tools": ["neo4j", "cypher", "networkx"],
    },
    
    # Design Agents (5)
    {
        "name": "UI/UX Designer",
        "type": "design",
        "description": "User interface and experience design specialist",
        "specialization": "ui_ux",
        "capabilities": ["wireframing", "prototyping", "user_research"],
        "tools": ["figma", "sketch", "adobe_xd"],
    },
    {
        "name": "System Architecture Designer",
        "type": "design",
        "description": "Software architecture and system design expert",
        "specialization": "system_architecture",
        "capabilities": ["architecture_patterns", "scalability_design", "technology_selection"],
        "tools": ["c4_model", "uml", "mermaid"],
    },
    {
        "name": "Database Schema Designer",
        "type": "design",
        "description": "Database design and normalization specialist",
        "specialization": "database_design",
        "capabilities": ["er_modeling", "normalization", "indexing_strategy"],
        "tools": ["dbdiagram", "mysql_workbench", "dbeaver"],
    },
    {
        "name": "API Design Specialist",
        "type": "design",
        "description": "RESTful and GraphQL API design expert",
        "specialization": "api_design",
        "capabilities": ["rest_design", "graphql_schema", "api_versioning"],
        "tools": ["swagger", "postman", "graphql_editor"],
    },
    {
        "name": "Microservices Architect",
        "type": "design",
        "description": "Microservices architecture and design patterns expert",
        "specialization": "microservices",
        "capabilities": ["service_decomposition", "inter_service_communication", "api_gateway"],
        "tools": ["kubernetes", "service_mesh", "api_gateway"],
    },
    
    # Communication Agents (5)
    {
        "name": "Slack Bot Manager",
        "type": "communication",
        "description": "Slack integration and bot management specialist",
        "specialization": "slack",
        "capabilities": ["slack_api", "bot_creation", "workflow_automation"],
        "tools": ["slack_api", "bolt", "slack_sdk"],
    },
    {
        "name": "Email Notification System",
        "type": "communication",
        "description": "Email automation and notification specialist",
        "specialization": "email",
        "capabilities": ["template_management", "bulk_sending", "tracking"],
        "tools": ["sendgrid", "mailgun", "ses"],
    },
    {
        "name": "Webhook Manager",
        "type": "communication",
        "description": "Webhook integration and event handling specialist",
        "specialization": "webhooks",
        "capabilities": ["webhook_handling", "event_processing", "retry_logic"],
        "tools": ["webhook_relay", "ngrok"],
    },
    {
        "name": "Report Generator",
        "type": "communication",
        "description": "Automated report generation and distribution",
        "specialization": "reporting",
        "capabilities": ["report_creation", "scheduling", "distribution"],
        "tools": ["pandas", "matplotlib", "reportlab"],
    },
    {
        "name": "Chat Interface Manager",
        "type": "communication",
        "description": "Chat interface and conversational AI specialist",
        "specialization": "chat",
        "capabilities": ["chat_flows", "nlp_integration", "multi_channel"],
        "tools": ["dialogflow", "rasa", "botpress"],
    },
    
    # Monitoring Agents (5)
    {
        "name": "Application Performance Monitor",
        "type": "monitoring",
        "description": "APM and application performance tracking specialist",
        "specialization": "apm",
        "capabilities": ["performance_tracking", "bottleneck_detection", "distributed_tracing"],
        "tools": ["new_relic", "datadog", "dynatrace"],
    },
    {
        "name": "Infrastructure Health Monitor",
        "type": "monitoring",
        "description": "Infrastructure monitoring and health checking specialist",
        "specialization": "infrastructure_monitoring",
        "capabilities": ["server_monitoring", "resource_tracking", "uptime_monitoring"],
        "tools": ["prometheus", "nagios", "zabbix"],
    },
    {
        "name": "Log Aggregation Specialist",
        "type": "monitoring",
        "description": "Centralized logging and log analysis expert",
        "specialization": "logging",
        "capabilities": ["log_collection", "parsing", "analysis"],
        "tools": ["elk_stack", "loki", "splunk"],
    },
    {
        "name": "Alert Manager",
        "type": "monitoring",
        "description": "Alert configuration and incident management specialist",
        "specialization": "alerting",
        "capabilities": ["alert_rules", "notification_routing", "escalation"],
        "tools": ["alertmanager", "pagerduty", "opsgenie"],
    },
    {
        "name": "Metrics Dashboard Creator",
        "type": "monitoring",
        "description": "Metrics visualization and dashboard creation expert",
        "specialization": "dashboards",
        "capabilities": ["dashboard_design", "metric_visualization", "kpi_tracking"],
        "tools": ["grafana", "kibana", "datadog"],
    },
    
    # Automation Agents (10)
    {
        "name": "Workflow Orchestrator",
        "type": "automation",
        "description": "Complex workflow orchestration and automation specialist",
        "specialization": "workflow",
        "capabilities": ["dag_creation", "task_dependencies", "scheduling"],
        "tools": ["airflow", "prefect", "temporal"],
    },
    {
        "name": "Code Generator",
        "type": "automation",
        "description": "Code generation from templates and specifications",
        "specialization": "code_generation",
        "capabilities": ["template_engine", "code_scaffolding", "boilerplate_generation"],
        "tools": ["yeoman", "plop", "cookiecutter"],
    },
    {
        "name": "Release Automation Specialist",
        "type": "automation",
        "description": "Automated release and deployment management",
        "specialization": "release",
        "capabilities": ["version_bumping", "changelog_generation", "artifact_publishing"],
        "tools": ["semantic_release", "release_it", "goreleaser"],
    },
    {
        "name": "Database Migration Manager",
        "type": "automation",
        "description": "Database schema migration and versioning automation",
        "specialization": "db_migration",
        "capabilities": ["migration_creation", "rollback_handling", "version_control"],
        "tools": ["flyway", "liquibase", "alembic"],
    },
    {
        "name": "Dependency Update Bot",
        "type": "automation",
        "description": "Automated dependency updates and security patches",
        "specialization": "dependencies",
        "capabilities": ["dependency_scanning", "update_automation", "pr_creation"],
        "tools": ["dependabot", "renovate", "snyk"],
    },
    {
        "name": "Infrastructure Provisioning Automation",
        "type": "automation",
        "description": "Automated infrastructure provisioning and configuration",
        "specialization": "provisioning",
        "capabilities": ["cloud_provisioning", "configuration_management", "drift_detection"],
        "tools": ["terraform", "pulumi", "crossplane"],
    },
    {
        "name": "Backup Automation Specialist",
        "type": "automation",
        "description": "Automated backup creation and verification",
        "specialization": "backup",
        "capabilities": ["backup_scheduling", "verification", "restoration_testing"],
        "tools": ["velero", "restic", "duplicity"],
    },
    {
        "name": "Certificate Management Bot",
        "type": "automation",
        "description": "TLS/SSL certificate automation and renewal",
        "specialization": "certificates",
        "capabilities": ["cert_renewal", "acme_protocol", "monitoring"],
        "tools": ["cert_manager", "acme", "letsencrypt"],
    },
    {
        "name": "Scaling Automation Manager",
        "type": "automation",
        "description": "Auto-scaling rules and capacity management",
        "specialization": "scaling",
        "capabilities": ["horizontal_scaling", "vertical_scaling", "predictive_scaling"],
        "tools": ["keda", "hpa", "vpa"],
    },
    {
        "name": "Incident Response Automation",
        "type": "automation",
        "description": "Automated incident detection and response",
        "specialization": "incident",
        "capabilities": ["auto_remediation", "runbook_automation", "rollback"],
        "tools": ["rundeck", "stackstorm", "ansible"],
    },
]


def generate_agent_file(agent_def: Dict[str, Any], index: int) -> str:
    """Generate Python code for an agent"""
    agent_name_snake = agent_def["name"].lower().replace(" ", "_").replace("/", "_")
    
    code = f'''"""
{agent_def["name"]} Agent

{agent_def["description"]}

This agent specializes in {agent_def["specialization"]} and is part of the
multi-agentic system for distributed problem-solving and automation.

Specialization: {agent_def["specialization"]}
Type: {agent_def["type"]}
Capabilities: {", ".join(agent_def["capabilities"])}
Tools: {", ".join(agent_def["tools"])}

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
RabbitMQ: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability


class {agent_def["name"].replace(" ", "").replace("/", "")}Agent(BaseAgent):
    """
    {agent_def["name"]} - {agent_def["description"]}
    
    This specialized agent is configured for {agent_def["specialization"]} tasks
    and integrates with the following tools: {", ".join(agent_def["tools"])}
    
    Capabilities:
'''
    
    for capability in agent_def["capabilities"]:
        code += f'    - {capability.replace("_", " ").title()}\n'
    
    agent_class_name = agent_def["name"].replace(" ", "").replace("/", "")
    agent_type_upper = agent_def["type"].upper()
    agent_name = agent_def["name"]
    agent_description = agent_def["description"]
    agent_specialization = agent_def["specialization"]
    agent_type = agent_def["type"]
    
    code += f'''    
    Example Usage:
        ```python
        agent = {agent_class_name}Agent(
            name="{agent_name}",
            type=AgentType.{agent_type_upper}
        )
        
        # Add a task
        task = Task(
            title="Example {agent_specialization} task",
            description="Perform specialized work",
            priority=TaskPriority.HIGH
        )
        
        agent.add_task(task)
        ```
    """
    
    def __init__(self, **data):
        """Initialize the {agent_name} agent with specialized configuration"""
        
        # Set default values if not provided
        defaults = {{
            "name": "{agent_name}",
            "type": AgentType.{agent_type_upper},
            "description": "{agent_description}",
            "tags": ["{agent_type}_agent"],
        }}
        
        # Merge defaults with provided data
        for key, value in defaults.items():
            if key not in data:
                data[key] = value
        
        # Initialize parent class
        super().__init__(**data)
        
        # Add specialized capabilities
'''
    
    for capability in agent_def["capabilities"]:
        cap_desc = capability.replace('_', ' ')
        code += f'''        self.capabilities.append(
            AgentCapability(
                name="{capability}",
                description="Specialized {cap_desc} capability for {agent_specialization}",
                parameters={{}},
                required=True
            )
        )
'''
    
    tools_list = agent_def["tools"]
    code += f'''        
        # Configure specialized tools
        self.config.tools = {tools_list}
        
        # Add specialization metadata
        self.metadata.update({{
            "specialization": "{agent_specialization}",
            "category": "{agent_type}",
            "index": {index + 1}
        }})
    
    async def execute_task(self, task: Any) -> Dict[str, Any]:
        """
        Execute a specialized {agent_def["specialization"]} task
        
        Args:
            task: The task to execute
            
        Returns:
            Dict with execution results
        """
        # Implementation would go here
        # This is a template - actual implementation depends on specific requirements
        
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "{agent_def["specialization"]}",
            "message": f"Task {{task.title}} executed by {agent_def["name"]}"
        }
    
    def get_openai_function_schema(self) -> Dict[str, Any]:
        """
        Get OpenAI function calling schema for this agent
        
        Returns:
            Dict compatible with OpenAI function calling format
        """
        return {
            "name": "{agent_name_snake}",
            "description": "{agent_def["description"]}",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "Description of the {agent_def["specialization"]} task to perform"
                    },
                    "priority": {
                        "type": "string",
                        "enum": ["critical", "high", "medium", "low", "background"],
                        "description": "Task priority level"
                    },
                    "context": {
                        "type": "object",
                        "description": "Additional context and parameters for the task"
                    }
                },
                "required": ["task_description"]
            }
        }
'''
    
    return code


def main():
    """Generate all agent files"""
    base_path = Path(__file__).parent.parent / "agents"
    
    # Create category directories
    categories = {
        "programming": [],
        "devops": [],
        "documentation": [],
        "testing": [],
        "security": [],
        "data": [],
        "design": [],
        "communication": [],
        "monitoring": [],
        "automation": []
    }
    
    # Generate agent files
    for index, agent_def in enumerate(AGENT_DEFINITIONS):
        category = agent_def["type"]
        agent_name_snake = agent_def["name"].lower().replace(" ", "_").replace("/", "_")
        
        # Generate file content
        content = generate_agent_file(agent_def, index)
        
        # Write to file
        file_path = base_path / category / f"{agent_name_snake}_agent.py"
        file_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        categories[category].append(agent_name_snake)
        print(f"Generated: {file_path}")
    
    # Generate __init__.py files for each category
    for category, agents in categories.items():
        init_path = base_path / category / "__init__.py"
        
        init_content = f'''"""
{category.title()} Agents

This module contains all {category} specialized agents.
"""

'''
        
        for agent in agents:
            class_name = "".join(word.title() for word in agent.split("_"))
            init_content += f"from .{agent}_agent import {class_name}Agent\n"
        
        init_content += f'''

__all__ = [
'''
        
        for agent in agents:
            class_name = "".join(word.title() for word in agent.split("_"))
            init_content += f'    "{class_name}Agent",\n'
        
        init_content += "]\n"
        
        with open(init_path, 'w') as f:
            f.write(init_content)
        
        print(f"Generated: {init_path}")
    
    # Generate master agents __init__.py
    master_init = base_path / "__init__.py"
    master_content = '''"""
Multi-Agentic AI System - Agent Package

This package contains 100 specialized AI agents organized by category.
All agents are OpenAI compatible, MCP compliant, and support A2A protocol.
"""

__version__ = "0.1.0"

# Import all agent categories
from . import programming
from . import devops
from . import documentation
from . import testing
from . import security
from . import data
from . import design
from . import communication
from . import monitoring
from . import automation

__all__ = [
    "programming",
    "devops",
    "documentation",
    "testing",
    "security",
    "data",
    "design",
    "communication",
    "monitoring",
    "automation",
]
'''
    
    with open(master_init, 'w') as f:
        f.write(master_content)
    
    print(f"\n✓ Successfully generated {len(AGENT_DEFINITIONS)} specialized agents!")
    print(f"\nAgent Distribution:")
    for category, agents in categories.items():
        print(f"  - {category.title()}: {len(agents)} agents")


if __name__ == "__main__":
    main()
