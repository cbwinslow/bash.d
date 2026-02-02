# AI Agent Guidelines

## Purpose
This directory contains your public platform code - blog engine, data portal, API gateway, and content management system for cloudcurio.cc.

## File Placement Rules
- `blog_engine.sh`: Blog post creation, editing, publishing workflow
- `data_portal.sh`: Public data interface with search and pagination
- `api_gateway.sh`: Unified API for all data sources and services
- `content_cms.sh`: Content management, versioning, workflow
- `search_engine.sh`: Full-text search across all content
- `user_system.sh`: User registration, profiles, authentication
- `comment_system.sh`: Comments, moderation, notifications
- `analytics.sh`: Visitor tracking, content performance, user behavior

## File Naming Conventions
- Functions: `system_action_description()`
- Templates: `template_type.html.mustache`
- Configs: `system_config.yaml`
- Cache: `system_cache_type.tmp`
- Logs: `system_YYYY-MM-DD.log`

## Automation Instructions
- AI agents should validate content before publishing
- Implement proper content workflow (draft -> review -> publish)
- Use responsive design for all web interfaces
- Implement proper SEO for all content
- Use caching for performance optimization
- Implement rate limiting for public APIs
- Validate all user inputs and comments

## Integration Points
- Uses data from `../data/processed/`
- Serves content via Cloudflare Workers
- Stores user data in secure database
- Integrates with authentication system
- Uses Bitwarden for credential management
- Logs all activities to central system

## Context
This is the public-facing layer of bash.d ecosystem. It provides:
- Blog platform for your writings and tutorials
- Data portal for public access to integrated datasets
- API gateway for programmatic access
- User management and community features
- Search and discovery capabilities
- Analytics and performance monitoring

## Content Types Supported
- **Blog Posts**: Markdown with front matter
- **Tutorials**: Step-by-step guides with code
- **Data Visualizations**: Interactive charts and graphs
- **API Documentation**: Auto-generated from code
- **Project Showcases**: Featured projects and demos
- **Research Papers**: Academic and industry research

## Technical Features
- **Responsive Design**: Mobile-first approach
- **Progressive Enhancement**: Works without JavaScript
- **SEO Optimization**: Meta tags, structured data, sitemaps
- **Performance**: CDN, caching, compression
- **Accessibility**: WCAG 2.1 AA compliance
- **Internationalization**: Multi-language support

## Security Standards
- HTTPS-only communication
- CSRF protection for all forms
- XSS protection and input sanitization
- Rate limiting on all endpoints
- Content Security Policy headers
- Regular security audits
- User data encryption at rest

## Performance Targets
- Page load time: <2 seconds
- Time to Interactive: <3 seconds
- Core Web Vitals: Good scores
- Uptime: 99.9% availability
- CDN cache hit rate: >90%

## Community Features
- User registration and profiles
- Comment system with moderation
- Content sharing and bookmarking
- Newsletter subscription
- RSS feeds for all content
- Social media integration