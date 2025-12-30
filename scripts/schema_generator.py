#!/usr/bin/env python3
"""
OpenAI Schema Generator for Shell Functions
Converts shell functions to OpenAI-compatible function calling schemas.
"""

import os
import re
import json
import argparse
from pathlib import Path


def generate_openai_schema(function_data):
    """Generate OpenAI function calling schema from shell function."""
    name = function_data["name"]
    docstring = function_data.get("docstring", "")
    safety = function_data.get("safety", "supervision")

    # Parse docstring for parameters
    parameters = parse_docstring_parameters(docstring)
    description = extract_description(docstring)

    schema = {
        "type": "function",
        "function": {
            "name": name,
            "description": description or f"Execute shell function {name}",
            "parameters": {"type": "object", "properties": {}, "required": []},
        },
        "metadata": {
            "safety": safety,
            "file": function_data.get("file", ""),
            "line": function_data.get("line", 0),
            "category": function_data.get("category", "utility"),
        },
    }

    # Add parameters to schema
    for param in parameters:
        schema["function"]["parameters"]["properties"][param["name"]] = {
            "type": param.get("type", "string"),
            "description": param.get("description", f"Parameter {param['name']}"),
        }

        if param.get("required", False):
            schema["function"]["parameters"]["required"].append(param["name"])

    return schema


def parse_docstring_parameters(docstring):
    """Extract parameters from docstring."""
    parameters = []
    lines = docstring.split("\n")

    for line in lines:
        line = line.strip()
        if line.startswith("# @param "):
            parts = line[9:].split(":", 1)
            if len(parts) == 2:
                param_name = parts[0].strip()
                param_desc = parts[1].strip()

                # Extract type from description
                param_type = "string"
                if "(type:" in param_desc:
                    type_match = re.search(r"\(type:\s*(\w+)\)", param_desc)
                    if type_match:
                        param_type = type_match.group(1)

                parameters.append(
                    {
                        "name": param_name,
                        "description": param_desc,
                        "type": param_type,
                        "required": "[optional]" not in param_desc,
                    }
                )

    return parameters


def extract_description(docstring):
    """Extract description from docstring."""
    lines = docstring.split("\n")

    for line in lines:
        line = line.strip()
        if line.startswith("# @description "):
            return line[14:].strip()

    return ""


def generate_schemas_from_functions(functions_data):
    """Generate OpenAI schemas from all functions."""
    schemas = {}
    safe_functions = []
    supervision_functions = []
    unsafe_functions = []

    for function_data in functions_data:
        name = function_data["name"]
        schema = generate_openai_schema(function_data)

        # Only include safe functions for immediate use
        safety = function_data.get("safety", "supervision")

        if safety == "safe":
            safe_functions.append(schema)
            schemas[name] = schema
        elif safety == "supervision":
            supervision_functions.append(schema)
            schemas[name] = schema  # Include but mark for supervision
        else:
            unsafe_functions.append(schema)
            # Don't include unsafe functions in main schema

    # Create organized schema registry
    schema_registry = {
        "safe_tools": safe_functions,
        "supervision_tools": supervision_functions,
        "unsafe_tools": unsafe_functions,
        "metadata": {
            "total_functions": len(functions_data),
            "safe_count": len(safe_functions),
            "supervision_count": len(supervision_functions),
            "unsafe_count": len(unsafe_functions),
            "generated_by": "bash.d AI Documentation System",
        },
        "tool_schemas": schemas,
    }

    return schema_registry


def main():
    parser = argparse.ArgumentParser(
        description="Generate OpenAI schemas from documented functions"
    )
    parser.add_argument(
        "--input", required=True, help="Input JSON file with documented functions"
    )
    parser.add_argument("--output", required=True, help="Output JSON file for schemas")

    args = parser.parse_args()

    try:
        with open(args.input, "r") as f:
            data = json.load(f)
    except Exception as e:
        print(f"❌ Error loading input file: {e}")
        return

    functions = data.get("functions", [])
    print(f"🔧 Generating OpenAI schemas for {len(functions)} functions...")

    # Generate schemas
    schema_registry = generate_schemas_from_functions(functions)

    # Save schemas
    with open(args.output, "w") as f:
        json.dump(schema_registry, f, indent=2)

    print(f"✅ Schemas saved: {args.output}")

    # Print summary
    metadata = schema_registry["metadata"]
    print(f"📊 Schema Summary:")
    print(f"   Total Functions: {metadata['total_functions']}")
    print(f"   Safe Tools: {metadata['safe_count']}")
    print(f"   Supervision Required: {metadata['supervision_count']}")
    print(f"   Unsafe (Excluded): {metadata['unsafe_count']}")
    print(
        f"   Available for AI: {metadata['safe_count'] + metadata['supervision_count']}"
    )


if __name__ == "__main__":
    main()
