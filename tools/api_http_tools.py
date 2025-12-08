"""
API and HTTP Operations Tools

This module provides comprehensive API and HTTP operation tools
that are OpenAI-compatible and follow the MCP protocol.
"""

from typing import Dict, Any, List, Optional
from .base import BaseTool, ToolCategory, ToolParameter, ToolResult
import json


class HTTPGet(BaseTool):
    """
    Make HTTP GET request.
    
    Performs an HTTP GET request to a specified URL with optional headers and query parameters.
    """
    
    def __init__(self):
        super().__init__(
            name="http_get",
            category=ToolCategory.API,
            description="Make HTTP GET request to a URL",
            parameters=[
                ToolParameter(
                    name="url",
                    type="string",
                    description="URL to make GET request to",
                    required=True
                ),
                ToolParameter(
                    name="headers",
                    type="object",
                    description="HTTP headers to include",
                    required=False
                ),
                ToolParameter(
                    name="params",
                    type="object",
                    description="Query parameters",
                    required=False
                ),
                ToolParameter(
                    name="timeout",
                    type="integer",
                    description="Request timeout in seconds",
                    required=False,
                    default=30
                )
            ],
            tags=["http", "api", "get", "request"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        import requests
        
        url = kwargs["url"]
        headers = kwargs.get("headers", {})
        params = kwargs.get("params", {})
        timeout = kwargs.get("timeout", 30)
        
        response = requests.get(url, headers=headers, params=params, timeout=timeout)
        
        return {
            "url": url,
            "status_code": response.status_code,
            "headers": dict(response.headers),
            "content": response.text,
            "json": response.json() if response.headers.get('content-type', '').startswith('application/json') else None,
            "elapsed_ms": response.elapsed.total_seconds() * 1000
        }


class HTTPPost(BaseTool):
    """
    Make HTTP POST request.
    
    Performs an HTTP POST request with JSON or form data.
    """
    
    def __init__(self):
        super().__init__(
            name="http_post",
            category=ToolCategory.API,
            description="Make HTTP POST request with data",
            parameters=[
                ToolParameter(
                    name="url",
                    type="string",
                    description="URL to make POST request to",
                    required=True
                ),
                ToolParameter(
                    name="data",
                    type="object",
                    description="Data to send in request body",
                    required=False
                ),
                ToolParameter(
                    name="json_data",
                    type="object",
                    description="JSON data to send (sets Content-Type to application/json)",
                    required=False
                ),
                ToolParameter(
                    name="headers",
                    type="object",
                    description="HTTP headers to include",
                    required=False
                ),
                ToolParameter(
                    name="timeout",
                    type="integer",
                    description="Request timeout in seconds",
                    required=False,
                    default=30
                )
            ],
            tags=["http", "api", "post", "request"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        import requests
        
        url = kwargs["url"]
        data = kwargs.get("data")
        json_data = kwargs.get("json_data")
        headers = kwargs.get("headers", {})
        timeout = kwargs.get("timeout", 30)
        
        if json_data:
            response = requests.post(url, json=json_data, headers=headers, timeout=timeout)
        else:
            response = requests.post(url, data=data, headers=headers, timeout=timeout)
        
        return {
            "url": url,
            "status_code": response.status_code,
            "headers": dict(response.headers),
            "content": response.text,
            "json": response.json() if response.headers.get('content-type', '').startswith('application/json') else None,
            "elapsed_ms": response.elapsed.total_seconds() * 1000
        }


class HTTPPut(BaseTool):
    """
    Make HTTP PUT request.
    
    Performs an HTTP PUT request to update resources.
    """
    
    def __init__(self):
        super().__init__(
            name="http_put",
            category=ToolCategory.API,
            description="Make HTTP PUT request to update resource",
            parameters=[
                ToolParameter(
                    name="url",
                    type="string",
                    description="URL to make PUT request to",
                    required=True
                ),
                ToolParameter(
                    name="data",
                    type="object",
                    description="Data to send in request body",
                    required=False
                ),
                ToolParameter(
                    name="json_data",
                    type="object",
                    description="JSON data to send",
                    required=False
                ),
                ToolParameter(
                    name="headers",
                    type="object",
                    description="HTTP headers to include",
                    required=False
                )
            ],
            tags=["http", "api", "put", "update"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        import requests
        
        url = kwargs["url"]
        data = kwargs.get("data")
        json_data = kwargs.get("json_data")
        headers = kwargs.get("headers", {})
        
        if json_data:
            response = requests.put(url, json=json_data, headers=headers)
        else:
            response = requests.put(url, data=data, headers=headers)
        
        return {
            "url": url,
            "status_code": response.status_code,
            "content": response.text,
            "json": response.json() if response.headers.get('content-type', '').startswith('application/json') else None
        }


class HTTPDelete(BaseTool):
    """
    Make HTTP DELETE request.
    
    Performs an HTTP DELETE request to remove resources.
    """
    
    def __init__(self):
        super().__init__(
            name="http_delete",
            category=ToolCategory.API,
            description="Make HTTP DELETE request to remove resource",
            parameters=[
                ToolParameter(
                    name="url",
                    type="string",
                    description="URL to make DELETE request to",
                    required=True
                ),
                ToolParameter(
                    name="headers",
                    type="object",
                    description="HTTP headers to include",
                    required=False
                )
            ],
            tags=["http", "api", "delete"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        import requests
        
        url = kwargs["url"]
        headers = kwargs.get("headers", {})
        
        response = requests.delete(url, headers=headers)
        
        return {
            "url": url,
            "status_code": response.status_code,
            "content": response.text
        }


class HTTPPatch(BaseTool):
    """
    Make HTTP PATCH request.
    
    Performs an HTTP PATCH request for partial resource updates.
    """
    
    def __init__(self):
        super().__init__(
            name="http_patch",
            category=ToolCategory.API,
            description="Make HTTP PATCH request for partial updates",
            parameters=[
                ToolParameter(
                    name="url",
                    type="string",
                    description="URL to make PATCH request to",
                    required=True
                ),
                ToolParameter(
                    name="data",
                    type="object",
                    description="Data to send in request body",
                    required=True
                ),
                ToolParameter(
                    name="headers",
                    type="object",
                    description="HTTP headers to include",
                    required=False
                )
            ],
            tags=["http", "api", "patch", "update"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        import requests
        
        url = kwargs["url"]
        data = kwargs["data"]
        headers = kwargs.get("headers", {})
        
        response = requests.patch(url, json=data, headers=headers)
        
        return {
            "url": url,
            "status_code": response.status_code,
            "content": response.text,
            "json": response.json() if response.headers.get('content-type', '').startswith('application/json') else None
        }


class ParseURL(BaseTool):
    """
    Parse URL components.
    
    Parses a URL into its component parts (scheme, host, path, query, etc.).
    """
    
    def __init__(self):
        super().__init__(
            name="parse_url",
            category=ToolCategory.API,
            description="Parse URL into component parts",
            parameters=[
                ToolParameter(
                    name="url",
                    type="string",
                    description="URL to parse",
                    required=True
                )
            ],
            tags=["url", "parse", "api"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        from urllib.parse import urlparse, parse_qs
        
        url = kwargs["url"]
        parsed = urlparse(url)
        
        return {
            "url": url,
            "scheme": parsed.scheme,
            "netloc": parsed.netloc,
            "hostname": parsed.hostname,
            "port": parsed.port,
            "path": parsed.path,
            "params": parsed.params,
            "query": parsed.query,
            "query_params": parse_qs(parsed.query),
            "fragment": parsed.fragment
        }


class BuildURL(BaseTool):
    """
    Build URL from components.
    
    Constructs a URL from its component parts.
    """
    
    def __init__(self):
        super().__init__(
            name="build_url",
            category=ToolCategory.API,
            description="Build URL from component parts",
            parameters=[
                ToolParameter(
                    name="scheme",
                    type="string",
                    description="URL scheme (http, https, etc.)",
                    required=True
                ),
                ToolParameter(
                    name="host",
                    type="string",
                    description="Hostname",
                    required=True
                ),
                ToolParameter(
                    name="path",
                    type="string",
                    description="URL path",
                    required=False,
                    default=""
                ),
                ToolParameter(
                    name="query_params",
                    type="object",
                    description="Query parameters as key-value pairs",
                    required=False
                ),
                ToolParameter(
                    name="port",
                    type="integer",
                    description="Port number",
                    required=False
                )
            ],
            tags=["url", "build", "api"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        from urllib.parse import urlencode, urlunparse
        
        scheme = kwargs["scheme"]
        host = kwargs["host"]
        path = kwargs.get("path", "")
        query_params = kwargs.get("query_params", {})
        port = kwargs.get("port")
        
        netloc = host
        if port:
            netloc = f"{host}:{port}"
        
        query = urlencode(query_params) if query_params else ""
        
        url = urlunparse((scheme, netloc, path, "", query, ""))
        
        return {
            "url": url,
            "scheme": scheme,
            "netloc": netloc,
            "path": path,
            "query": query
        }


class DownloadFile(BaseTool):
    """
    Download file from URL.
    
    Downloads a file from a URL and saves it to disk.
    """
    
    def __init__(self):
        super().__init__(
            name="download_file",
            category=ToolCategory.API,
            description="Download file from URL and save to disk",
            parameters=[
                ToolParameter(
                    name="url",
                    type="string",
                    description="URL to download from",
                    required=True
                ),
                ToolParameter(
                    name="destination",
                    type="string",
                    description="Local path to save file",
                    required=True
                ),
                ToolParameter(
                    name="chunk_size",
                    type="integer",
                    description="Download chunk size in bytes",
                    required=False,
                    default=8192
                )
            ],
            tags=["http", "download", "file"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        import requests
        import os
        
        url = kwargs["url"]
        destination = kwargs["destination"]
        chunk_size = kwargs.get("chunk_size", 8192)
        
        # Create directory if needed
        os.makedirs(os.path.dirname(destination), exist_ok=True)
        
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        total_bytes = 0
        with open(destination, 'wb') as f:
            for chunk in response.iter_content(chunk_size=chunk_size):
                if chunk:
                    f.write(chunk)
                    total_bytes += len(chunk)
        
        return {
            "url": url,
            "destination": destination,
            "bytes_downloaded": total_bytes,
            "content_type": response.headers.get('content-type')
        }


class CheckURLStatus(BaseTool):
    """
    Check HTTP status of URL.
    
    Checks if a URL is accessible and returns HTTP status.
    """
    
    def __init__(self):
        super().__init__(
            name="check_url_status",
            category=ToolCategory.API,
            description="Check HTTP status code and accessibility of URL",
            parameters=[
                ToolParameter(
                    name="url",
                    type="string",
                    description="URL to check",
                    required=True
                ),
                ToolParameter(
                    name="timeout",
                    type="integer",
                    description="Request timeout in seconds",
                    required=False,
                    default=10
                )
            ],
            tags=["http", "status", "check", "health"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        import requests
        from datetime import datetime
        
        url = kwargs["url"]
        timeout = kwargs.get("timeout", 10)
        
        start_time = datetime.utcnow()
        
        try:
            response = requests.head(url, timeout=timeout, allow_redirects=True)
            response_time = (datetime.utcnow() - start_time).total_seconds() * 1000
            
            return {
                "url": url,
                "accessible": True,
                "status_code": response.status_code,
                "status_text": response.reason,
                "response_time_ms": response_time,
                "content_type": response.headers.get('content-type'),
                "content_length": response.headers.get('content-length')
            }
        except Exception as e:
            response_time = (datetime.utcnow() - start_time).total_seconds() * 1000
            return {
                "url": url,
                "accessible": False,
                "error": str(e),
                "response_time_ms": response_time
            }


class MakeWebhookCall(BaseTool):
    """
    Make webhook POST call.
    
    Sends data to a webhook URL with proper formatting.
    """
    
    def __init__(self):
        super().__init__(
            name="make_webhook_call",
            category=ToolCategory.API,
            description="Send data to webhook URL",
            parameters=[
                ToolParameter(
                    name="webhook_url",
                    type="string",
                    description="Webhook URL to call",
                    required=True
                ),
                ToolParameter(
                    name="payload",
                    type="object",
                    description="Data to send to webhook",
                    required=True
                ),
                ToolParameter(
                    name="headers",
                    type="object",
                    description="Additional headers",
                    required=False
                )
            ],
            tags=["webhook", "api", "post"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        import requests
        
        webhook_url = kwargs["webhook_url"]
        payload = kwargs["payload"]
        headers = kwargs.get("headers", {})
        
        headers.setdefault('Content-Type', 'application/json')
        
        response = requests.post(webhook_url, json=payload, headers=headers)
        
        return {
            "webhook_url": webhook_url,
            "status_code": response.status_code,
            "success": response.status_code < 400,
            "response": response.text
        }


class FetchJSON(BaseTool):
    """
    Fetch and parse JSON from URL.
    
    Retrieves JSON data from a URL and returns parsed object.
    """
    
    def __init__(self):
        super().__init__(
            name="fetch_json",
            category=ToolCategory.API,
            description="Fetch and parse JSON data from URL",
            parameters=[
                ToolParameter(
                    name="url",
                    type="string",
                    description="URL to fetch JSON from",
                    required=True
                ),
                ToolParameter(
                    name="headers",
                    type="object",
                    description="HTTP headers to include",
                    required=False
                )
            ],
            tags=["http", "json", "api", "fetch"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        import requests
        
        url = kwargs["url"]
        headers = kwargs.get("headers", {})
        
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        
        data = response.json()
        
        return {
            "url": url,
            "status_code": response.status_code,
            "data": data
        }


class EncodeURLParams(BaseTool):
    """
    Encode URL query parameters.
    
    Encodes a dictionary of parameters into URL query string format.
    """
    
    def __init__(self):
        super().__init__(
            name="encode_url_params",
            category=ToolCategory.API,
            description="Encode parameters into URL query string",
            parameters=[
                ToolParameter(
                    name="params",
                    type="object",
                    description="Parameters to encode",
                    required=True
                )
            ],
            tags=["url", "encode", "params"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        from urllib.parse import urlencode
        
        params = kwargs["params"]
        
        encoded = urlencode(params)
        
        return {
            "params": params,
            "encoded": encoded,
            "length": len(encoded)
        }


class DecodeURLParams(BaseTool):
    """
    Decode URL query parameters.
    
    Decodes a URL query string into a dictionary of parameters.
    """
    
    def __init__(self):
        super().__init__(
            name="decode_url_params",
            category=ToolCategory.API,
            description="Decode URL query string into parameters",
            parameters=[
                ToolParameter(
                    name="query_string",
                    type="string",
                    description="Query string to decode",
                    required=True
                )
            ],
            tags=["url", "decode", "params"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        from urllib.parse import parse_qs
        
        query_string = kwargs["query_string"]
        
        # Remove leading ? if present
        if query_string.startswith('?'):
            query_string = query_string[1:]
        
        params = parse_qs(query_string)
        
        # Convert lists with single items to single values
        params = {k: v[0] if len(v) == 1 else v for k, v in params.items()}
        
        return {
            "query_string": query_string,
            "params": params,
            "param_count": len(params)
        }


class ValidateJSONSchema(BaseTool):
    """
    Validate JSON against schema.
    
    Validates a JSON document against a JSON Schema.
    """
    
    def __init__(self):
        super().__init__(
            name="validate_json_schema",
            category=ToolCategory.API,
            description="Validate JSON data against JSON Schema",
            parameters=[
                ToolParameter(
                    name="data",
                    type="object",
                    description="JSON data to validate",
                    required=True
                ),
                ToolParameter(
                    name="schema",
                    type="object",
                    description="JSON Schema to validate against",
                    required=True
                )
            ],
            tags=["json", "schema", "validate"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        try:
            import jsonschema
            
            data = kwargs["data"]
            schema = kwargs["schema"]
            
            jsonschema.validate(instance=data, schema=schema)
            
            return {
                "valid": True,
                "message": "Data is valid according to schema"
            }
        except Exception as e:
            return {
                "valid": False,
                "error": str(e)
            }


class RateLimitedRequest(BaseTool):
    """
    Make rate-limited HTTP request.
    
    Makes an HTTP request with built-in rate limiting.
    """
    
    def __init__(self):
        super().__init__(
            name="rate_limited_request",
            category=ToolCategory.API,
            description="Make HTTP request with rate limiting",
            parameters=[
                ToolParameter(
                    name="url",
                    type="string",
                    description="URL to request",
                    required=True
                ),
                ToolParameter(
                    name="method",
                    type="string",
                    description="HTTP method",
                    required=False,
                    default="GET",
                    enum=["GET", "POST", "PUT", "PATCH", "DELETE"]
                ),
                ToolParameter(
                    name="data",
                    type="object",
                    description="Request data",
                    required=False
                ),
                ToolParameter(
                    name="max_requests_per_minute",
                    type="integer",
                    description="Maximum requests per minute",
                    required=False,
                    default=60
                )
            ],
            tags=["http", "api", "rate-limit"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        import requests
        import time
        
        url = kwargs["url"]
        method = kwargs.get("method", "GET")
        data = kwargs.get("data")
        max_rpm = kwargs.get("max_requests_per_minute", 60)
        
        # Simple rate limiting - wait if needed
        wait_time = 60.0 / max_rpm
        time.sleep(wait_time)
        
        if method == "GET":
            response = requests.get(url)
        elif method == "POST":
            response = requests.post(url, json=data)
        elif method == "PUT":
            response = requests.put(url, json=data)
        elif method == "PATCH":
            response = requests.patch(url, json=data)
        elif method == "DELETE":
            response = requests.delete(url)
        
        return {
            "url": url,
            "method": method,
            "status_code": response.status_code,
            "content": response.text,
            "rate_limit": max_rpm
        }


class RetryRequest(BaseTool):
    """
    Make HTTP request with retry logic.
    
    Makes an HTTP request with automatic retries on failure.
    """
    
    def __init__(self):
        super().__init__(
            name="retry_request",
            category=ToolCategory.API,
            description="Make HTTP request with automatic retries",
            parameters=[
                ToolParameter(
                    name="url",
                    type="string",
                    description="URL to request",
                    required=True
                ),
                ToolParameter(
                    name="method",
                    type="string",
                    description="HTTP method",
                    required=False,
                    default="GET",
                    enum=["GET", "POST", "PUT", "DELETE"]
                ),
                ToolParameter(
                    name="max_retries",
                    type="integer",
                    description="Maximum number of retry attempts",
                    required=False,
                    default=3
                ),
                ToolParameter(
                    name="backoff_factor",
                    type="number",
                    description="Backoff multiplier between retries",
                    required=False,
                    default=2.0
                )
            ],
            tags=["http", "api", "retry", "resilience"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        import requests
        import time
        
        url = kwargs["url"]
        method = kwargs.get("method", "GET")
        max_retries = kwargs.get("max_retries", 3)
        backoff_factor = kwargs.get("backoff_factor", 2.0)
        
        attempts = 0
        last_error = None
        
        while attempts <= max_retries:
            try:
                if method == "GET":
                    response = requests.get(url)
                elif method == "POST":
                    response = requests.post(url)
                elif method == "PUT":
                    response = requests.put(url)
                elif method == "DELETE":
                    response = requests.delete(url)
                
                response.raise_for_status()
                
                return {
                    "url": url,
                    "status_code": response.status_code,
                    "content": response.text,
                    "attempts": attempts + 1,
                    "success": True
                }
            except Exception as e:
                last_error = str(e)
                attempts += 1
                
                if attempts <= max_retries:
                    wait_time = backoff_factor ** attempts
                    time.sleep(wait_time)
        
        return {
            "url": url,
            "success": False,
            "attempts": attempts,
            "error": last_error
        }
