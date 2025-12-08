"""
Data Manipulation and Processing Tools

This module provides comprehensive data manipulation, transformation,
and processing tools that are OpenAI-compatible and follow the MCP protocol.
"""

from typing import Dict, Any, List, Optional
from .base import BaseTool, ToolCategory, ToolParameter, ToolResult
import json
import csv
from io import StringIO
from datetime import datetime
import re


class ParseJSON(BaseTool):
    """Parse JSON string into object."""
    
    def __init__(self):
        super().__init__(
            name="parse_json",
            category=ToolCategory.DATA,
            description="Parse JSON string into Python object",
            parameters=[
                ToolParameter(
                    name="json_string",
                    type="string",
                    description="JSON string to parse",
                    required=True
                )
            ],
            tags=["json", "parse", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        json_string = kwargs["json_string"]
        data = json.loads(json_string)
        
        return {
            "data": data,
            "type": type(data).__name__
        }


class StringifyJSON(BaseTool):
    """Convert object to JSON string."""
    
    def __init__(self):
        super().__init__(
            name="stringify_json",
            category=ToolCategory.DATA,
            description="Convert Python object to JSON string",
            parameters=[
                ToolParameter(
                    name="data",
                    type="object",
                    description="Data to convert to JSON",
                    required=True
                ),
                ToolParameter(
                    name="indent",
                    type="integer",
                    description="Indentation spaces",
                    required=False,
                    default=2
                )
            ],
            tags=["json", "stringify", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        data = kwargs["data"]
        indent = kwargs.get("indent", 2)
        
        json_string = json.dumps(data, indent=indent)
        
        return {
            "json_string": json_string,
            "length": len(json_string)
        }


class ParseCSV(BaseTool):
    """Parse CSV data into array of objects."""
    
    def __init__(self):
        super().__init__(
            name="parse_csv",
            category=ToolCategory.DATA,
            description="Parse CSV string into array of objects",
            parameters=[
                ToolParameter(
                    name="csv_string",
                    type="string",
                    description="CSV string to parse",
                    required=True
                ),
                ToolParameter(
                    name="has_header",
                    type="boolean",
                    description="First row contains column names",
                    required=False,
                    default=True
                ),
                ToolParameter(
                    name="delimiter",
                    type="string",
                    description="Field delimiter",
                    required=False,
                    default=","
                )
            ],
            tags=["csv", "parse", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        csv_string = kwargs["csv_string"]
        has_header = kwargs.get("has_header", True)
        delimiter = kwargs.get("delimiter", ",")
        
        f = StringIO(csv_string)
        reader = csv.DictReader(f, delimiter=delimiter) if has_header else csv.reader(f, delimiter=delimiter)
        
        if has_header:
            rows = list(reader)
        else:
            rows = [list(row) for row in reader]
        
        return {
            "rows": rows,
            "row_count": len(rows)
        }


class ConvertToCSV(BaseTool):
    """Convert array of objects to CSV."""
    
    def __init__(self):
        super().__init__(
            name="convert_to_csv",
            category=ToolCategory.DATA,
            description="Convert array of objects to CSV string",
            parameters=[
                ToolParameter(
                    name="data",
                    type="array",
                    description="Array of objects to convert",
                    required=True
                ),
                ToolParameter(
                    name="delimiter",
                    type="string",
                    description="Field delimiter",
                    required=False,
                    default=","
                )
            ],
            tags=["csv", "convert", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        data = kwargs["data"]
        delimiter = kwargs.get("delimiter", ",")
        
        if not data:
            return {"csv_string": "", "row_count": 0}
        
        output = StringIO()
        
        if isinstance(data[0], dict):
            fieldnames = data[0].keys()
            writer = csv.DictWriter(output, fieldnames=fieldnames, delimiter=delimiter)
            writer.writeheader()
            writer.writerows(data)
        else:
            writer = csv.writer(output, delimiter=delimiter)
            writer.writerows(data)
        
        csv_string = output.getvalue()
        
        return {
            "csv_string": csv_string,
            "row_count": len(data)
        }


class FilterArray(BaseTool):
    """Filter array elements by condition."""
    
    def __init__(self):
        super().__init__(
            name="filter_array",
            category=ToolCategory.DATA,
            description="Filter array elements matching a condition",
            parameters=[
                ToolParameter(
                    name="data",
                    type="array",
                    description="Array to filter",
                    required=True
                ),
                ToolParameter(
                    name="field",
                    type="string",
                    description="Field to check (for objects)",
                    required=False
                ),
                ToolParameter(
                    name="operator",
                    type="string",
                    description="Comparison operator",
                    required=True,
                    enum=["equals", "not_equals", "contains", "greater_than", "less_than", "regex"]
                ),
                ToolParameter(
                    name="value",
                    type="string",
                    description="Value to compare against",
                    required=True
                )
            ],
            tags=["array", "filter", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        data = kwargs["data"]
        field = kwargs.get("field")
        operator = kwargs["operator"]
        value = kwargs["value"]
        
        filtered = []
        
        for item in data:
            check_value = item.get(field) if field and isinstance(item, dict) else item
            
            if operator == "equals":
                if str(check_value) == str(value):
                    filtered.append(item)
            elif operator == "not_equals":
                if str(check_value) != str(value):
                    filtered.append(item)
            elif operator == "contains":
                if str(value) in str(check_value):
                    filtered.append(item)
            elif operator == "greater_than":
                if float(check_value) > float(value):
                    filtered.append(item)
            elif operator == "less_than":
                if float(check_value) < float(value):
                    filtered.append(item)
            elif operator == "regex":
                if re.search(value, str(check_value)):
                    filtered.append(item)
        
        return {
            "filtered_data": filtered,
            "original_count": len(data),
            "filtered_count": len(filtered)
        }


class MapArray(BaseTool):
    """Transform array elements."""
    
    def __init__(self):
        super().__init__(
            name="map_array",
            category=ToolCategory.DATA,
            description="Transform array elements by extracting or modifying fields",
            parameters=[
                ToolParameter(
                    name="data",
                    type="array",
                    description="Array to transform",
                    required=True
                ),
                ToolParameter(
                    name="fields",
                    type="array",
                    description="Fields to extract (for objects)",
                    required=False
                )
            ],
            tags=["array", "map", "transform", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        data = kwargs["data"]
        fields = kwargs.get("fields")
        
        if fields and data and isinstance(data[0], dict):
            mapped = []
            for item in data:
                mapped_item = {field: item.get(field) for field in fields if field in item}
                mapped.append(mapped_item)
        else:
            mapped = data
        
        return {
            "mapped_data": mapped,
            "count": len(mapped)
        }


class SortArray(BaseTool):
    """Sort array elements."""
    
    def __init__(self):
        super().__init__(
            name="sort_array",
            category=ToolCategory.DATA,
            description="Sort array elements by field or value",
            parameters=[
                ToolParameter(
                    name="data",
                    type="array",
                    description="Array to sort",
                    required=True
                ),
                ToolParameter(
                    name="field",
                    type="string",
                    description="Field to sort by (for objects)",
                    required=False
                ),
                ToolParameter(
                    name="reverse",
                    type="boolean",
                    description="Sort in descending order",
                    required=False,
                    default=False
                )
            ],
            tags=["array", "sort", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        data = kwargs["data"]
        field = kwargs.get("field")
        reverse = kwargs.get("reverse", False)
        
        if field and data and isinstance(data[0], dict):
            sorted_data = sorted(data, key=lambda x: x.get(field, ''), reverse=reverse)
        else:
            sorted_data = sorted(data, reverse=reverse)
        
        return {
            "sorted_data": sorted_data,
            "count": len(sorted_data)
        }


class GroupBy(BaseTool):
    """Group array elements by field."""
    
    def __init__(self):
        super().__init__(
            name="group_by",
            category=ToolCategory.DATA,
            description="Group array elements by a field value",
            parameters=[
                ToolParameter(
                    name="data",
                    type="array",
                    description="Array of objects to group",
                    required=True
                ),
                ToolParameter(
                    name="field",
                    type="string",
                    description="Field to group by",
                    required=True
                )
            ],
            tags=["array", "group", "aggregate", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        data = kwargs["data"]
        field = kwargs["field"]
        
        groups = {}
        for item in data:
            if not isinstance(item, dict):
                continue
            
            key = str(item.get(field, 'undefined'))
            if key not in groups:
                groups[key] = []
            groups[key].append(item)
        
        return {
            "groups": groups,
            "group_count": len(groups),
            "total_items": len(data)
        }


class AggregateData(BaseTool):
    """Aggregate data with sum, count, avg, etc."""
    
    def __init__(self):
        super().__init__(
            name="aggregate_data",
            category=ToolCategory.DATA,
            description="Calculate aggregates (sum, count, avg, min, max) on array",
            parameters=[
                ToolParameter(
                    name="data",
                    type="array",
                    description="Array of objects to aggregate",
                    required=True
                ),
                ToolParameter(
                    name="field",
                    type="string",
                    description="Field to aggregate",
                    required=True
                ),
                ToolParameter(
                    name="operations",
                    type="array",
                    description="Aggregation operations to perform",
                    required=False
                )
            ],
            tags=["array", "aggregate", "stats", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        data = kwargs["data"]
        field = kwargs["field"]
        operations = kwargs.get("operations", ["sum", "count", "avg", "min", "max"])
        
        values = []
        for item in data:
            if isinstance(item, dict) and field in item:
                try:
                    values.append(float(item[field]))
                except (ValueError, TypeError):
                    continue
        
        results = {}
        
        if not values:
            return {
                "results": {},
                "item_count": len(data),
                "valid_values": 0
            }
        
        if "count" in operations:
            results["count"] = len(values)
        if "sum" in operations:
            results["sum"] = sum(values)
        if "avg" in operations:
            results["avg"] = sum(values) / len(values)
        if "min" in operations:
            results["min"] = min(values)
        if "max" in operations:
            results["max"] = max(values)
        
        return {
            "results": results,
            "item_count": len(data),
            "valid_values": len(values)
        }


class MergeArrays(BaseTool):
    """Merge multiple arrays."""
    
    def __init__(self):
        super().__init__(
            name="merge_arrays",
            category=ToolCategory.DATA,
            description="Merge multiple arrays into one",
            parameters=[
                ToolParameter(
                    name="arrays",
                    type="array",
                    description="Array of arrays to merge",
                    required=True
                ),
                ToolParameter(
                    name="remove_duplicates",
                    type="boolean",
                    description="Remove duplicate elements",
                    required=False,
                    default=False
                )
            ],
            tags=["array", "merge", "combine", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        arrays = kwargs["arrays"]
        remove_duplicates = kwargs.get("remove_duplicates", False)
        
        merged = []
        for arr in arrays:
            if isinstance(arr, list):
                merged.extend(arr)
        
        if remove_duplicates:
            # For simple types
            try:
                merged = list(dict.fromkeys(merged))
            except:
                pass
        
        return {
            "merged_data": merged,
            "count": len(merged),
            "source_arrays": len(arrays)
        }


class FlattenArray(BaseTool):
    """Flatten nested arrays."""
    
    def __init__(self):
        super().__init__(
            name="flatten_array",
            category=ToolCategory.DATA,
            description="Flatten nested arrays into single-level array",
            parameters=[
                ToolParameter(
                    name="data",
                    type="array",
                    description="Nested array to flatten",
                    required=True
                ),
                ToolParameter(
                    name="depth",
                    type="integer",
                    description="Levels to flatten (-1 for all)",
                    required=False,
                    default=-1
                )
            ],
            tags=["array", "flatten", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        data = kwargs["data"]
        depth = kwargs.get("depth", -1)
        
        def flatten(arr, d):
            if d == 0:
                return arr
            
            result = []
            for item in arr:
                if isinstance(item, list):
                    result.extend(flatten(item, d - 1 if d > 0 else -1))
                else:
                    result.append(item)
            return result
        
        flattened = flatten(data, depth)
        
        return {
            "flattened_data": flattened,
            "count": len(flattened)
        }


class UniqueArray(BaseTool):
    """Get unique elements from array."""
    
    def __init__(self):
        super().__init__(
            name="unique_array",
            category=ToolCategory.DATA,
            description="Get unique elements from array, removing duplicates",
            parameters=[
                ToolParameter(
                    name="data",
                    type="array",
                    description="Array to get unique elements from",
                    required=True
                ),
                ToolParameter(
                    name="field",
                    type="string",
                    description="Field to use for uniqueness (for objects)",
                    required=False
                )
            ],
            tags=["array", "unique", "distinct", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        data = kwargs["data"]
        field = kwargs.get("field")
        
        if field and data and isinstance(data[0], dict):
            seen = set()
            unique = []
            for item in data:
                value = item.get(field)
                if value not in seen:
                    seen.add(value)
                    unique.append(item)
        else:
            try:
                unique = list(dict.fromkeys(data))
            except:
                unique = data
        
        return {
            "unique_data": unique,
            "original_count": len(data),
            "unique_count": len(unique),
            "duplicates_removed": len(data) - len(unique)
        }


class ChunkArray(BaseTool):
    """Split array into chunks."""
    
    def __init__(self):
        super().__init__(
            name="chunk_array",
            category=ToolCategory.DATA,
            description="Split array into smaller chunks of specified size",
            parameters=[
                ToolParameter(
                    name="data",
                    type="array",
                    description="Array to chunk",
                    required=True
                ),
                ToolParameter(
                    name="chunk_size",
                    type="integer",
                    description="Size of each chunk",
                    required=True
                )
            ],
            tags=["array", "chunk", "split", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        data = kwargs["data"]
        chunk_size = kwargs["chunk_size"]
        
        chunks = [data[i:i + chunk_size] for i in range(0, len(data), chunk_size)]
        
        return {
            "chunks": chunks,
            "chunk_count": len(chunks),
            "chunk_size": chunk_size,
            "total_items": len(data)
        }


class TransposeMatrix(BaseTool):
    """Transpose a 2D array (matrix)."""
    
    def __init__(self):
        super().__init__(
            name="transpose_matrix",
            category=ToolCategory.DATA,
            description="Transpose a 2D array, swapping rows and columns",
            parameters=[
                ToolParameter(
                    name="matrix",
                    type="array",
                    description="2D array to transpose",
                    required=True
                )
            ],
            tags=["matrix", "transpose", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        matrix = kwargs["matrix"]
        
        if not matrix or not isinstance(matrix[0], list):
            return {
                "transposed_matrix": matrix,
                "rows": len(matrix) if matrix else 0,
                "cols": 0
            }
        
        transposed = list(map(list, zip(*matrix)))
        
        return {
            "transposed_matrix": transposed,
            "original_rows": len(matrix),
            "original_cols": len(matrix[0]) if matrix else 0,
            "transposed_rows": len(transposed),
            "transposed_cols": len(transposed[0]) if transposed else 0
        }


class PivotData(BaseTool):
    """Pivot data table."""
    
    def __init__(self):
        super().__init__(
            name="pivot_data",
            category=ToolCategory.DATA,
            description="Pivot data table with rows, columns, and values",
            parameters=[
                ToolParameter(
                    name="data",
                    type="array",
                    description="Array of objects to pivot",
                    required=True
                ),
                ToolParameter(
                    name="row_field",
                    type="string",
                    description="Field to use for rows",
                    required=True
                ),
                ToolParameter(
                    name="col_field",
                    type="string",
                    description="Field to use for columns",
                    required=True
                ),
                ToolParameter(
                    name="value_field",
                    type="string",
                    description="Field to use for values",
                    required=True
                )
            ],
            tags=["data", "pivot", "transform"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        data = kwargs["data"]
        row_field = kwargs["row_field"]
        col_field = kwargs["col_field"]
        value_field = kwargs["value_field"]
        
        pivot = {}
        
        for item in data:
            if not isinstance(item, dict):
                continue
            
            row_key = str(item.get(row_field, 'undefined'))
            col_key = str(item.get(col_field, 'undefined'))
            value = item.get(value_field)
            
            if row_key not in pivot:
                pivot[row_key] = {}
            
            pivot[row_key][col_key] = value
        
        return {
            "pivot_data": pivot,
            "row_count": len(pivot),
            "source_items": len(data)
        }


class ValidateSchema(BaseTool):
    """Validate data against a schema."""
    
    def __init__(self):
        super().__init__(
            name="validate_schema",
            category=ToolCategory.DATA,
            description="Validate data structure against a schema definition",
            parameters=[
                ToolParameter(
                    name="data",
                    type="object",
                    description="Data to validate",
                    required=True
                ),
                ToolParameter(
                    name="schema",
                    type="object",
                    description="Schema definition with required fields and types",
                    required=True
                )
            ],
            tags=["data", "validate", "schema"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        data = kwargs["data"]
        schema = kwargs["schema"]
        
        errors = []
        warnings = []
        
        # Check required fields
        required = schema.get("required", [])
        for field in required:
            if field not in data:
                errors.append(f"Missing required field: {field}")
        
        # Check field types
        properties = schema.get("properties", {})
        for field, spec in properties.items():
            if field in data:
                expected_type = spec.get("type")
                actual_value = data[field]
                
                type_map = {
                    "string": str,
                    "integer": int,
                    "number": (int, float),
                    "boolean": bool,
                    "array": list,
                    "object": dict
                }
                
                if expected_type in type_map:
                    if not isinstance(actual_value, type_map[expected_type]):
                        errors.append(f"Field '{field}' should be {expected_type}, got {type(actual_value).__name__}")
        
        return {
            "valid": len(errors) == 0,
            "errors": errors,
            "warnings": warnings,
            "fields_checked": len(properties)
        }


class ConvertDateFormat(BaseTool):
    """Convert date between formats."""
    
    def __init__(self):
        super().__init__(
            name="convert_date_format",
            category=ToolCategory.DATA,
            description="Convert date string from one format to another",
            parameters=[
                ToolParameter(
                    name="date_string",
                    type="string",
                    description="Date string to convert",
                    required=True
                ),
                ToolParameter(
                    name="input_format",
                    type="string",
                    description="Input date format (strftime format)",
                    required=True
                ),
                ToolParameter(
                    name="output_format",
                    type="string",
                    description="Output date format (strftime format)",
                    required=True
                )
            ],
            tags=["date", "format", "convert", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        date_string = kwargs["date_string"]
        input_format = kwargs["input_format"]
        output_format = kwargs["output_format"]
        
        # Parse date with input format
        date_obj = datetime.strptime(date_string, input_format)
        
        # Format with output format
        output_string = date_obj.strftime(output_format)
        
        return {
            "input": date_string,
            "output": output_string,
            "iso_format": date_obj.isoformat()
        }


class CalculateTimeDelta(BaseTool):
    """Calculate difference between two dates."""
    
    def __init__(self):
        super().__init__(
            name="calculate_time_delta",
            category=ToolCategory.DATA,
            description="Calculate the difference between two dates",
            parameters=[
                ToolParameter(
                    name="start_date",
                    type="string",
                    description="Start date (ISO format or timestamp)",
                    required=True
                ),
                ToolParameter(
                    name="end_date",
                    type="string",
                    description="End date (ISO format or timestamp)",
                    required=True
                ),
                ToolParameter(
                    name="unit",
                    type="string",
                    description="Unit for result",
                    required=False,
                    default="days",
                    enum=["seconds", "minutes", "hours", "days", "weeks"]
                )
            ],
            tags=["date", "time", "delta", "calculate", "data"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        start_date = kwargs["start_date"]
        end_date = kwargs["end_date"]
        unit = kwargs.get("unit", "days")
        
        # Try to parse dates
        try:
            start = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
        except:
            start = datetime.fromtimestamp(float(start_date))
        
        try:
            end = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
        except:
            end = datetime.fromtimestamp(float(end_date))
        
        delta = end - start
        seconds = delta.total_seconds()
        
        unit_map = {
            "seconds": seconds,
            "minutes": seconds / 60,
            "hours": seconds / 3600,
            "days": seconds / 86400,
            "weeks": seconds / 604800
        }
        
        value = unit_map.get(unit, seconds)
        
        return {
            "start_date": start.isoformat(),
            "end_date": end.isoformat(),
            "delta": value,
            "unit": unit,
            "total_seconds": seconds
        }
