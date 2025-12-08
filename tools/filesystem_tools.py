"""
File System Operations Tools

This module provides comprehensive file system operation tools that are
OpenAI-compatible and follow the MCP protocol.
"""

from typing import Dict, Any, List, Optional
from .base import BaseTool, ToolCategory, ToolParameter, ToolResult
import os
import shutil
import glob
import json
from pathlib import Path
from datetime import datetime


class ReadFileContent(BaseTool):
    """
    Read content from a file.
    
    This tool reads and returns the entire content of a specified file.
    Supports text files and can optionally decode with specific encoding.
    """
    
    def __init__(self):
        super().__init__(
            name="read_file_content",
            category=ToolCategory.FILESYSTEM,
            description="Read and return the content of a file",
            parameters=[
                ToolParameter(
                    name="file_path",
                    type="string",
                    description="Path to the file to read",
                    required=True
                ),
                ToolParameter(
                    name="encoding",
                    type="string",
                    description="File encoding (default: utf-8)",
                    required=False,
                    default="utf-8"
                )
            ],
            tags=["file", "read", "io"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        file_path = kwargs["file_path"]
        encoding = kwargs.get("encoding", "utf-8")
        
        with open(file_path, 'r', encoding=encoding) as f:
            content = f.read()
        
        return {
            "file_path": file_path,
            "content": content,
            "size_bytes": len(content.encode(encoding)),
            "lines": len(content.splitlines())
        }


class WriteFileContent(BaseTool):
    """
    Write content to a file.
    
    Creates or overwrites a file with specified content.
    Creates parent directories if they don't exist.
    """
    
    def __init__(self):
        super().__init__(
            name="write_file_content",
            category=ToolCategory.FILESYSTEM,
            description="Write content to a file, creating it if necessary",
            parameters=[
                ToolParameter(
                    name="file_path",
                    type="string",
                    description="Path to the file to write",
                    required=True
                ),
                ToolParameter(
                    name="content",
                    type="string",
                    description="Content to write to the file",
                    required=True
                ),
                ToolParameter(
                    name="encoding",
                    type="string",
                    description="File encoding (default: utf-8)",
                    required=False,
                    default="utf-8"
                ),
                ToolParameter(
                    name="create_dirs",
                    type="boolean",
                    description="Create parent directories if they don't exist",
                    required=False,
                    default=True
                )
            ],
            tags=["file", "write", "io"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        file_path = kwargs["file_path"]
        content = kwargs["content"]
        encoding = kwargs.get("encoding", "utf-8")
        create_dirs = kwargs.get("create_dirs", True)
        
        if create_dirs:
            os.makedirs(os.path.dirname(file_path), exist_ok=True)
        
        with open(file_path, 'w', encoding=encoding) as f:
            f.write(content)
        
        return {
            "file_path": file_path,
            "bytes_written": len(content.encode(encoding)),
            "lines_written": len(content.splitlines())
        }


class AppendFileContent(BaseTool):
    """
    Append content to a file.
    
    Adds content to the end of an existing file or creates a new file.
    """
    
    def __init__(self):
        super().__init__(
            name="append_file_content",
            category=ToolCategory.FILESYSTEM,
            description="Append content to an existing file or create new file",
            parameters=[
                ToolParameter(
                    name="file_path",
                    type="string",
                    description="Path to the file to append to",
                    required=True
                ),
                ToolParameter(
                    name="content",
                    type="string",
                    description="Content to append to the file",
                    required=True
                ),
                ToolParameter(
                    name="newline_before",
                    type="boolean",
                    description="Add newline before appending content",
                    required=False,
                    default=True
                )
            ],
            tags=["file", "append", "io"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        file_path = kwargs["file_path"]
        content = kwargs["content"]
        newline_before = kwargs.get("newline_before", True)
        
        with open(file_path, 'a', encoding='utf-8') as f:
            if newline_before and os.path.exists(file_path) and os.path.getsize(file_path) > 0:
                f.write('\n')
            f.write(content)
        
        return {
            "file_path": file_path,
            "bytes_appended": len(content.encode('utf-8'))
        }


class ListDirectory(BaseTool):
    """
    List contents of a directory.
    
    Returns list of files and directories with optional filtering and details.
    """
    
    def __init__(self):
        super().__init__(
            name="list_directory",
            category=ToolCategory.FILESYSTEM,
            description="List files and directories in a specified path",
            parameters=[
                ToolParameter(
                    name="directory_path",
                    type="string",
                    description="Path to the directory to list",
                    required=True
                ),
                ToolParameter(
                    name="pattern",
                    type="string",
                    description="Glob pattern to filter results (e.g., '*.py')",
                    required=False
                ),
                ToolParameter(
                    name="recursive",
                    type="boolean",
                    description="List recursively through subdirectories",
                    required=False,
                    default=False
                ),
                ToolParameter(
                    name="include_hidden",
                    type="boolean",
                    description="Include hidden files (starting with .)",
                    required=False,
                    default=False
                )
            ],
            tags=["directory", "list", "io"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        directory_path = kwargs["directory_path"]
        pattern = kwargs.get("pattern", "*")
        recursive = kwargs.get("recursive", False)
        include_hidden = kwargs.get("include_hidden", False)
        
        if recursive:
            search_pattern = os.path.join(directory_path, "**", pattern)
            files = glob.glob(search_pattern, recursive=True)
        else:
            search_pattern = os.path.join(directory_path, pattern)
            files = glob.glob(search_pattern)
        
        if not include_hidden:
            files = [f for f in files if not os.path.basename(f).startswith('.')]
        
        items = []
        for f in files:
            stat = os.stat(f)
            items.append({
                "path": f,
                "name": os.path.basename(f),
                "is_file": os.path.isfile(f),
                "is_dir": os.path.isdir(f),
                "size": stat.st_size,
                "modified": datetime.fromtimestamp(stat.st_mtime).isoformat()
            })
        
        return {
            "directory": directory_path,
            "pattern": pattern,
            "count": len(items),
            "items": items
        }


class CreateDirectory(BaseTool):
    """
    Create a new directory.
    
    Creates a directory and optionally all parent directories in the path.
    """
    
    def __init__(self):
        super().__init__(
            name="create_directory",
            category=ToolCategory.FILESYSTEM,
            description="Create a new directory with optional parent creation",
            parameters=[
                ToolParameter(
                    name="directory_path",
                    type="string",
                    description="Path of the directory to create",
                    required=True
                ),
                ToolParameter(
                    name="parents",
                    type="boolean",
                    description="Create parent directories if they don't exist",
                    required=False,
                    default=True
                ),
                ToolParameter(
                    name="mode",
                    type="integer",
                    description="Directory permissions in octal (e.g., 755)",
                    required=False,
                    default=0o755
                )
            ],
            tags=["directory", "create", "io"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        directory_path = kwargs["directory_path"]
        parents = kwargs.get("parents", True)
        mode = kwargs.get("mode", 0o755)
        
        if parents:
            os.makedirs(directory_path, mode=mode, exist_ok=True)
        else:
            os.mkdir(directory_path, mode=mode)
        
        return {
            "directory_path": directory_path,
            "created": True,
            "absolute_path": os.path.abspath(directory_path)
        }


class DeleteFile(BaseTool):
    """
    Delete a file.
    
    Removes a file from the filesystem.
    """
    
    def __init__(self):
        super().__init__(
            name="delete_file",
            category=ToolCategory.FILESYSTEM,
            description="Delete a file from the filesystem",
            parameters=[
                ToolParameter(
                    name="file_path",
                    type="string",
                    description="Path to the file to delete",
                    required=True
                ),
                ToolParameter(
                    name="ignore_missing",
                    type="boolean",
                    description="Don't raise error if file doesn't exist",
                    required=False,
                    default=False
                )
            ],
            tags=["file", "delete", "io"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        file_path = kwargs["file_path"]
        ignore_missing = kwargs.get("ignore_missing", False)
        
        if ignore_missing and not os.path.exists(file_path):
            return {"file_path": file_path, "deleted": False, "reason": "File not found"}
        
        os.remove(file_path)
        
        return {
            "file_path": file_path,
            "deleted": True
        }


class DeleteDirectory(BaseTool):
    """
    Delete a directory.
    
    Removes a directory and optionally all its contents.
    """
    
    def __init__(self):
        super().__init__(
            name="delete_directory",
            category=ToolCategory.FILESYSTEM,
            description="Delete a directory and optionally its contents",
            parameters=[
                ToolParameter(
                    name="directory_path",
                    type="string",
                    description="Path to the directory to delete",
                    required=True
                ),
                ToolParameter(
                    name="recursive",
                    type="boolean",
                    description="Delete directory and all contents recursively",
                    required=False,
                    default=False
                )
            ],
            tags=["directory", "delete", "io"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        directory_path = kwargs["directory_path"]
        recursive = kwargs.get("recursive", False)
        
        if recursive:
            shutil.rmtree(directory_path)
        else:
            os.rmdir(directory_path)
        
        return {
            "directory_path": directory_path,
            "deleted": True
        }


class CopyFile(BaseTool):
    """
    Copy a file.
    
    Copies a file from source to destination, preserving metadata.
    """
    
    def __init__(self):
        super().__init__(
            name="copy_file",
            category=ToolCategory.FILESYSTEM,
            description="Copy a file from source to destination",
            parameters=[
                ToolParameter(
                    name="source_path",
                    type="string",
                    description="Path to the source file",
                    required=True
                ),
                ToolParameter(
                    name="destination_path",
                    type="string",
                    description="Path to the destination file",
                    required=True
                ),
                ToolParameter(
                    name="preserve_metadata",
                    type="boolean",
                    description="Preserve file metadata (timestamps, permissions)",
                    required=False,
                    default=True
                )
            ],
            tags=["file", "copy", "io"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        source_path = kwargs["source_path"]
        destination_path = kwargs["destination_path"]
        preserve_metadata = kwargs.get("preserve_metadata", True)
        
        if preserve_metadata:
            shutil.copy2(source_path, destination_path)
        else:
            shutil.copy(source_path, destination_path)
        
        return {
            "source_path": source_path,
            "destination_path": destination_path,
            "copied": True,
            "size_bytes": os.path.getsize(destination_path)
        }


class MoveFile(BaseTool):
    """
    Move or rename a file.
    
    Moves a file from source to destination, effectively renaming or relocating it.
    """
    
    def __init__(self):
        super().__init__(
            name="move_file",
            category=ToolCategory.FILESYSTEM,
            description="Move or rename a file",
            parameters=[
                ToolParameter(
                    name="source_path",
                    type="string",
                    description="Path to the source file",
                    required=True
                ),
                ToolParameter(
                    name="destination_path",
                    type="string",
                    description="Path to the destination file",
                    required=True
                )
            ],
            tags=["file", "move", "rename", "io"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        source_path = kwargs["source_path"]
        destination_path = kwargs["destination_path"]
        
        shutil.move(source_path, destination_path)
        
        return {
            "source_path": source_path,
            "destination_path": destination_path,
            "moved": True
        }


class GetFileInfo(BaseTool):
    """
    Get detailed information about a file.
    
    Returns metadata including size, permissions, timestamps, and type.
    """
    
    def __init__(self):
        super().__init__(
            name="get_file_info",
            category=ToolCategory.FILESYSTEM,
            description="Get detailed metadata and information about a file",
            parameters=[
                ToolParameter(
                    name="file_path",
                    type="string",
                    description="Path to the file",
                    required=True
                )
            ],
            tags=["file", "info", "metadata"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        file_path = kwargs["file_path"]
        
        stat = os.stat(file_path)
        
        return {
            "path": file_path,
            "absolute_path": os.path.abspath(file_path),
            "size_bytes": stat.st_size,
            "is_file": os.path.isfile(file_path),
            "is_dir": os.path.isdir(file_path),
            "is_symlink": os.path.islink(file_path),
            "permissions": oct(stat.st_mode)[-3:],
            "owner_uid": stat.st_uid,
            "group_gid": stat.st_gid,
            "created": datetime.fromtimestamp(stat.st_ctime).isoformat(),
            "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
            "accessed": datetime.fromtimestamp(stat.st_atime).isoformat()
        }


class SearchFiles(BaseTool):
    """
    Search for files matching criteria.
    
    Searches for files by name pattern, content, or other attributes.
    """
    
    def __init__(self):
        super().__init__(
            name="search_files",
            category=ToolCategory.FILESYSTEM,
            description="Search for files matching name pattern or content",
            parameters=[
                ToolParameter(
                    name="search_path",
                    type="string",
                    description="Base directory to search from",
                    required=True
                ),
                ToolParameter(
                    name="name_pattern",
                    type="string",
                    description="Glob pattern to match filenames",
                    required=False
                ),
                ToolParameter(
                    name="content_pattern",
                    type="string",
                    description="Text pattern to search within files",
                    required=False
                ),
                ToolParameter(
                    name="max_results",
                    type="integer",
                    description="Maximum number of results to return",
                    required=False,
                    default=100
                )
            ],
            tags=["file", "search", "find"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        search_path = kwargs["search_path"]
        name_pattern = kwargs.get("name_pattern", "*")
        content_pattern = kwargs.get("content_pattern")
        max_results = kwargs.get("max_results", 100)
        
        results = []
        search_pattern = os.path.join(search_path, "**", name_pattern)
        
        for file_path in glob.glob(search_pattern, recursive=True):
            if not os.path.isfile(file_path):
                continue
            
            match = {"path": file_path, "name": os.path.basename(file_path)}
            
            if content_pattern:
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        if content_pattern in content:
                            match["matched_content"] = True
                            results.append(match)
                except:
                    continue
            else:
                results.append(match)
            
            if len(results) >= max_results:
                break
        
        return {
            "search_path": search_path,
            "name_pattern": name_pattern,
            "content_pattern": content_pattern,
            "count": len(results),
            "results": results
        }


class ReadJSONFile(BaseTool):
    """
    Read and parse a JSON file.
    
    Reads a JSON file and returns parsed data structure.
    """
    
    def __init__(self):
        super().__init__(
            name="read_json_file",
            category=ToolCategory.FILESYSTEM,
            description="Read and parse a JSON file",
            parameters=[
                ToolParameter(
                    name="file_path",
                    type="string",
                    description="Path to the JSON file",
                    required=True
                )
            ],
            tags=["file", "json", "read", "parse"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        file_path = kwargs["file_path"]
        
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        return {
            "file_path": file_path,
            "data": data
        }


class WriteJSONFile(BaseTool):
    """
    Write data to a JSON file.
    
    Serializes data structure to JSON and writes to file.
    """
    
    def __init__(self):
        super().__init__(
            name="write_json_file",
            category=ToolCategory.FILESYSTEM,
            description="Write data to a JSON file with formatting",
            parameters=[
                ToolParameter(
                    name="file_path",
                    type="string",
                    description="Path to the JSON file",
                    required=True
                ),
                ToolParameter(
                    name="data",
                    type="object",
                    description="Data to write to JSON file",
                    required=True
                ),
                ToolParameter(
                    name="indent",
                    type="integer",
                    description="Indentation spaces for pretty printing",
                    required=False,
                    default=2
                )
            ],
            tags=["file", "json", "write"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        file_path = kwargs["file_path"]
        data = kwargs["data"]
        indent = kwargs.get("indent", 2)
        
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=indent)
        
        return {
            "file_path": file_path,
            "written": True
        }


class GetDirectorySize(BaseTool):
    """
    Calculate total size of a directory.
    
    Recursively calculates the total size of all files in a directory.
    """
    
    def __init__(self):
        super().__init__(
            name="get_directory_size",
            category=ToolCategory.FILESYSTEM,
            description="Calculate the total size of a directory recursively",
            parameters=[
                ToolParameter(
                    name="directory_path",
                    type="string",
                    description="Path to the directory",
                    required=True
                )
            ],
            tags=["directory", "size", "info"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        directory_path = kwargs["directory_path"]
        
        total_size = 0
        file_count = 0
        dir_count = 0
        
        for dirpath, dirnames, filenames in os.walk(directory_path):
            dir_count += len(dirnames)
            for filename in filenames:
                filepath = os.path.join(dirpath, filename)
                if os.path.isfile(filepath):
                    total_size += os.path.getsize(filepath)
                    file_count += 1
        
        return {
            "directory_path": directory_path,
            "total_size_bytes": total_size,
            "total_size_mb": round(total_size / (1024 * 1024), 2),
            "file_count": file_count,
            "directory_count": dir_count
        }


class CheckPathExists(BaseTool):
    """
    Check if a path exists.
    
    Verifies the existence of a file or directory path.
    """
    
    def __init__(self):
        super().__init__(
            name="check_path_exists",
            category=ToolCategory.FILESYSTEM,
            description="Check if a file or directory path exists",
            parameters=[
                ToolParameter(
                    name="path",
                    type="string",
                    description="Path to check for existence",
                    required=True
                )
            ],
            tags=["file", "directory", "check", "exists"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        path = kwargs["path"]
        
        exists = os.path.exists(path)
        
        return {
            "path": path,
            "exists": exists,
            "is_file": os.path.isfile(path) if exists else None,
            "is_dir": os.path.isdir(path) if exists else None,
            "is_symlink": os.path.islink(path) if exists else None
        }


class CreateSymlink(BaseTool):
    """
    Create a symbolic link.
    
    Creates a symbolic link pointing to a target file or directory.
    """
    
    def __init__(self):
        super().__init__(
            name="create_symlink",
            category=ToolCategory.FILESYSTEM,
            description="Create a symbolic link to a target file or directory",
            parameters=[
                ToolParameter(
                    name="target_path",
                    type="string",
                    description="Path to the target file or directory",
                    required=True
                ),
                ToolParameter(
                    name="link_path",
                    type="string",
                    description="Path where the symbolic link will be created",
                    required=True
                )
            ],
            tags=["symlink", "link", "create"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        target_path = kwargs["target_path"]
        link_path = kwargs["link_path"]
        
        os.symlink(target_path, link_path)
        
        return {
            "target_path": target_path,
            "link_path": link_path,
            "created": True
        }


class ChangePermissions(BaseTool):
    """
    Change file or directory permissions.
    
    Modifies the permission bits of a file or directory.
    """
    
    def __init__(self):
        super().__init__(
            name="change_permissions",
            category=ToolCategory.FILESYSTEM,
            description="Change permissions of a file or directory",
            parameters=[
                ToolParameter(
                    name="path",
                    type="string",
                    description="Path to the file or directory",
                    required=True
                ),
                ToolParameter(
                    name="mode",
                    type="integer",
                    description="Permission mode in octal (e.g., 755 for rwxr-xr-x)",
                    required=True
                ),
                ToolParameter(
                    name="recursive",
                    type="boolean",
                    description="Apply permissions recursively for directories",
                    required=False,
                    default=False
                )
            ],
            tags=["permissions", "chmod", "security"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        path = kwargs["path"]
        mode = kwargs["mode"]
        recursive = kwargs.get("recursive", False)
        
        if recursive and os.path.isdir(path):
            for root, dirs, files in os.walk(path):
                os.chmod(root, mode)
                for d in dirs:
                    os.chmod(os.path.join(root, d), mode)
                for f in files:
                    os.chmod(os.path.join(root, f), mode)
        else:
            os.chmod(path, mode)
        
        return {
            "path": path,
            "mode": oct(mode),
            "recursive": recursive,
            "changed": True
        }


class GetWorkingDirectory(BaseTool):
    """
    Get the current working directory.
    
    Returns the current working directory path.
    """
    
    def __init__(self):
        super().__init__(
            name="get_working_directory",
            category=ToolCategory.FILESYSTEM,
            description="Get the current working directory path",
            parameters=[],
            tags=["directory", "cwd", "path"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        cwd = os.getcwd()
        
        return {
            "working_directory": cwd,
            "absolute_path": os.path.abspath(cwd)
        }


class ChangeWorkingDirectory(BaseTool):
    """
    Change the current working directory.
    
    Changes the current working directory to the specified path.
    """
    
    def __init__(self):
        super().__init__(
            name="change_working_directory",
            category=ToolCategory.FILESYSTEM,
            description="Change the current working directory",
            parameters=[
                ToolParameter(
                    name="directory_path",
                    type="string",
                    description="Path to change to",
                    required=True
                )
            ],
            tags=["directory", "cwd", "navigation"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        directory_path = kwargs["directory_path"]
        
        os.chdir(directory_path)
        new_cwd = os.getcwd()
        
        return {
            "previous_directory": kwargs.get("previous_cwd"),
            "current_directory": new_cwd
        }
