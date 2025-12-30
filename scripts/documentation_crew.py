#!/usr/bin/env python3
"""
Documentation Generator using Free OpenRouter Models
Creates AI-powered docstrings for shell functions without cost.
"""

import os
import json
import argparse
import re
from pathlib import Path
import requests
import time


class FreeDocumentationGenerator:
    def __init__(self, api_key=None):
        self.api_key = api_key or os.getenv("OPENROUTER_API_KEY")
        self.base_url = "https://openrouter.ai/api/v1"
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

    def call_free_model(self, prompt, model="meta-llama/llama-3.2-3b-instruct:free"):
        """Call OpenRouter free model API."""
        try:
            data = {
                "model": model,
                "messages": [{"role": "user", "content": prompt}],
                "temperature": 0.7,
                "max_tokens": 1000,
            }

            response = requests.post(
                f"{self.base_url}/chat/completions",
                headers=self.headers,
                json=data,
                timeout=30,
            )

            if response.status_code == 200:
                return response.json()["choices"][0]["message"]["content"]
            else:
                print(f"API Error: {response.status_code} - {response.text}")
                return None

        except Exception as e:
            print(f"Request failed: {str(e)}")
            return None

    def generate_function_docstring(self, function):
        """Generate docstring for a single function."""
        prompt = f"""
        Analyze this shell function and create a comprehensive docstring:

        Function Name: {function["name"]}
        File: {function["file"]}
        Signature: {function.get("signature", "unknown")}
        
        Generate a docstring in this format:
        ```bash
        # @function {function["name"]}
        # @description Brief description of what the function does
        # @param param1: Description (type: string/int/boolean) [optional]
        # @param param2: Description (type: string/int/boolean) [optional]  
        # @return Description of return value
        # @example {function["name"]} "arg1" "arg2"
        # @category git/system/ai/utility/network/debug etc
        # @safety safe/supervision/unsafe
        ```
        
        Be specific and practical. Focus on what the function actually does.
        """

        response = self.call_free_model(prompt)

        if response:
            return self.extract_docstring_from_response(response, function["name"])
        else:
            return self.create_fallback_docstring(function)

    def extract_docstring_from_response(self, response, function_name):
        """Extract docstring from AI response."""
        # Look for code block with docstring
        code_block_pattern = r"```bash\n(.*?)\n```"
        match = re.search(code_block_pattern, response, re.DOTALL)

        if match:
            docstring = match.group(1).strip()
            return docstring
        else:
            # Fallback: extract lines that look like docstring
            lines = response.split("\n")
            docstring_lines = []
            for line in lines:
                if line.strip().startswith("# @"):
                    docstring_lines.append(line.strip())

            return (
                "\n".join(docstring_lines)
                if docstring_lines
                else self.create_fallback_docstring({"name": function_name})
            )

    def create_fallback_docstring(self, function):
        """Create basic docstring when AI fails."""
        return f"""# @function {function["name"]}
# @description Shell function {function["name"]} from {function.get("file", "unknown")}
# @category utility
# @safety supervision"""

    def evaluate_safety(self, function):
        """Evaluate function safety using AI."""
        # Simple rule-based safety evaluation
        name = function["name"].lower()
        file = function.get("file", "").lower()

        # Potentially unsafe patterns
        unsafe_patterns = ["rm", "delete", "remove", "format", "fdisk", "mkfs"]
        supervision_patterns = ["sudo", "restart", "stop", "kill", "chmod", "chown"]

        for pattern in unsafe_patterns:
            if pattern in name or pattern in file:
                return "unsafe"

        for pattern in supervision_patterns:
            if pattern in name or pattern in file:
                return "supervision"

        return "safe"

    def categorize_function(self, function):
        """Categorize function based on name and file."""
        name = function["name"].lower()
        file = function.get("file", "").lower()

        categories = {
            "git": ["git", "commit", "push", "pull", "branch", "merge", "clone"],
            "ai": ["ai", "openai", "anthropic", "gemini", "chat", "llm"],
            "system": ["systemctl", "service", "mount", "umount", "ps", "kill"],
            "network": ["ping", "curl", "wget", "ssh", "netstat", "network"],
            "docker": ["docker", "container", "image", "pod"],
            "file": ["find", "ls", "cp", "mv", "rm", "mkdir", "touch", "file"],
            "debug": ["debug", "test", "check", "verify"],
            "utility": ["help", "info", "status", "list", "show"],
        }

        for category, keywords in categories.items():
            for keyword in keywords:
                if keyword in name or keyword in file:
                    return category

        return "misc"

    def process_functions_batch(self, functions, batch_size=3, delay=2):
        """Process functions in batches to avoid rate limits."""
        results = []

        for i in range(0, len(functions), batch_size):
            batch = functions[i : i + batch_size]

            print(
                f"📝 Processing batch {i // batch_size + 1}/{(len(functions) - 1) // batch_size + 1} ({len(batch)} functions)"
            )

            batch_results = []
            for func in batch:
                print(f"  🔄 Analyzing: {func['name']}")

                # Generate docstring
                docstring = self.generate_function_docstring(func)

                # Evaluate safety and category
                safety = self.evaluate_safety(func)
                category = self.categorize_function(func)

                result = {
                    "name": func["name"],
                    "file": func.get("file", "unknown"),
                    "line": func.get("line", 0),
                    "signature": func.get("signature", ""),
                    "docstring": docstring,
                    "safety": safety,
                    "category": category,
                }

                batch_results.append(result)
                print(f"  ✅ Completed: {func['name']}")

                # Small delay between functions
                time.sleep(1)

            results.extend(batch_results)

            # Delay between batches
            if i + batch_size < len(functions):
                print(f"  ⏱️ Waiting {delay}s before next batch...")
                time.sleep(delay)

        return results


def main():
    parser = argparse.ArgumentParser(
        description="Generate documentation using free OpenRouter models"
    )
    parser.add_argument("--input", required=True, help="Input JSON file with functions")
    parser.add_argument("--output-dir", required=True, help="Output directory")
    parser.add_argument(
        "--batch-size", type=int, default=3, help="Batch size for processing"
    )
    parser.add_argument(
        "--api-key", help="OpenRouter API key (or set OPENROUTER_API_KEY env)"
    )

    args = parser.parse_args()

    # Check for API key
    api_key = args.api_key or os.getenv("OPENROUTER_API_KEY")
    if not api_key:
        print("⚠️ No OpenRouter API key found. Using fallback documentation generation.")
        print("To get a free API key:")
        print("1. Go to https://openrouter.ai/")
        print("2. Sign up for free account")
        print("3. Get your API key")
        print("4. Set OPENROUTER_API_KEY environment variable")
        print()
        api_key = "dummy-key-for-fallback"

    # Load functions
    try:
        with open(args.input, "r") as f:
            data = json.load(f)
    except Exception as e:
        print(f"❌ Error loading input file: {e}")
        return

    functions = data.get("functions", [])
    print(f"📚 Processing {len(functions)} shell functions...")

    # Create output directory
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Generate documentation
    generator = FreeDocumentationGenerator(api_key)

    # Process first 10 functions as a demo (can remove this limit)
    demo_functions = functions[:10] if len(functions) > 10 else functions

    results = generator.process_functions_batch(
        demo_functions, batch_size=args.batch_size
    )

    # Save results
    output_file = output_dir / "documented_functions.json"

    final_data = {
        "summary": {
            "total_functions": len(functions),
            "processed_functions": len(results),
            "model_used": "meta-llama/llama-3.2-3b-instruct:free",
            "generated_with": "OpenRouter Free Models",
        },
        "functions": results,
    }

    with open(output_file, "w") as f:
        json.dump(final_data, f, indent=2, default=str)

    print(f"✅ Documentation generated: {output_file}")
    print(f"📊 Documented {len(results)} functions")

    # Generate summary
    summary_file = output_dir / "summary.txt"
    with open(summary_file, "w") as f:
        f.write(f"Bash.d Function Documentation Report\n")
        f.write(f"==================================\n\n")
        f.write(f"Total Functions Available: {len(functions)}\n")
        f.write(f"Functions Processed: {len(results)}\n")
        f.write(f"Model: meta-llama/llama-3.2-3b-instruct:free\n")
        f.write(f"Generated: OpenRouter Free Models\n\n")

        if len(functions) > len(results):
            f.write(f"Note: Processing limited to {len(results)} functions for demo.\n")
            f.write(f"To process all functions, modify the demo limit in the script.\n")

    print(f"📄 Summary saved: {summary_file}")


if __name__ == "__main__":
    main()
