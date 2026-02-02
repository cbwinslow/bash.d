# AI Agent Guidelines

## Purpose
This directory stores all data processed by the bash.d ecosystem. Includes census data, ACS surveys, government datasets, AI model data, and your personal content.

## File Placement Rules
- `census/`: US Census Bureau data and processing
- `acs/`: American Community Survey data
- `government/`: Federal government datasets (FBI, Congress, etc.)
- `legislation/`: Legislative data from OpenStates, OpenLegislation
- `ai_models/`: AI model data, training sets, outputs
- `financial/`: Financial data, market analysis, portfolio tracking
- `content/`: Your blog posts, articles, writings
- `processed/`: Cleaned and processed data ready for use
- `cache/`: Temporary cached data for performance

## File Naming Conventions
- Raw data: `source_raw_YYYY-MM-DD.format`
- Processed data: `source_processed_YYYY-MM-DD.format`
- Cache files: `source_cache_hash.tmp`
- Metadata: `source_metadata.json`
- Backups: `source_backup_YYYY-MM-DD.tar.gz`

## Automation Instructions
- AI agents should always check for existing cache before downloading
- Implement proper data validation after processing
- Use consistent schema for all processed data
- Maintain metadata files for data lineage
- Implement data retention policies
- Use compression for archived data

## Integration Points
- Data sources write to this directory
- Processing scripts read from here
- Web APIs serve data from `processed/` subdirectory
- AI models use data from `ai_models/`
- Backup systems archive this directory

## Context
This is the data lake for the entire bash.d ecosystem. It contains:
- Primary data sources for your research and analysis
- Processed data ready for public consumption
- AI training data and model outputs
- Personal content and writings
- Cached data for performance optimization

## Data Quality Standards
- All data must have associated metadata
- Implement schema validation for structured data
- Use consistent date formats (ISO 8601)
- Include data source and processing timestamps
- Validate data integrity with checksums
- Document data transformation steps

## Security Notes
- Encrypt sensitive personal data at rest
- Use access controls for restricted datasets
- Implement audit logging for data access
- Follow data provider terms of service
- Respect privacy regulations (GDPR, CCPA)
- Use secure connections for data transfers

## Performance Optimization
- Use appropriate file formats (Parquet for large datasets)
- Implement data partitioning for large files
- Use compression for storage efficiency
- Cache frequently accessed data
- Implement lazy loading for large datasets
- Use streaming for real-time data processing