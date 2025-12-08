"""
Docker and Container Management Tools

This module provides comprehensive Docker operation tools
that are OpenAI-compatible and follow the MCP protocol.
"""

from typing import Dict, Any, List, Optional
from .base import BaseTool, ToolCategory, ToolParameter, ToolResult
import subprocess
import json


class DockerListContainers(BaseTool):
    """List Docker containers."""
    
    def __init__(self):
        super().__init__(
            name="docker_list_containers",
            category=ToolCategory.BUILD,
            description="List Docker containers with optional filtering",
            parameters=[
                ToolParameter(
                    name="all_containers",
                    type="boolean",
                    description="Show all containers (default shows running only)",
                    required=False,
                    default=False
                ),
                ToolParameter(
                    name="format",
                    type="string",
                    description="Output format",
                    required=False,
                    default="json",
                    enum=["json", "table"]
                )
            ],
            tags=["docker", "container", "list"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        all_containers = kwargs.get("all_containers", False)
        output_format = kwargs.get("format", "json")
        
        cmd = ["docker", "ps"]
        
        if all_containers:
            cmd.append("-a")
        
        if output_format == "json":
            cmd.append("--format={{json .}}")
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            containers = []
            for line in result.stdout.strip().split('\n'):
                if line:
                    try:
                        containers.append(json.loads(line))
                    except json.JSONDecodeError:
                        pass
            
            return {
                "containers": containers,
                "count": len(containers)
            }
        else:
            result = subprocess.run(cmd, capture_output=True, text=True)
            return {
                "output": result.stdout,
                "format": "table"
            }


class DockerRunContainer(BaseTool):
    """Run a Docker container."""
    
    def __init__(self):
        super().__init__(
            name="docker_run_container",
            category=ToolCategory.BUILD,
            description="Run a Docker container with specified image and options",
            parameters=[
                ToolParameter(
                    name="image",
                    type="string",
                    description="Docker image to run",
                    required=True
                ),
                ToolParameter(
                    name="name",
                    type="string",
                    description="Container name",
                    required=False
                ),
                ToolParameter(
                    name="ports",
                    type="array",
                    description="Port mappings (e.g., ['8080:80', '443:443'])",
                    required=False
                ),
                ToolParameter(
                    name="environment",
                    type="object",
                    description="Environment variables",
                    required=False
                ),
                ToolParameter(
                    name="detached",
                    type="boolean",
                    description="Run container in detached mode",
                    required=False,
                    default=True
                )
            ],
            tags=["docker", "container", "run"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        image = kwargs["image"]
        name = kwargs.get("name")
        ports = kwargs.get("ports", [])
        environment = kwargs.get("environment", {})
        detached = kwargs.get("detached", True)
        
        cmd = ["docker", "run"]
        
        if detached:
            cmd.append("-d")
        
        if name:
            cmd.extend(["--name", name])
        
        for port in ports:
            cmd.extend(["-p", port])
        
        for key, value in environment.items():
            cmd.extend(["-e", f"{key}={value}"])
        
        cmd.append(image)
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "success": result.returncode == 0,
            "container_id": result.stdout.strip() if result.returncode == 0 else None,
            "image": image,
            "error": result.stderr if result.returncode != 0 else None
        }


class DockerStopContainer(BaseTool):
    """Stop a Docker container."""
    
    def __init__(self):
        super().__init__(
            name="docker_stop_container",
            category=ToolCategory.BUILD,
            description="Stop a running Docker container",
            parameters=[
                ToolParameter(
                    name="container",
                    type="string",
                    description="Container ID or name",
                    required=True
                ),
                ToolParameter(
                    name="timeout",
                    type="integer",
                    description="Seconds to wait before killing",
                    required=False,
                    default=10
                )
            ],
            tags=["docker", "container", "stop"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        container = kwargs["container"]
        timeout = kwargs.get("timeout", 10)
        
        cmd = ["docker", "stop", "-t", str(timeout), container]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "success": result.returncode == 0,
            "container": container,
            "error": result.stderr if result.returncode != 0 else None
        }


class DockerRemoveContainer(BaseTool):
    """Remove a Docker container."""
    
    def __init__(self):
        super().__init__(
            name="docker_remove_container",
            category=ToolCategory.BUILD,
            description="Remove a Docker container",
            parameters=[
                ToolParameter(
                    name="container",
                    type="string",
                    description="Container ID or name",
                    required=True
                ),
                ToolParameter(
                    name="force",
                    type="boolean",
                    description="Force removal of running container",
                    required=False,
                    default=False
                )
            ],
            tags=["docker", "container", "remove"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        container = kwargs["container"]
        force = kwargs.get("force", False)
        
        cmd = ["docker", "rm"]
        
        if force:
            cmd.append("-f")
        
        cmd.append(container)
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "success": result.returncode == 0,
            "container": container,
            "error": result.stderr if result.returncode != 0 else None
        }


class DockerLogs(BaseTool):
    """Get container logs."""
    
    def __init__(self):
        super().__init__(
            name="docker_logs",
            category=ToolCategory.MONITORING,
            description="Get logs from a Docker container",
            parameters=[
                ToolParameter(
                    name="container",
                    type="string",
                    description="Container ID or name",
                    required=True
                ),
                ToolParameter(
                    name="tail",
                    type="integer",
                    description="Number of lines from end of logs",
                    required=False
                ),
                ToolParameter(
                    name="follow",
                    type="boolean",
                    description="Follow log output",
                    required=False,
                    default=False
                )
            ],
            tags=["docker", "logs", "container"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        container = kwargs["container"]
        tail = kwargs.get("tail")
        follow = kwargs.get("follow", False)
        
        cmd = ["docker", "logs"]
        
        if tail:
            cmd.extend(["--tail", str(tail)])
        
        if follow:
            cmd.append("-f")
        
        cmd.append(container)
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
        
        return {
            "container": container,
            "logs": result.stdout,
            "errors": result.stderr
        }


class DockerInspect(BaseTool):
    """Inspect Docker container or image."""
    
    def __init__(self):
        super().__init__(
            name="docker_inspect",
            category=ToolCategory.MONITORING,
            description="Get detailed information about container or image",
            parameters=[
                ToolParameter(
                    name="target",
                    type="string",
                    description="Container or image ID/name",
                    required=True
                )
            ],
            tags=["docker", "inspect", "info"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        target = kwargs["target"]
        
        cmd = ["docker", "inspect", target]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            info = json.loads(result.stdout)[0]
            return {
                "success": True,
                "info": info
            }
        else:
            return {
                "success": False,
                "error": result.stderr
            }


class DockerListImages(BaseTool):
    """List Docker images."""
    
    def __init__(self):
        super().__init__(
            name="docker_list_images",
            category=ToolCategory.BUILD,
            description="List Docker images",
            parameters=[
                ToolParameter(
                    name="filter",
                    type="string",
                    description="Filter images (e.g., 'dangling=true')",
                    required=False
                )
            ],
            tags=["docker", "image", "list"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        filter_str = kwargs.get("filter")
        
        cmd = ["docker", "images", "--format={{json .}}"]
        
        if filter_str:
            cmd.extend(["--filter", filter_str])
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        images = []
        for line in result.stdout.strip().split('\n'):
            if line:
                try:
                    images.append(json.loads(line))
                except json.JSONDecodeError:
                    pass
        
        return {
            "images": images,
            "count": len(images)
        }


class DockerPullImage(BaseTool):
    """Pull Docker image."""
    
    def __init__(self):
        super().__init__(
            name="docker_pull_image",
            category=ToolCategory.BUILD,
            description="Pull a Docker image from registry",
            parameters=[
                ToolParameter(
                    name="image",
                    type="string",
                    description="Image name with optional tag (e.g., 'nginx:latest')",
                    required=True
                )
            ],
            tags=["docker", "image", "pull"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        image = kwargs["image"]
        
        cmd = ["docker", "pull", image]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "success": result.returncode == 0,
            "image": image,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class DockerBuildImage(BaseTool):
    """Build Docker image from Dockerfile."""
    
    def __init__(self):
        super().__init__(
            name="docker_build_image",
            category=ToolCategory.BUILD,
            description="Build Docker image from Dockerfile",
            parameters=[
                ToolParameter(
                    name="path",
                    type="string",
                    description="Build context path",
                    required=True
                ),
                ToolParameter(
                    name="tag",
                    type="string",
                    description="Image tag",
                    required=True
                ),
                ToolParameter(
                    name="dockerfile",
                    type="string",
                    description="Dockerfile name (default: Dockerfile)",
                    required=False,
                    default="Dockerfile"
                )
            ],
            tags=["docker", "image", "build"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        path = kwargs["path"]
        tag = kwargs["tag"]
        dockerfile = kwargs.get("dockerfile", "Dockerfile")
        
        cmd = ["docker", "build", "-t", tag, "-f", dockerfile, path]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "success": result.returncode == 0,
            "tag": tag,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class DockerComposeUp(BaseTool):
    """Start services with Docker Compose."""
    
    def __init__(self):
        super().__init__(
            name="docker_compose_up",
            category=ToolCategory.BUILD,
            description="Start services defined in docker-compose.yml",
            parameters=[
                ToolParameter(
                    name="project_path",
                    type="string",
                    description="Path to docker-compose.yml directory",
                    required=True
                ),
                ToolParameter(
                    name="detached",
                    type="boolean",
                    description="Run in detached mode",
                    required=False,
                    default=True
                ),
                ToolParameter(
                    name="build",
                    type="boolean",
                    description="Build images before starting",
                    required=False,
                    default=False
                )
            ],
            tags=["docker", "compose", "up"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        project_path = kwargs["project_path"]
        detached = kwargs.get("detached", True)
        build = kwargs.get("build", False)
        
        cmd = ["docker-compose", "-f", f"{project_path}/docker-compose.yml", "up"]
        
        if detached:
            cmd.append("-d")
        
        if build:
            cmd.append("--build")
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "success": result.returncode == 0,
            "project_path": project_path,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class DockerComposeDown(BaseTool):
    """Stop and remove Docker Compose services."""
    
    def __init__(self):
        super().__init__(
            name="docker_compose_down",
            category=ToolCategory.BUILD,
            description="Stop and remove containers, networks, volumes",
            parameters=[
                ToolParameter(
                    name="project_path",
                    type="string",
                    description="Path to docker-compose.yml directory",
                    required=True
                ),
                ToolParameter(
                    name="remove_volumes",
                    type="boolean",
                    description="Remove named volumes",
                    required=False,
                    default=False
                )
            ],
            tags=["docker", "compose", "down"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        project_path = kwargs["project_path"]
        remove_volumes = kwargs.get("remove_volumes", False)
        
        cmd = ["docker-compose", "-f", f"{project_path}/docker-compose.yml", "down"]
        
        if remove_volumes:
            cmd.append("-v")
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "success": result.returncode == 0,
            "project_path": project_path,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class DockerExec(BaseTool):
    """Execute command in running container."""
    
    def __init__(self):
        super().__init__(
            name="docker_exec",
            category=ToolCategory.BUILD,
            description="Execute a command in a running container",
            parameters=[
                ToolParameter(
                    name="container",
                    type="string",
                    description="Container ID or name",
                    required=True
                ),
                ToolParameter(
                    name="command",
                    type="string",
                    description="Command to execute",
                    required=True
                ),
                ToolParameter(
                    name="interactive",
                    type="boolean",
                    description="Keep STDIN open",
                    required=False,
                    default=False
                )
            ],
            tags=["docker", "exec", "command"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        container = kwargs["container"]
        command = kwargs["command"]
        interactive = kwargs.get("interactive", False)
        
        cmd = ["docker", "exec"]
        
        if interactive:
            cmd.append("-it")
        
        cmd.extend([container, "sh", "-c", command])
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            "success": result.returncode == 0,
            "container": container,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None
        }


class DockerStats(BaseTool):
    """Get container resource usage statistics."""
    
    def __init__(self):
        super().__init__(
            name="docker_stats",
            category=ToolCategory.MONITORING,
            description="Get real-time resource usage statistics for containers",
            parameters=[
                ToolParameter(
                    name="container",
                    type="string",
                    description="Container ID or name (omit for all)",
                    required=False
                ),
                ToolParameter(
                    name="no_stream",
                    type="boolean",
                    description="Show single snapshot instead of streaming",
                    required=False,
                    default=True
                )
            ],
            tags=["docker", "stats", "monitoring"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        container = kwargs.get("container")
        no_stream = kwargs.get("no_stream", True)
        
        cmd = ["docker", "stats", "--format={{json .}}", "--no-trunc"]
        
        if no_stream:
            cmd.append("--no-stream")
        
        if container:
            cmd.append(container)
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
        
        stats = []
        for line in result.stdout.strip().split('\n'):
            if line:
                try:
                    stats.append(json.loads(line))
                except json.JSONDecodeError:
                    pass
        
        return {
            "stats": stats,
            "count": len(stats)
        }
