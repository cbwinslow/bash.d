#!/usr/bin/env python3
"""
Database models for telemetry system.
Uses SQLAlchemy with asyncpg for PostgreSQL.
"""

import os
from datetime import datetime
from typing import Optional
from sqlalchemy import (
    Column, Integer, String, Float, DateTime, Text, JSON, Boolean,
    Index, ForeignKey
)
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.pool import NullPool

Base = declarative_base()


# ====================
# Database URL
# ====================

def get_database_url() -> str:
    """Get database URL from environment or config."""
    host = os.getenv("TELEMETRY_DB_HOST", "localhost")
    port = os.getenv("TELEMETRY_DB_PORT", "5432")
    user = os.getenv("TELEMETRY_DB_USER", "postgres")
    password = os.getenv("TELEMETRY_DB_PASSWORD", "postgres")
    database = os.getenv("TELEMETRY_DB_NAME", "telemetry")
    
    return f"postgresql+asyncpg://{user}:{password}@{host}:{port}/{database}"


# ====================
# Models
# ====================

class Conversation(Base):
    """AI conversation storage for training/evaluation."""
    __tablename__ = "conversations"
    
    id = Column(Integer, primary_key=True)
    tool = Column(String(50), nullable=False)  # cline, claude, cursor, etc.
    model = Column(String(100), nullable=True)  # qwen3:4b, llama3.2, etc.
    prompt = Column(Text, nullable=False)
    response = Column(Text, nullable=False)
    session_id = Column(String(100), nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
    metadata = Column(JSON, nullable=True)  # extra info
    
    # Indexes
    __table_args__ = (
        Index('idx_conversations_timestamp', 'timestamp'),
        Index('idx_conversations_tool', 'tool'),
    )


class HardwareMetric(Base):
    """Hardware telemetry metrics."""
    __tablename__ = "hardware_metrics"
    
    id = Column(Integer, primary_key=True)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    
    # CPU
    cpu_percent = Column(Float)
    cpu_count = Column(Integer)
    cpu_freq = Column(Float)  # MHz
    
    # Memory
    memory_total = Column(Float)  # GB
    memory_used = Column(Float)    # GB
    memory_percent = Column(Float)
    
    # Disk
    disk_total = Column(Float)    # GB
    disk_used = Column(Float)      # GB
    disk_percent = Column(Float)
    
    # Temperature (if available)
    temperature = Column(Float)    # Celsius
    
    # GPU (if available)
    gpu_percent = Column(Float)
    gpu_memory_used = Column(Float)
    gpu_memory_total = Column(Float)
    gpu_temperature = Column(Float)
    
    # Boot time
    boot_time = Column(DateTime)
    
    # Index
    __table_args__ = (
        Index('idx_hardware_timestamp', 'timestamp'),
    )


class NetworkMetric(Base):
    """Network traffic and connection metrics."""
    __tablename__ = "network_metrics"
    
    id = Column(Integer, primary_key=True)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    
    # Bandwidth (cumulative)
    bytes_sent = Column(Integer)
    bytes_recv = Column(Integer)
    
    # Packets
    packets_sent = Column(Integer)
    packets_recv = Column(Integer)
    
    # Errors
    errin = Column(Integer)
    errout = Column(Integer)
    dropin = Column(Integer)
    dropout = Column(Integer)
    
    # Connections
    tcp_connections = Column(Integer)
    udp_connections = Column(Integer)
    established_connections = Column(Integer)
    
    # Per-interface breakdown stored as JSON
    interfaces = Column(JSON)
    
    __table_args__ = (
        Index('idx_network_timestamp', 'timestamp'),
    )


class SystemEvent(Base):
    """System events - errors, warnings, important events."""
    __tablename__ = "system_events"
    
    id = Column(Integer, primary_key=True)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    event_type = Column(String(50), nullable=False)  # error, warning, info, critical
    severity = Column(String(20), nullable=False)   # low, medium, high, critical
    source = Column(String(100), nullable=False)    # cpu, memory, disk, network, etc.
    message = Column(Text, nullable=False)
    details = Column(JSON, nullable=True)
    
    __table_args__ = (
        Index('idx_events_timestamp', 'timestamp'),
        Index('idx_events_severity', 'severity'),
    )


class NetworkConnection(Base):
    """Individual network connections snapshot."""
    __tablename__ = "network_connections"
    
    id = Column(Integer, primary_key=True)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    
    protocol = Column(String(10))  # TCP, UDP
    local_addr = Column(String(50))
    local_port = Column(Integer)
    remote_addr = Column(String(50))
    remote_port = Column(Integer)
    state = Column(String(20))  # ESTABLISHED, LISTEN, etc.
    pid = Column(Integer)
    
    __table_args__ = (
        Index('idx_connections_timestamp', 'timestamp'),
    )


class ProcessMetric(Base):
    """Per-process metrics for resource-heavy processes."""
    __tablename__ = "process_metrics"
    
    id = Column(Integer, primary_key=True)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    
    pid = Column(Integer)
    name = Column(String(200))
    username = Column(String(50))
    
    cpu_percent = Column(Float)
    memory_percent = Column(Float)
    memory_rss = Column(Integer)  # bytes
    num_threads = Column(Integer)
    status = Column(String(20))
    create_time = Column(Float)
    
    # I/O
    io_read_bytes = Column(Integer)
    io_write_bytes = Column(Integer)
    
    __table_args__ = (
        Index('idx_process_timestamp', 'timestamp'),
        Index('idx_process_name', 'name'),
    )


# ====================
# Database Functions
# ====================

async def create_tables(engine):
    """Create all tables."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def drop_tables(engine):
    """Drop all tables."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


async def get_session() -> AsyncSession:
    """Get async database session."""
    engine = create_async_engine(
        get_database_url(),
        poolclass=NullPool,
        echo=False
    )
    async with AsyncSession(engine) as session:
        yield session


async def init_db():
    """Initialize database - create tables."""
    engine = create_async_engine(
        get_database_url(),
        echo=True
    )
    
    await create_tables(engine)
    print("Database tables created!")
    
    await engine.dispose()


# ====================
# CRUD Operations
# ====================

async def save_hardware_metric(session, data: dict):
    """Save hardware metric."""
    metric = HardwareMetric(**data)
    session.add(metric)
    await session.commit()
    return metric


async def save_network_metric(session, data: dict):
    """Save network metric."""
    metric = NetworkMetric(**data)
    session.add(metric)
    await session.commit()
    return metric


async def save_conversation(session, tool: str, prompt: str, response: str, 
                          model: str = None, session_id: str = None,
                          metadata: dict = None):
    """Save AI conversation."""
    conv = Conversation(
        tool=tool,
        model=model,
        prompt=prompt,
        response=response,
        session_id=session_id,
        metadata=metadata
    )
    session.add(conv)
    await session.commit()
    return conv


async def save_system_event(session, event_type: str, severity: str,
                            source: str, message: str, details: dict = None):
    """Save system event."""
    event = SystemEvent(
        event_type=event_type,
        severity=severity,
        source=source,
        message=message,
        details=details
    )
    session.add(event)
    await session.commit()
    return event


if __name__ == "__main__":
    import asyncio
    asyncio.run(init_db())
