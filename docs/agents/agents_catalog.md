# AI Agents Catalog — OpenAI-compatible (draft)

This catalog contains a curated list of AI agents intended for the bash.d multi-agent system. Each entry is a concise description and can be expanded into a pydantic config and an OpenAI-compatible instruction/prompt template.

Goal: produce a useful, actionable list of 50–100 agent roles to cover common development, devops, security, documentation, testing, data, design, and productivity needs.

---

## How to use

- Each agent should have a pydantic model describing: id, name, category, description, capabilities, default model/provider config (OpenAI compatible), prompts or system messages, allowed tools, expected outputs, and safety/usage notes.
- After finalizing the catalog we can generate YAML/JSON config files and code stubs for each agent.

---

## Local Integrations

- Bitwarden Secrets Access — use `bash_functions.d/tools/bw_agent.sh` for agent-safe Bitwarden queries; secrets live in `~/.bash_secrets.d/env/root.env` and are never committed.

---

## Categories

- Programming
- DevOps & Infrastructure
- Security
- Testing & QA
- Documentation & Writing
- Data & Analysis
- Design & UX
- Automation & Productivity
- Monitoring & Observability
- Cloud & Platform
- Communication & Support

---

## Agent list (75 agents)

Note: Each entry lists: Name — short description

### Programming (20)
1. Python Backend Developer — scaffolds, improves, and reviews backend Python services (FastAPI, Django, etc.).
2. JavaScript Full-Stack Developer — builds front-end + Node.js backend patterns and integrations.
3. TypeScript Architect — enforces types, designs typesafe APIs and libraries.
4. Rust Systems Programmer — low-level systems, performance, and memory-safe design.
5. Go Microservices Developer — designs scalable microservices and idiomatic Go code.
6. Java Enterprise Engineer — Java ecosystem, Spring, design for enterprise deployments.
7. Frontend UI Developer — React/Vue/Svelte components, accessibility, and state management.
8. Mobile Dev (iOS/Android) — mobile app scaffolding, UI guidelines, packaging.
9. Dev Experience Scripter — CLI and automation scripts, developer ergonomics.
10. Code Reviewer — performs code reviews and suggests fixes and improvements.
11. Refactor Specialist — plans and executes safe refactors with tests.
12. Plugin/Extension Developer — builds editor extensions (VSCode) and plugins.
13. Performance Profiler — analyzes code to suggest hotspots and profiling guidance.
14. Legacy Migration Specialist — converts legacy codebases (monolith -> modular services).
15. Security-Focused Developer — identifies insecure patterns and suggests fixes in code.
16. Dependency Management Agent — updates pins, resolves vulnerabilities in deps.
17. CI/CD Pipeline Developer — author pipelines for GitHub Actions, GitLab CI, etc.
18. API Design Specialist — designs OpenAPI/GraphQL APIs with examples and docs.
19. Test-Driven Development Coach — creates tests and enforces testing patterns.
20. Documentation-Driven Development Agent — ensures code is well-documented and examples exist.

### DevOps & Infrastructure (10)
21. Docker Container Expert — builds optimized Dockerfiles and multi-stage builds.
22. Kubernetes Orchestration Specialist — writes manifests, Helm charts and troubleshooting k8s clusters.
23. Terraform Infrastructure Engineer — manages IaC for multi-cloud infrastructure.
24. CI/CD Orchestrator — integrates test, build, and deploy stages with rollback strategies.
25. Infrastructure Security Auditor — checks IaC for insecure defaults and misconfigurations.
26. Release Manager — coordinates versioning, release notes, changelogs, and semantic version strategies.
27. System Hardening Specialist — OS/container hardening recommendations and scripts.
28. Storage & Backup Engineer — designs backup, retention, and disaster recovery plans.
29. Networking & Connectivity Specialist — network design, firewall, VPNs, DNS and troubleshooting.
30. Secrets & Config Manager — recommends secure vaulting, rotation, and environment handling best practices.

### Security (6)
31. Vulnerability Scanner — inspects code and deps for known CVEs and insecure patterns.
32. Code Security Reviewer — provides secure-by-design code review suggestions.
33. Secrets Detector — scans repo history & configs for leaked secrets and exposure.
34. Penetration Test Planner — designs pentest scenarios, threat models and test harnesses.
35. Compliance Auditor — compares system architecture to relevant standards (SOC2, GDPR, PCI).
36. SAST Assistant — static analysis recommendations and prioritized remediation paths.

### Testing & QA (6)
37. Unit Test Developer — generates unit tests, mocks, and asserts for codebases.
38. Integration Test Engineer — designs and executes integration/E2E tests across services.
39. Performance Test Engineer — creates benchmarks, load tests and performance reports.
40. Flaky Test Investigator — triages and de-flakes intermittent test failures.
41. Accessibility (a11y) Tester — audits UI for compliance, readable reports, remediation steps.
42. Automation QA Bot — manages test pipelines and post-deploy validation checks.

### Documentation & Writing (6)
43. Technical Writer — produces clear docs from code, examples, and API references.
44. API Documentation Generator — autogenerates OpenAPI docs, examples, and interactive snippets.
45. Tutorial Creator — step-by-step guides, best-practice walkthroughs, and learning plans.
46. Release Notes Composer — generates structured release notes from commit history.
47. Onboarding Guide Author — builds onboarding docs and checklists for new contributors.
48. Changelog Curator — creates semantic changelogs and highlights for end-users.

### Data & Analysis (6)
49. Data Engineer — ETL pipelines, data migration, storage design and schema validation.
50. Data Scientist — model selection, experiment design, feature engineering guidance.
51. Analytics Dashboard Builder — constructs queries, dashboards, and visualizations.
52. SQL Optimizer — inspects queries and suggests indexing and rewrite strategies.
53. Data Privacy Advisor — anonymization, retention and compliance for PII.
54. MLOps Engineer — model packaging, reproducibility, and deployment best practices.

### Design & UX (4)
55. UX Research Assistant — analyzes user feedback, designs A/B tests and user flows.
56. Visual Designer — creates style guides, color systems and quick mockups.
57. Accessibility Designer — designs inclusive UI patterns and checks contrast/keyboard navigation.
58. Interaction Designer — microinteractions and motion guidance.

### Automation & Productivity (6)
59. Workflow Orchestrator — composes and runs multi-step automation workflows.
60. Scheduler & Cron Manager — manages scheduled tasks, failure handling and alerting.
61. Personal Productivity Assistant — automates repetitive dev tasks and local environment ops.
62. Snippet & Template Manager — creates reusable project templates and snippets.
63. Local Developer Environment Builder — configures dev containers, dotfiles, and onboarding scripts.
64. Task Prioritization Assistant — ranks backlog items and suggests sprint scope.

### Monitoring & Observability (3)
65. Metrics Engineer — defines metrics, instrumentation points and dashboards.
66. Log Analysis Agent — parses logs, detects anomalies, and provides remediation steps.
67. Alerting & Runbook Assistant — writes runbooks and automates incident response triggers.

### Cloud & Platform (3)
68. Cloud Cost Optimizer — finds cost-saving opportunities in cloud infra and reservations.
69. Platform Integrator — configures third-party integrations and API connectors.
70. Multi-Cloud Orchestrator — helps design multi-cloud deployments and migration plans.

### Communication & Support (2)
71. Chatbot & Support Agent — triages support tickets and answers FAQ with context.
72. Release Communication Manager — drafts release messaging, announcements and user-facing copy.

### Special-purpose & Research (3)
73. Architecture Reviewer — holistic architecture reviews with trade-offs and future-proofing guidance.
74. Ethical AI Auditor — examines models and system flows for bias and fairness concerns.
75. Research Assistant — literature review, experiment summarization, and design suggestions.

---

## Next steps (suggested)

1. Choose an initial subset (e.g., 15–30 core agents) to implement first with complete OpenAI-compatible configs and prompt templates.  
2. Define a common agent config schema (JSON/YAML) that maps to pydantic models and OpenAI system/user messages.  
3. Generate config files into `configs/agents/` and optionally create skeleton Python agent classes under `agents/` or `scripts/` to bootstrap the system.

---

## Notes & considerations

- Each agent should have a safety strategy (input validation, rate limits, opt-out behavior) and usage constraints.  
- Tool access (e.g., system, file, network tools) must be whitelisted per-agent.  
- Prefer small, focused agents over very large generalist agents to facilitate specialization and observability.
