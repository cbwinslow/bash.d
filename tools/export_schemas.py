#!/usr/bin/env python3
"""
Export Tool Schemas Script

Exports all tool schemas in multiple formats (OpenAI, MCP, JSON).
Usage: python tools/export_schemas.py
"""

import json
import os
from pathlib import Path
from registry import get_registry


def main():
    """Export tool schemas in all supported formats."""
    
    # Initialize registry
    registry = get_registry()
    
    # Create output directory
    output_dir = Path("schemas")
    output_dir.mkdir(exist_ok=True)
    
    print(f"Exporting tool schemas...")
    print(f"Total tools registered: {registry.get_tool_count()}")
    print()
    
    # Export OpenAI format
    print("Exporting OpenAI function calling format...")
    openai_schemas = registry.export_schemas("openai")
    openai_file = output_dir / "openai_tools.json"
    with open(openai_file, 'w') as f:
        json.dump(openai_schemas, f, indent=2)
    print(f"  ✓ Saved {len(openai_schemas)} tools to {openai_file}")
    
    # Export MCP format
    print("Exporting MCP (Model Context Protocol) format...")
    mcp_schemas = registry.export_schemas("mcp")
    mcp_file = output_dir / "mcp_tools.json"
    with open(mcp_file, 'w') as f:
        json.dump(mcp_schemas, f, indent=2)
    print(f"  ✓ Saved {len(mcp_schemas)} tools to {mcp_file}")
    
    # Export generic JSON format
    print("Exporting generic JSON format...")
    json_schemas = registry.export_schemas("json")
    json_file = output_dir / "tools.json"
    with open(json_file, 'w') as f:
        json.dump(json_schemas, f, indent=2)
    print(f"  ✓ Saved {len(json_schemas)} tools to {json_file}")
    
    # Generate documentation
    print("\nGenerating documentation...")
    doc = registry.generate_documentation()
    doc_file = output_dir / "TOOLS.md"
    with open(doc_file, 'w') as f:
        f.write(doc)
    print(f"  ✓ Saved documentation to {doc_file}")
    
    # Export statistics
    print("\nGenerating statistics...")
    stats = registry.get_statistics()
    stats_file = output_dir / "statistics.json"
    with open(stats_file, 'w') as f:
        json.dump(stats, f, indent=2)
    print(f"  ✓ Saved statistics to {stats_file}")
    
    # Create combined export
    print("\nCreating combined export...")
    combined = {
        "metadata": {
            "version": "1.0.0",
            "total_tools": registry.get_tool_count(),
            "categories": list(registry.get_category_counts().keys()),
            "formats": ["openai", "mcp", "json"]
        },
        "statistics": stats,
        "tools": {
            "openai": openai_schemas,
            "mcp": mcp_schemas,
            "json": json_schemas
        }
    }
    combined_file = output_dir / "all_tools.json"
    with open(combined_file, 'w') as f:
        json.dump(combined, f, indent=2)
    print(f"  ✓ Saved combined export to {combined_file}")
    
    # Print summary
    print("\n" + "="*60)
    print("EXPORT SUMMARY")
    print("="*60)
    print(f"Total Tools Exported: {registry.get_tool_count()}")
    print("\nTools by Category:")
    for category, count in sorted(stats['by_category'].items()):
        print(f"  - {category.title()}: {count}")
    print("\nOutput Files:")
    print(f"  - {openai_file}")
    print(f"  - {mcp_file}")
    print(f"  - {json_file}")
    print(f"  - {doc_file}")
    print(f"  - {stats_file}")
    print(f"  - {combined_file}")
    print("\n✓ Export complete!")


if __name__ == "__main__":
    main()
