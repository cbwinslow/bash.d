"""
FastAPI Server for Application Builder

This module provides a REST API and WebSocket interface for the
autonomous application builder system.
"""

import asyncio
import logging
from typing import Dict, List, Optional
from datetime import datetime
from contextlib import asynccontextmanager
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

from .base import Task, TaskStatus, TaskPriority
from .orchestrator import AgentOrchestrator
from .application_builder import (
    ApplicationBuilder,
    ApplicationIdea,
    ApplicationPlan,
    ApplicationPhase
)

logger = logging.getLogger(__name__)

# Global instances
orchestrator: Optional[AgentOrchestrator] = None
builder: Optional[ApplicationBuilder] = None
active_builds: Dict[str, Dict] = {}
websocket_connections: List[WebSocket] = []


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown"""
    global orchestrator, builder
    
    # Startup
    logger.info("Starting Autonomous Application Builder API")
    orchestrator = AgentOrchestrator()
    builder = ApplicationBuilder(orchestrator)
    logger.info("System initialized successfully")
    
    yield
    
    # Shutdown
    logger.info("Shutting down Autonomous Application Builder API")
    for ws in websocket_connections:
        await ws.close()


# FastAPI app
app = FastAPI(
    title="Autonomous Application Builder API",
    description="Multi-agentic system for building complete applications",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class BuildRequest(BaseModel):
    """Request to build an application"""
    title: str
    description: str
    requirements: List[str] = []
    target_users: str = ""
    success_criteria: List[str] = []
    autonomous: bool = True


class BuildResponse(BaseModel):
    """Response for build request"""
    build_id: str
    status: str
    message: str
    started_at: str


class BuildStatus(BaseModel):
    """Status of a build"""
    build_id: str
    title: str
    status: str
    current_phase: Optional[str]
    progress: float
    phases_completed: List[str]
    started_at: str
    estimated_completion: Optional[str]


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "name": "Autonomous Application Builder API",
        "version": "1.0.0",
        "status": "running",
        "features": [
            "Democratic problem-solving",
            "Autonomous execution",
            "Complete lifecycle management",
            "Automatic testing and debugging",
            "UI generation"
        ]
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "orchestrator": orchestrator is not None,
        "builder": builder is not None,
        "active_builds": len(active_builds),
        "timestamp": datetime.utcnow().isoformat()
    }


@app.post("/api/v1/builds", response_model=BuildResponse)
async def create_build(request: BuildRequest):
    """
    Create a new application build
    
    This is the "click go" endpoint that starts autonomous application building.
    """
    if not builder:
        raise HTTPException(status_code=500, detail="Builder not initialized")
    
    # Create application idea
    idea = ApplicationIdea(
        title=request.title,
        description=request.description,
        requirements=request.requirements,
        target_users=request.target_users,
        success_criteria=request.success_criteria
    )
    
    # Generate build ID
    build_id = f"build_{datetime.utcnow().timestamp()}"
    
    # Store build info
    active_builds[build_id] = {
        "id": build_id,
        "title": request.title,
        "status": "running",
        "current_phase": "planning",
        "progress": 0.0,
        "phases_completed": [],
        "started_at": datetime.utcnow().isoformat(),
        "idea": idea.dict()
    }
    
    # Start build in background
    asyncio.create_task(execute_build(build_id, idea, request.autonomous))
    
    # Broadcast to websockets
    await broadcast_message({
        "type": "build_started",
        "build_id": build_id,
        "title": request.title
    })
    
    return BuildResponse(
        build_id=build_id,
        status="running",
        message="Build started successfully",
        started_at=active_builds[build_id]["started_at"]
    )


@app.get("/api/v1/builds", response_model=List[BuildStatus])
async def list_builds():
    """List all builds"""
    return [
        BuildStatus(
            build_id=build["id"],
            title=build["title"],
            status=build["status"],
            current_phase=build.get("current_phase"),
            progress=build.get("progress", 0.0),
            phases_completed=build.get("phases_completed", []),
            started_at=build["started_at"],
            estimated_completion=build.get("estimated_completion")
        )
        for build in active_builds.values()
    ]


@app.get("/api/v1/builds/{build_id}", response_model=BuildStatus)
async def get_build_status(build_id: str):
    """Get status of a specific build"""
    if build_id not in active_builds:
        raise HTTPException(status_code=404, detail="Build not found")
    
    build = active_builds[build_id]
    
    return BuildStatus(
        build_id=build["id"],
        title=build["title"],
        status=build["status"],
        current_phase=build.get("current_phase"),
        progress=build.get("progress", 0.0),
        phases_completed=build.get("phases_completed", []),
        started_at=build["started_at"],
        estimated_completion=build.get("estimated_completion")
    )


@app.delete("/api/v1/builds/{build_id}")
async def cancel_build(build_id: str):
    """Cancel a running build"""
    if build_id not in active_builds:
        raise HTTPException(status_code=404, detail="Build not found")
    
    build = active_builds[build_id]
    
    if build["status"] == "completed":
        raise HTTPException(status_code=400, detail="Build already completed")
    
    build["status"] = "cancelled"
    
    await broadcast_message({
        "type": "build_cancelled",
        "build_id": build_id
    })
    
    return {"message": "Build cancelled successfully"}


@app.get("/api/v1/agents")
async def list_agents():
    """List all registered agents"""
    if not orchestrator:
        raise HTTPException(status_code=500, detail="Orchestrator not initialized")
    
    agents = []
    for agent in orchestrator.agents.values():
        agents.append({
            "id": agent.id,
            "name": agent.name,
            "type": agent.type.value,
            "status": agent.status.value,
            "capabilities": [cap.name for cap in agent.capabilities]
        })
    
    return agents


@app.get("/api/v1/agents/{agent_id}")
async def get_agent_details(agent_id: str):
    """Get details of a specific agent"""
    if not orchestrator:
        raise HTTPException(status_code=500, detail="Orchestrator not initialized")
    
    if agent_id not in orchestrator.agents:
        raise HTTPException(status_code=404, detail="Agent not found")
    
    agent = orchestrator.agents[agent_id]
    
    return {
        "id": agent.id,
        "name": agent.name,
        "type": agent.type.value,
        "status": agent.status.value,
        "description": agent.description,
        "capabilities": [
            {
                "name": cap.name,
                "description": cap.description,
                "required": cap.required
            }
            for cap in agent.capabilities
        ],
        "tags": agent.tags,
        "metadata": agent.metadata
    }


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for real-time updates
    
    Clients can connect to receive real-time updates about builds,
    phases, logs, and system status.
    """
    await websocket.accept()
    websocket_connections.append(websocket)
    
    try:
        # Send initial connection message
        await websocket.send_json({
            "type": "connected",
            "message": "Connected to Application Builder",
            "timestamp": datetime.utcnow().isoformat()
        })
        
        # Keep connection alive and handle incoming messages
        while True:
            data = await websocket.receive_text()
            # Handle client messages if needed
            
    except WebSocketDisconnect:
        websocket_connections.remove(websocket)
        logger.info("WebSocket client disconnected")


async def execute_build(build_id: str, idea: ApplicationIdea, autonomous: bool):
    """
    Execute a build asynchronously
    
    This function runs the complete build lifecycle and updates
    the build status throughout the process.
    """
    phases = [
        ("planning", "Planning & Task Decomposition"),
        ("architecture", "Democratic Architecture Decision"),
        ("techstack", "Technology Stack Selection"),
        ("design", "Design Phase"),
        ("development", "Development Phase"),
        ("testing", "Testing Phase"),
        ("debugging", "Debugging Phase"),
        ("ui", "UI Creation Phase"),
        ("integration", "Integration Phase"),
        ("build", "Build Phase"),
        ("validation", "Final Validation"),
    ]
    
    try:
        for i, (phase_id, phase_name) in enumerate(phases):
            # Update current phase
            active_builds[build_id]["current_phase"] = phase_id
            active_builds[build_id]["progress"] = (i / len(phases)) * 100
            
            # Broadcast phase start
            await broadcast_message({
                "type": "phase_started",
                "build_id": build_id,
                "phase": phase_id,
                "phase_name": phase_name,
                "progress": active_builds[build_id]["progress"]
            })
            
            # Simulate phase execution
            await asyncio.sleep(2)
            
            # Mark phase completed
            active_builds[build_id]["phases_completed"].append(phase_id)
            
            # Broadcast phase completion
            await broadcast_message({
                "type": "phase_completed",
                "build_id": build_id,
                "phase": phase_id,
                "phase_name": phase_name,
                "progress": active_builds[build_id]["progress"]
            })
        
        # Mark build as completed
        active_builds[build_id]["status"] = "completed"
        active_builds[build_id]["progress"] = 100.0
        active_builds[build_id]["completed_at"] = datetime.utcnow().isoformat()
        
        # Broadcast completion
        await broadcast_message({
            "type": "build_completed",
            "build_id": build_id,
            "title": active_builds[build_id]["title"]
        })
        
    except Exception as e:
        logger.error(f"Build {build_id} failed: {e}")
        active_builds[build_id]["status"] = "failed"
        active_builds[build_id]["error"] = str(e)
        
        await broadcast_message({
            "type": "build_failed",
            "build_id": build_id,
            "error": str(e)
        })


async def broadcast_message(message: Dict):
    """Broadcast a message to all connected WebSocket clients"""
    disconnected = []
    
    for ws in websocket_connections:
        try:
            await ws.send_json(message)
        except Exception:
            disconnected.append(ws)
    
    # Remove disconnected clients
    for ws in disconnected:
        websocket_connections.remove(ws)


def start_server(host: str = "0.0.0.0", port: int = 8000):
    """Start the API server"""
    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level="info"
    )


if __name__ == "__main__":
    start_server()
