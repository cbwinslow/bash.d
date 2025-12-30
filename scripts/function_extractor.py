#!/usr/bin/env python3
"""
Function Extractor for Bash.d AI Documentation System
"""

import os
import json
import argparse
from pathlib import Path


def extract_functions(directory):
    """Extract function information from shell files."""
    functions = []
    shell_files = list(Path(directory).rglob("*.sh"))

    for file_path in shell_files:
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()

            # Simple pattern to find function definitions
            import re

            pattern = r"^([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\s*\)"

            for line_num, line in enumerate(content.split("\n"), 1):
                match = re.match(pattern, line.strip())
                if match:
                    functions.append(
                        {
                            "name": match.group(1),
                            "file": str(file_path.relative_to(directory)),
                            "line": line_num,
                            "signature": line.strip(),
                        }
                    )
        except Exception as e:
            print(f"Error processing {file_path}: {e}")

    return functions


def main():
    parser = argparse.ArgumentParser(description="Extract shell function information")
    parser.add_argument("--input-dir", required=True, help="Input directory")
    parser.add_argument("--output-dir", required=True, help="Output directory")
    parser.add_argument("--format", default="json", help="Output format")

    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    functions = extract_functions(args.input_dir)

    result = {
        "summary": {"total_functions": len(functions)},
        "functions": functions,
    }

    output_file = output_dir / f"functions.{args.format}"

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2)

    print(f"Found {len(functions)} functions")
    print(f"Results saved to: {output_file}")


if __name__ == "__main__":
    main()
