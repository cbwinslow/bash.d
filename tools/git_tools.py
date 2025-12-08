"""
Git and Version Control Tools

This module provides comprehensive Git operation tools
that are OpenAI-compatible and follow the MCP protocol.
"""

from typing import Dict, Any, List, Optional
from .base import BaseTool, ToolCategory, ToolParameter, ToolResult
import subprocess
import os


class GitInit(BaseTool):
    """
    Initialize a new Git repository.
    
    Creates a new Git repository in the specified directory.
    """
    
    def __init__(self):
        super().__init__(
            name="git_init",
            category=ToolCategory.BUILD,
            description="Initialize a new Git repository",
            parameters=[
                ToolParameter(
                    name="directory",
                    type="string",
                    description="Directory to initialize Git repository in",
                    required=True
                ),
                ToolParameter(
                    name="initial_branch",
                    type="string",
                    description="Name of the initial branch (default: main)",
                    required=False,
                    default="main"
                )
            ],
            tags=["git", "vcs", "init"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        directory = kwargs["directory"]
        initial_branch = kwargs.get("initial_branch", "main")
        
        # Create directory if it doesn't exist
        os.makedirs(directory, exist_ok=True)
        
        # Initialize git repo
        result = subprocess.run(
            ["git", "init", "-b", initial_branch, directory],
            capture_output=True,
            text=True
        )
        
        return {
            "directory": directory,
            "initial_branch": initial_branch,
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class GitClone(BaseTool):
    """
    Clone a Git repository.
    
    Clones a remote repository to a local directory.
    """
    
    def __init__(self):
        super().__init__(
            name="git_clone",
            category=ToolCategory.BUILD,
            description="Clone a Git repository from remote URL",
            parameters=[
                ToolParameter(
                    name="repository_url",
                    type="string",
                    description="URL of the repository to clone",
                    required=True
                ),
                ToolParameter(
                    name="destination",
                    type="string",
                    description="Local directory to clone into",
                    required=False
                ),
                ToolParameter(
                    name="branch",
                    type="string",
                    description="Specific branch to clone",
                    required=False
                ),
                ToolParameter(
                    name="depth",
                    type="integer",
                    description="Create a shallow clone with depth commits",
                    required=False
                )
            ],
            tags=["git", "clone", "vcs"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        repository_url = kwargs["repository_url"]
        destination = kwargs.get("destination")
        branch = kwargs.get("branch")
        depth = kwargs.get("depth")
        
        cmd = ["git", "clone"]
        
        if branch:
            cmd.extend(["-b", branch])
        
        if depth:
            cmd.extend(["--depth", str(depth)])
        
        cmd.append(repository_url)
        
        if destination:
            cmd.append(destination)
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "repository_url": repository_url,
            "destination": destination,
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class GitStatus(BaseTool):
    """
    Get Git repository status.
    
    Shows the working tree status including modified, staged, and untracked files.
    """
    
    def __init__(self):
        super().__init__(
            name="git_status",
            category=ToolCategory.BUILD,
            description="Get the status of Git repository",
            parameters=[
                ToolParameter(
                    name="repository_path",
                    type="string",
                    description="Path to Git repository",
                    required=True
                ),
                ToolParameter(
                    name="short_format",
                    type="boolean",
                    description="Use short format output",
                    required=False,
                    default=False
                )
            ],
            tags=["git", "status", "vcs"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        repository_path = kwargs["repository_path"]
        short_format = kwargs.get("short_format", False)
        
        cmd = ["git", "-C", repository_path, "status"]
        
        if short_format:
            cmd.append("--short")
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "repository_path": repository_path,
            "success": result.returncode == 0,
            "status": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class GitAdd(BaseTool):
    """
    Stage files for commit.
    
    Adds files to the staging area for the next commit.
    """
    
    def __init__(self):
        super().__init__(
            name="git_add",
            category=ToolCategory.BUILD,
            description="Stage files for commit in Git repository",
            parameters=[
                ToolParameter(
                    name="repository_path",
                    type="string",
                    description="Path to Git repository",
                    required=True
                ),
                ToolParameter(
                    name="files",
                    type="array",
                    description="List of files to stage (use ['.'] for all)",
                    required=True
                )
            ],
            tags=["git", "add", "stage", "vcs"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        repository_path = kwargs["repository_path"]
        files = kwargs["files"]
        
        cmd = ["git", "-C", repository_path, "add"] + files
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "repository_path": repository_path,
            "files": files,
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class GitCommit(BaseTool):
    """
    Commit staged changes.
    
    Creates a new commit with staged changes and a commit message.
    """
    
    def __init__(self):
        super().__init__(
            name="git_commit",
            category=ToolCategory.BUILD,
            description="Commit staged changes with a message",
            parameters=[
                ToolParameter(
                    name="repository_path",
                    type="string",
                    description="Path to Git repository",
                    required=True
                ),
                ToolParameter(
                    name="message",
                    type="string",
                    description="Commit message",
                    required=True
                ),
                ToolParameter(
                    name="author",
                    type="string",
                    description="Author name and email (format: 'Name <email>')",
                    required=False
                )
            ],
            tags=["git", "commit", "vcs"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        repository_path = kwargs["repository_path"]
        message = kwargs["message"]
        author = kwargs.get("author")
        
        cmd = ["git", "-C", repository_path, "commit", "-m", message]
        
        if author:
            cmd.extend(["--author", author])
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "repository_path": repository_path,
            "message": message,
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class GitPush(BaseTool):
    """
    Push commits to remote repository.
    
    Pushes local commits to the remote repository.
    """
    
    def __init__(self):
        super().__init__(
            name="git_push",
            category=ToolCategory.BUILD,
            description="Push commits to remote repository",
            parameters=[
                ToolParameter(
                    name="repository_path",
                    type="string",
                    description="Path to Git repository",
                    required=True
                ),
                ToolParameter(
                    name="remote",
                    type="string",
                    description="Remote name (default: origin)",
                    required=False,
                    default="origin"
                ),
                ToolParameter(
                    name="branch",
                    type="string",
                    description="Branch to push",
                    required=False
                ),
                ToolParameter(
                    name="force",
                    type="boolean",
                    description="Force push",
                    required=False,
                    default=False
                )
            ],
            tags=["git", "push", "vcs", "remote"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        repository_path = kwargs["repository_path"]
        remote = kwargs.get("remote", "origin")
        branch = kwargs.get("branch")
        force = kwargs.get("force", False)
        
        cmd = ["git", "-C", repository_path, "push"]
        
        if force:
            cmd.append("--force")
        
        cmd.append(remote)
        
        if branch:
            cmd.append(branch)
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "repository_path": repository_path,
            "remote": remote,
            "branch": branch,
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class GitPull(BaseTool):
    """
    Pull changes from remote repository.
    
    Fetches and integrates changes from the remote repository.
    """
    
    def __init__(self):
        super().__init__(
            name="git_pull",
            category=ToolCategory.BUILD,
            description="Pull changes from remote repository",
            parameters=[
                ToolParameter(
                    name="repository_path",
                    type="string",
                    description="Path to Git repository",
                    required=True
                ),
                ToolParameter(
                    name="remote",
                    type="string",
                    description="Remote name (default: origin)",
                    required=False,
                    default="origin"
                ),
                ToolParameter(
                    name="branch",
                    type="string",
                    description="Branch to pull",
                    required=False
                )
            ],
            tags=["git", "pull", "vcs", "remote"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        repository_path = kwargs["repository_path"]
        remote = kwargs.get("remote", "origin")
        branch = kwargs.get("branch")
        
        cmd = ["git", "-C", repository_path, "pull", remote]
        
        if branch:
            cmd.append(branch)
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "repository_path": repository_path,
            "remote": remote,
            "branch": branch,
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class GitBranch(BaseTool):
    """
    List, create, or delete branches.
    
    Manages Git branches in the repository.
    """
    
    def __init__(self):
        super().__init__(
            name="git_branch",
            category=ToolCategory.BUILD,
            description="List, create, or delete Git branches",
            parameters=[
                ToolParameter(
                    name="repository_path",
                    type="string",
                    description="Path to Git repository",
                    required=True
                ),
                ToolParameter(
                    name="action",
                    type="string",
                    description="Action to perform",
                    required=False,
                    default="list",
                    enum=["list", "create", "delete"]
                ),
                ToolParameter(
                    name="branch_name",
                    type="string",
                    description="Branch name (for create/delete)",
                    required=False
                )
            ],
            tags=["git", "branch", "vcs"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        repository_path = kwargs["repository_path"]
        action = kwargs.get("action", "list")
        branch_name = kwargs.get("branch_name")
        
        if action == "list":
            cmd = ["git", "-C", repository_path, "branch", "-a"]
        elif action == "create":
            if not branch_name:
                raise ValueError("branch_name required for create action")
            cmd = ["git", "-C", repository_path, "branch", branch_name]
        elif action == "delete":
            if not branch_name:
                raise ValueError("branch_name required for delete action")
            cmd = ["git", "-C", repository_path, "branch", "-d", branch_name]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "repository_path": repository_path,
            "action": action,
            "branch_name": branch_name,
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class GitCheckout(BaseTool):
    """
    Switch branches or restore files.
    
    Checks out a branch or restores working tree files.
    """
    
    def __init__(self):
        super().__init__(
            name="git_checkout",
            category=ToolCategory.BUILD,
            description="Switch to a different branch or restore files",
            parameters=[
                ToolParameter(
                    name="repository_path",
                    type="string",
                    description="Path to Git repository",
                    required=True
                ),
                ToolParameter(
                    name="branch_name",
                    type="string",
                    description="Branch name to checkout",
                    required=True
                ),
                ToolParameter(
                    name="create_new",
                    type="boolean",
                    description="Create new branch if it doesn't exist",
                    required=False,
                    default=False
                )
            ],
            tags=["git", "checkout", "switch", "vcs"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        repository_path = kwargs["repository_path"]
        branch_name = kwargs["branch_name"]
        create_new = kwargs.get("create_new", False)
        
        cmd = ["git", "-C", repository_path, "checkout"]
        
        if create_new:
            cmd.append("-b")
        
        cmd.append(branch_name)
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "repository_path": repository_path,
            "branch_name": branch_name,
            "created_new": create_new,
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class GitLog(BaseTool):
    """
    View commit history.
    
    Shows the commit logs with optional filtering.
    """
    
    def __init__(self):
        super().__init__(
            name="git_log",
            category=ToolCategory.BUILD,
            description="View commit history",
            parameters=[
                ToolParameter(
                    name="repository_path",
                    type="string",
                    description="Path to Git repository",
                    required=True
                ),
                ToolParameter(
                    name="max_count",
                    type="integer",
                    description="Maximum number of commits to show",
                    required=False,
                    default=10
                ),
                ToolParameter(
                    name="oneline",
                    type="boolean",
                    description="Show one commit per line",
                    required=False,
                    default=False
                )
            ],
            tags=["git", "log", "history", "vcs"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        repository_path = kwargs["repository_path"]
        max_count = kwargs.get("max_count", 10)
        oneline = kwargs.get("oneline", False)
        
        cmd = ["git", "-C", repository_path, "log", f"-{max_count}"]
        
        if oneline:
            cmd.append("--oneline")
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "repository_path": repository_path,
            "max_count": max_count,
            "success": result.returncode == 0,
            "log": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class GitDiff(BaseTool):
    """
    Show changes between commits, branches, or working tree.
    
    Displays differences in the repository.
    """
    
    def __init__(self):
        super().__init__(
            name="git_diff",
            category=ToolCategory.BUILD,
            description="Show differences in repository",
            parameters=[
                ToolParameter(
                    name="repository_path",
                    type="string",
                    description="Path to Git repository",
                    required=True
                ),
                ToolParameter(
                    name="target",
                    type="string",
                    description="Target to diff (file, branch, commit)",
                    required=False
                ),
                ToolParameter(
                    name="staged",
                    type="boolean",
                    description="Show staged changes only",
                    required=False,
                    default=False
                )
            ],
            tags=["git", "diff", "changes", "vcs"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        repository_path = kwargs["repository_path"]
        target = kwargs.get("target")
        staged = kwargs.get("staged", False)
        
        cmd = ["git", "-C", repository_path, "diff"]
        
        if staged:
            cmd.append("--staged")
        
        if target:
            cmd.append(target)
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "repository_path": repository_path,
            "target": target,
            "staged": staged,
            "success": result.returncode == 0,
            "diff": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class GitTag(BaseTool):
    """
    Create, list, or delete tags.
    
    Manages Git tags for marking specific points in history.
    """
    
    def __init__(self):
        super().__init__(
            name="git_tag",
            category=ToolCategory.BUILD,
            description="Create, list, or delete Git tags",
            parameters=[
                ToolParameter(
                    name="repository_path",
                    type="string",
                    description="Path to Git repository",
                    required=True
                ),
                ToolParameter(
                    name="action",
                    type="string",
                    description="Action to perform",
                    required=False,
                    default="list",
                    enum=["list", "create", "delete"]
                ),
                ToolParameter(
                    name="tag_name",
                    type="string",
                    description="Tag name",
                    required=False
                ),
                ToolParameter(
                    name="message",
                    type="string",
                    description="Tag message (for annotated tags)",
                    required=False
                )
            ],
            tags=["git", "tag", "vcs"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        repository_path = kwargs["repository_path"]
        action = kwargs.get("action", "list")
        tag_name = kwargs.get("tag_name")
        message = kwargs.get("message")
        
        if action == "list":
            cmd = ["git", "-C", repository_path, "tag"]
        elif action == "create":
            if not tag_name:
                raise ValueError("tag_name required for create action")
            cmd = ["git", "-C", repository_path, "tag"]
            if message:
                cmd.extend(["-a", tag_name, "-m", message])
            else:
                cmd.append(tag_name)
        elif action == "delete":
            if not tag_name:
                raise ValueError("tag_name required for delete action")
            cmd = ["git", "-C", repository_path, "tag", "-d", tag_name]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "repository_path": repository_path,
            "action": action,
            "tag_name": tag_name,
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class GitRemote(BaseTool):
    """
    Manage remote repositories.
    
    List, add, remove, or show information about remote repositories.
    """
    
    def __init__(self):
        super().__init__(
            name="git_remote",
            category=ToolCategory.BUILD,
            description="Manage Git remote repositories",
            parameters=[
                ToolParameter(
                    name="repository_path",
                    type="string",
                    description="Path to Git repository",
                    required=True
                ),
                ToolParameter(
                    name="action",
                    type="string",
                    description="Action to perform",
                    required=False,
                    default="list",
                    enum=["list", "add", "remove", "show"]
                ),
                ToolParameter(
                    name="remote_name",
                    type="string",
                    description="Remote name",
                    required=False
                ),
                ToolParameter(
                    name="remote_url",
                    type="string",
                    description="Remote URL (for add action)",
                    required=False
                )
            ],
            tags=["git", "remote", "vcs"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        repository_path = kwargs["repository_path"]
        action = kwargs.get("action", "list")
        remote_name = kwargs.get("remote_name")
        remote_url = kwargs.get("remote_url")
        
        if action == "list":
            cmd = ["git", "-C", repository_path, "remote", "-v"]
        elif action == "add":
            if not remote_name or not remote_url:
                raise ValueError("remote_name and remote_url required for add action")
            cmd = ["git", "-C", repository_path, "remote", "add", remote_name, remote_url]
        elif action == "remove":
            if not remote_name:
                raise ValueError("remote_name required for remove action")
            cmd = ["git", "-C", repository_path, "remote", "remove", remote_name]
        elif action == "show":
            if not remote_name:
                raise ValueError("remote_name required for show action")
            cmd = ["git", "-C", repository_path, "remote", "show", remote_name]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "repository_path": repository_path,
            "action": action,
            "remote_name": remote_name,
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class GitStash(BaseTool):
    """
    Stash changes in working directory.
    
    Saves local modifications and reverts to clean working directory.
    """
    
    def __init__(self):
        super().__init__(
            name="git_stash",
            category=ToolCategory.BUILD,
            description="Stash or apply stashed changes",
            parameters=[
                ToolParameter(
                    name="repository_path",
                    type="string",
                    description="Path to Git repository",
                    required=True
                ),
                ToolParameter(
                    name="action",
                    type="string",
                    description="Stash action",
                    required=False,
                    default="save",
                    enum=["save", "pop", "apply", "list", "drop"]
                ),
                ToolParameter(
                    name="message",
                    type="string",
                    description="Stash message",
                    required=False
                )
            ],
            tags=["git", "stash", "vcs"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        repository_path = kwargs["repository_path"]
        action = kwargs.get("action", "save")
        message = kwargs.get("message")
        
        cmd = ["git", "-C", repository_path, "stash"]
        
        if action == "save":
            if message:
                cmd.extend(["push", "-m", message])
        elif action in ["pop", "apply", "list", "drop"]:
            cmd.append(action)
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "repository_path": repository_path,
            "action": action,
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class GitMerge(BaseTool):
    """
    Merge branches.
    
    Joins two or more development histories together.
    """
    
    def __init__(self):
        super().__init__(
            name="git_merge",
            category=ToolCategory.BUILD,
            description="Merge branches in Git repository",
            parameters=[
                ToolParameter(
                    name="repository_path",
                    type="string",
                    description="Path to Git repository",
                    required=True
                ),
                ToolParameter(
                    name="branch_name",
                    type="string",
                    description="Branch to merge into current branch",
                    required=True
                ),
                ToolParameter(
                    name="no_ff",
                    type="boolean",
                    description="Create merge commit even if fast-forward possible",
                    required=False,
                    default=False
                )
            ],
            tags=["git", "merge", "vcs"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        repository_path = kwargs["repository_path"]
        branch_name = kwargs["branch_name"]
        no_ff = kwargs.get("no_ff", False)
        
        cmd = ["git", "-C", repository_path, "merge"]
        
        if no_ff:
            cmd.append("--no-ff")
        
        cmd.append(branch_name)
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "repository_path": repository_path,
            "branch_name": branch_name,
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }
