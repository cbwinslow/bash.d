"""
Text Processing Tools

This module provides comprehensive text processing and manipulation tools
that are OpenAI-compatible and follow the MCP protocol.
"""

from typing import Dict, Any, List, Optional
from .base import BaseTool, ToolCategory, ToolParameter, ToolResult
import re
import json
import hashlib
import base64
from datetime import datetime


class CountWords(BaseTool):
    """
    Count words in a text.
    
    Counts the number of words, characters, lines, and sentences in text.
    """
    
    def __init__(self):
        super().__init__(
            name="count_words",
            category=ToolCategory.DATA,
            description="Count words, characters, lines, and sentences in text",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to analyze",
                    required=True
                )
            ],
            tags=["text", "count", "analyze"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        
        words = len(text.split())
        characters = len(text)
        characters_no_spaces = len(text.replace(" ", "").replace("\n", "").replace("\t", ""))
        lines = len(text.splitlines())
        sentences = len([s for s in re.split(r'[.!?]+', text) if s.strip()])
        
        return {
            "words": words,
            "characters": characters,
            "characters_no_spaces": characters_no_spaces,
            "lines": lines,
            "sentences": sentences,
            "average_word_length": round(characters_no_spaces / words, 2) if words > 0 else 0
        }


class FindReplace(BaseTool):
    """
    Find and replace text.
    
    Searches for a pattern and replaces it with new text.
    """
    
    def __init__(self):
        super().__init__(
            name="find_replace",
            category=ToolCategory.DATA,
            description="Find and replace text or patterns",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to process",
                    required=True
                ),
                ToolParameter(
                    name="find",
                    type="string",
                    description="Text or pattern to find",
                    required=True
                ),
                ToolParameter(
                    name="replace",
                    type="string",
                    description="Text to replace with",
                    required=True
                ),
                ToolParameter(
                    name="use_regex",
                    type="boolean",
                    description="Use regex pattern matching",
                    required=False,
                    default=False
                ),
                ToolParameter(
                    name="case_sensitive",
                    type="boolean",
                    description="Case-sensitive matching",
                    required=False,
                    default=True
                )
            ],
            tags=["text", "find", "replace", "regex"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        find = kwargs["find"]
        replace = kwargs["replace"]
        use_regex = kwargs.get("use_regex", False)
        case_sensitive = kwargs.get("case_sensitive", True)
        
        if use_regex:
            flags = 0 if case_sensitive else re.IGNORECASE
            result = re.sub(find, replace, text, flags=flags)
            count = len(re.findall(find, text, flags=flags))
        else:
            if not case_sensitive:
                # Case-insensitive replacement
                pattern = re.compile(re.escape(find), re.IGNORECASE)
                result = pattern.sub(replace, text)
                count = len(pattern.findall(text))
            else:
                result = text.replace(find, replace)
                count = text.count(find)
        
        return {
            "original_length": len(text),
            "result_length": len(result),
            "replacements": count,
            "result": result
        }


class ExtractUrls(BaseTool):
    """
    Extract URLs from text.
    
    Finds and extracts all URLs from the provided text.
    """
    
    def __init__(self):
        super().__init__(
            name="extract_urls",
            category=ToolCategory.DATA,
            description="Extract all URLs from text",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to extract URLs from",
                    required=True
                )
            ],
            tags=["text", "url", "extract", "regex"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        
        url_pattern = r'https?://(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&/=]*)'
        urls = re.findall(url_pattern, text)
        
        return {
            "count": len(urls),
            "urls": list(set(urls)),  # Remove duplicates
            "unique_count": len(set(urls))
        }


class ExtractEmails(BaseTool):
    """
    Extract email addresses from text.
    
    Finds and extracts all email addresses from the provided text.
    """
    
    def __init__(self):
        super().__init__(
            name="extract_emails",
            category=ToolCategory.DATA,
            description="Extract all email addresses from text",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to extract emails from",
                    required=True
                )
            ],
            tags=["text", "email", "extract", "regex"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        
        email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
        emails = re.findall(email_pattern, text)
        
        return {
            "count": len(emails),
            "emails": list(set(emails)),
            "unique_count": len(set(emails))
        }


class SplitText(BaseTool):
    """
    Split text by delimiter.
    
    Splits text into parts using a specified delimiter.
    """
    
    def __init__(self):
        super().__init__(
            name="split_text",
            category=ToolCategory.DATA,
            description="Split text into parts using a delimiter",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to split",
                    required=True
                ),
                ToolParameter(
                    name="delimiter",
                    type="string",
                    description="Delimiter to split on",
                    required=False,
                    default=" "
                ),
                ToolParameter(
                    name="max_splits",
                    type="integer",
                    description="Maximum number of splits (-1 for unlimited)",
                    required=False,
                    default=-1
                )
            ],
            tags=["text", "split", "parse"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        delimiter = kwargs.get("delimiter", " ")
        max_splits = kwargs.get("max_splits", -1)
        
        if max_splits > 0:
            parts = text.split(delimiter, max_splits)
        else:
            parts = text.split(delimiter)
        
        return {
            "parts_count": len(parts),
            "parts": parts
        }


class JoinText(BaseTool):
    """
    Join text parts with delimiter.
    
    Joins an array of text parts using a specified delimiter.
    """
    
    def __init__(self):
        super().__init__(
            name="join_text",
            category=ToolCategory.DATA,
            description="Join text parts with a delimiter",
            parameters=[
                ToolParameter(
                    name="parts",
                    type="array",
                    description="Array of text parts to join",
                    required=True
                ),
                ToolParameter(
                    name="delimiter",
                    type="string",
                    description="Delimiter to join with",
                    required=False,
                    default=" "
                )
            ],
            tags=["text", "join", "concatenate"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        parts = kwargs["parts"]
        delimiter = kwargs.get("delimiter", " ")
        
        result = delimiter.join(str(p) for p in parts)
        
        return {
            "parts_count": len(parts),
            "result_length": len(result),
            "result": result
        }


class TrimWhitespace(BaseTool):
    """
    Trim whitespace from text.
    
    Removes leading and trailing whitespace from text.
    """
    
    def __init__(self):
        super().__init__(
            name="trim_whitespace",
            category=ToolCategory.DATA,
            description="Remove leading and trailing whitespace from text",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to trim",
                    required=True
                ),
                ToolParameter(
                    name="mode",
                    type="string",
                    description="Trim mode: left, right, or both",
                    required=False,
                    default="both",
                    enum=["left", "right", "both"]
                )
            ],
            tags=["text", "trim", "whitespace"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        mode = kwargs.get("mode", "both")
        
        if mode == "left":
            result = text.lstrip()
        elif mode == "right":
            result = text.rstrip()
        else:
            result = text.strip()
        
        return {
            "original_length": len(text),
            "trimmed_length": len(result),
            "removed_chars": len(text) - len(result),
            "result": result
        }


class ChangeCase(BaseTool):
    """
    Change text case.
    
    Converts text to different case styles (upper, lower, title, etc.).
    """
    
    def __init__(self):
        super().__init__(
            name="change_case",
            category=ToolCategory.DATA,
            description="Change text case to different styles",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to convert",
                    required=True
                ),
                ToolParameter(
                    name="case_style",
                    type="string",
                    description="Case style to apply",
                    required=True,
                    enum=["upper", "lower", "title", "capitalize", "sentence"]
                )
            ],
            tags=["text", "case", "format"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        case_style = kwargs["case_style"]
        
        if case_style == "upper":
            result = text.upper()
        elif case_style == "lower":
            result = text.lower()
        elif case_style == "title":
            result = text.title()
        elif case_style == "capitalize":
            result = text.capitalize()
        elif case_style == "sentence":
            # Capitalize first letter of each sentence
            result = '. '.join(s.capitalize() for s in text.split('. '))
        else:
            result = text
        
        return {
            "case_style": case_style,
            "result": result
        }


class HashText(BaseTool):
    """
    Generate hash of text.
    
    Creates cryptographic hash (MD5, SHA1, SHA256, etc.) of text.
    """
    
    def __init__(self):
        super().__init__(
            name="hash_text",
            category=ToolCategory.DATA,
            description="Generate cryptographic hash of text",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to hash",
                    required=True
                ),
                ToolParameter(
                    name="algorithm",
                    type="string",
                    description="Hash algorithm to use",
                    required=False,
                    default="sha256",
                    enum=["md5", "sha1", "sha256", "sha512"]
                )
            ],
            tags=["text", "hash", "crypto", "security"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        algorithm = kwargs.get("algorithm", "sha256")
        
        text_bytes = text.encode('utf-8')
        
        if algorithm == "md5":
            hash_obj = hashlib.md5(text_bytes)
        elif algorithm == "sha1":
            hash_obj = hashlib.sha1(text_bytes)
        elif algorithm == "sha256":
            hash_obj = hashlib.sha256(text_bytes)
        elif algorithm == "sha512":
            hash_obj = hashlib.sha512(text_bytes)
        else:
            raise ValueError(f"Unsupported algorithm: {algorithm}")
        
        return {
            "algorithm": algorithm,
            "hash": hash_obj.hexdigest(),
            "input_length": len(text)
        }


class Base64Encode(BaseTool):
    """
    Encode text to Base64.
    
    Encodes text or binary data to Base64 format.
    """
    
    def __init__(self):
        super().__init__(
            name="base64_encode",
            category=ToolCategory.DATA,
            description="Encode text to Base64 format",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to encode",
                    required=True
                )
            ],
            tags=["text", "base64", "encode"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        
        encoded = base64.b64encode(text.encode('utf-8')).decode('utf-8')
        
        return {
            "original_length": len(text),
            "encoded_length": len(encoded),
            "encoded": encoded
        }


class Base64Decode(BaseTool):
    """
    Decode Base64 to text.
    
    Decodes Base64 encoded text back to original format.
    """
    
    def __init__(self):
        super().__init__(
            name="base64_decode",
            category=ToolCategory.DATA,
            description="Decode Base64 to original text",
            parameters=[
                ToolParameter(
                    name="encoded_text",
                    type="string",
                    description="Base64 encoded text to decode",
                    required=True
                )
            ],
            tags=["text", "base64", "decode"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        encoded_text = kwargs["encoded_text"]
        
        decoded = base64.b64decode(encoded_text).decode('utf-8')
        
        return {
            "encoded_length": len(encoded_text),
            "decoded_length": len(decoded),
            "decoded": decoded
        }


class RemoveDuplicateLines(BaseTool):
    """
    Remove duplicate lines from text.
    
    Removes duplicate lines while preserving order.
    """
    
    def __init__(self):
        super().__init__(
            name="remove_duplicate_lines",
            category=ToolCategory.DATA,
            description="Remove duplicate lines from text",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to process",
                    required=True
                ),
                ToolParameter(
                    name="preserve_order",
                    type="boolean",
                    description="Preserve original line order",
                    required=False,
                    default=True
                )
            ],
            tags=["text", "duplicate", "filter"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        preserve_order = kwargs.get("preserve_order", True)
        
        lines = text.splitlines()
        original_count = len(lines)
        
        if preserve_order:
            seen = set()
            unique_lines = []
            for line in lines:
                if line not in seen:
                    seen.add(line)
                    unique_lines.append(line)
        else:
            unique_lines = list(set(lines))
        
        result = '\n'.join(unique_lines)
        
        return {
            "original_lines": original_count,
            "unique_lines": len(unique_lines),
            "removed_lines": original_count - len(unique_lines),
            "result": result
        }


class SortLines(BaseTool):
    """
    Sort lines in text.
    
    Sorts text lines alphabetically or numerically.
    """
    
    def __init__(self):
        super().__init__(
            name="sort_lines",
            category=ToolCategory.DATA,
            description="Sort lines in text alphabetically or numerically",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to sort",
                    required=True
                ),
                ToolParameter(
                    name="reverse",
                    type="boolean",
                    description="Sort in reverse order",
                    required=False,
                    default=False
                ),
                ToolParameter(
                    name="case_sensitive",
                    type="boolean",
                    description="Case-sensitive sorting",
                    required=False,
                    default=True
                )
            ],
            tags=["text", "sort", "order"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        reverse = kwargs.get("reverse", False)
        case_sensitive = kwargs.get("case_sensitive", True)
        
        lines = text.splitlines()
        
        if case_sensitive:
            sorted_lines = sorted(lines, reverse=reverse)
        else:
            sorted_lines = sorted(lines, key=str.lower, reverse=reverse)
        
        result = '\n'.join(sorted_lines)
        
        return {
            "line_count": len(lines),
            "result": result
        }


class ReverseText(BaseTool):
    """
    Reverse text.
    
    Reverses the order of characters or words in text.
    """
    
    def __init__(self):
        super().__init__(
            name="reverse_text",
            category=ToolCategory.DATA,
            description="Reverse the order of characters or words in text",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to reverse",
                    required=True
                ),
                ToolParameter(
                    name="mode",
                    type="string",
                    description="Reverse mode: characters or words",
                    required=False,
                    default="characters",
                    enum=["characters", "words"]
                )
            ],
            tags=["text", "reverse"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        mode = kwargs.get("mode", "characters")
        
        if mode == "characters":
            result = text[::-1]
        else:  # words
            words = text.split()
            result = ' '.join(reversed(words))
        
        return {
            "mode": mode,
            "result": result
        }


class WrapText(BaseTool):
    """
    Wrap text to specified width.
    
    Wraps text lines to a maximum width.
    """
    
    def __init__(self):
        super().__init__(
            name="wrap_text",
            category=ToolCategory.DATA,
            description="Wrap text lines to a maximum width",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to wrap",
                    required=True
                ),
                ToolParameter(
                    name="width",
                    type="integer",
                    description="Maximum line width",
                    required=False,
                    default=80
                ),
                ToolParameter(
                    name="break_long_words",
                    type="boolean",
                    description="Break words longer than width",
                    required=False,
                    default=True
                )
            ],
            tags=["text", "wrap", "format"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        width = kwargs.get("width", 80)
        break_long_words = kwargs.get("break_long_words", True)
        
        import textwrap
        
        wrapped = textwrap.fill(text, width=width, break_long_words=break_long_words)
        
        return {
            "original_lines": len(text.splitlines()),
            "wrapped_lines": len(wrapped.splitlines()),
            "width": width,
            "result": wrapped
        }


class ExtractNumbers(BaseTool):
    """
    Extract numbers from text.
    
    Finds and extracts all numeric values from text.
    """
    
    def __init__(self):
        super().__init__(
            name="extract_numbers",
            category=ToolCategory.DATA,
            description="Extract all numbers from text",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to extract numbers from",
                    required=True
                ),
                ToolParameter(
                    name="include_decimals",
                    type="boolean",
                    description="Include decimal numbers",
                    required=False,
                    default=True
                )
            ],
            tags=["text", "numbers", "extract", "regex"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        include_decimals = kwargs.get("include_decimals", True)
        
        if include_decimals:
            pattern = r'-?\d+\.?\d*'
        else:
            pattern = r'-?\d+'
        
        numbers = re.findall(pattern, text)
        numbers = [n for n in numbers if n not in ['', '.']]
        
        return {
            "count": len(numbers),
            "numbers": numbers,
            "sum": sum(float(n) for n in numbers) if numbers else 0
        }


class SlugifyText(BaseTool):
    """
    Convert text to URL-friendly slug.
    
    Converts text to a URL-friendly slug format.
    """
    
    def __init__(self):
        super().__init__(
            name="slugify_text",
            category=ToolCategory.DATA,
            description="Convert text to URL-friendly slug format",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to slugify",
                    required=True
                ),
                ToolParameter(
                    name="separator",
                    type="string",
                    description="Separator character",
                    required=False,
                    default="-"
                )
            ],
            tags=["text", "slug", "url", "format"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        separator = kwargs.get("separator", "-")
        
        # Convert to lowercase
        slug = text.lower()
        
        # Remove special characters
        slug = re.sub(r'[^a-z0-9\s-]', '', slug)
        
        # Replace spaces with separator
        slug = re.sub(r'[\s_]+', separator, slug)
        
        # Remove duplicate separators
        slug = re.sub(f'{separator}+', separator, slug)
        
        # Trim separators from ends
        slug = slug.strip(separator)
        
        return {
            "original": text,
            "slug": slug
        }


class TruncateText(BaseTool):
    """
    Truncate text to specified length.
    
    Truncates text to a maximum length with optional suffix.
    """
    
    def __init__(self):
        super().__init__(
            name="truncate_text",
            category=ToolCategory.DATA,
            description="Truncate text to a maximum length",
            parameters=[
                ToolParameter(
                    name="text",
                    type="string",
                    description="Text to truncate",
                    required=True
                ),
                ToolParameter(
                    name="max_length",
                    type="integer",
                    description="Maximum length",
                    required=True
                ),
                ToolParameter(
                    name="suffix",
                    type="string",
                    description="Suffix to add if truncated",
                    required=False,
                    default="..."
                ),
                ToolParameter(
                    name="word_boundary",
                    type="boolean",
                    description="Truncate at word boundary",
                    required=False,
                    default=True
                )
            ],
            tags=["text", "truncate", "shorten"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        text = kwargs["text"]
        max_length = kwargs["max_length"]
        suffix = kwargs.get("suffix", "...")
        word_boundary = kwargs.get("word_boundary", True)
        
        if len(text) <= max_length:
            return {
                "truncated": False,
                "original_length": len(text),
                "result": text
            }
        
        truncate_at = max_length - len(suffix)
        
        if word_boundary:
            # Find last word boundary
            truncate_at = text.rfind(' ', 0, truncate_at)
            if truncate_at == -1:
                truncate_at = max_length - len(suffix)
        
        result = text[:truncate_at] + suffix
        
        return {
            "truncated": True,
            "original_length": len(text),
            "truncated_length": len(result),
            "result": result
        }
