# AI Agent Guidelines

## Purpose
This directory contains unified documentation for bash.d ecosystem including API documentation, architecture guides, and contribution guidelines.

## File Placement Rules
- `api.md`: Auto-generated API documentation
- `architecture.md`: System architecture and design decisions
- `contributing.md`: Contribution guidelines and standards
- `deployment.md`: Deployment guides and procedures
- `security.md`: Security policies and best practices
- `user_guide.md`: End-user documentation
- `developer_guide.md`: Developer documentation

## File Naming Conventions
- Documentation files: `topic.md`
- API docs: `api_version.md`
- Guides: `guide_topic_name.md`
- Tutorials: `tutorial_step_by_step.md`
- Architecture: `arch_component_name.md`

## Automation Instructions
- AI agents should keep documentation synchronized with code
- Generate API documentation from source code
- Update documentation with every feature change
- Validate all code examples in documentation
- Implement proper versioning of documentation
- Use consistent formatting and style

## Integration Points
- Documents all components from `../src/`
- Explains plugin architecture from `../plugins/`
- Details infrastructure setup from `../infrastructure/`
- Guides platform usage from `../platform/`
- References configuration options from `../config/`
- Includes testing procedures from `../tests/`

## Context
This directory provides comprehensive documentation for bash.d ecosystem:
- Single source of truth for all system information
- Auto-generated and manually maintained documentation
- User guides for different skill levels
- Developer documentation for contributors
- API documentation for integrations
- Architecture documentation for maintainers

## Documentation Standards
- Use Markdown format with proper front matter
- Include code examples for all features
- Provide step-by-step tutorials
- Use diagrams for complex concepts
- Include troubleshooting sections
- Maintain table of contents for long documents

## Content Types
- **User Guides**: End-user documentation
- **Developer Docs**: Technical documentation
- **API Reference**: Complete API documentation
- **Tutorials**: Step-by-step learning guides
- **Architecture**: System design and decisions
- **Deployment**: Production deployment guides

## Quality Standards
- All code examples must be tested
- Documentation must be version-controlled
- Include accessibility considerations
- Use consistent terminology and style
- Provide multiple learning paths
- Include performance considerations

## Automation Features
- Auto-generate API docs from source code
- Update table of contents automatically
- Validate all internal links
- Generate PDF versions for offline use
- Create search index for documentation
- Maintain changelog automatically

## Localization Support
- Use translatable strings for UI elements
- Provide region-specific examples
- Include timezone considerations
- Support multiple date formats
- Use metric and imperial units
- Consider cultural differences in examples