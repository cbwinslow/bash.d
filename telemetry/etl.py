#!/usr/bin/env python3
"""
ETL Pipeline for Data Processing
Extracts data from various sources, transforms, and loads into databases.
"""

import os
import json
import time
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, field
import subprocess
import asyncio

# Database imports
import psycopg2
from psycopg2.extras import RealDictCursor

# Config
TELEMETRY_DB = os.getenv("TELEMETRY_DB", "postgresql://cbwinslow:password@localhost:5433/telemetry")

@dataclass
class ETLConfig:
    """ETL Pipeline Configuration."""
    source: str
    destination: str
    interval: int = 60  # seconds
    batch_size: int = 100
    enabled: bool = True

@dataclass
class PipelineStats:
    """Statistics for ETL run."""
    pipeline_name: str
    start_time: datetime
    end_time: Optional[datetime] = None
    records_extracted: int = 0
    records_transformed: int = 0
    records_loaded: int = 0
    errors: List[str] = field(default_factory=list)
    
    def duration(self) -> float:
        if self.end_time:
            return (self.end_time - self.start_time).total_seconds()
        return 0

class BaseExtractor:
    """Base class for data extractors."""
    
    def __init__(self, config: ETLConfig):
        self.config = config
        self.stats = PipelineStats(pipeline_name=config.source, start_time=datetime.utcnow())
    
    def extract(self) -> List[Dict]:
        """Extract data from source."""
        raise NotImplementedError
    
    def get_stats(self) -> PipelineStats:
        return self.stats

class BaseTransformer:
    """Base class for data transformers."""
    
    def transform(self, data: List[Dict]) -> List[Dict]:
        """Transform data."""
        return data

class BaseLoader:
    """Base class for data loaders."""
    
    def __init__(self, connection_string: str):
        self.connection_string = connection_string
    
    def load(self, data: List[Dict], table: str) -> int:
        """Load data into destination."""
        raise NotImplementedError

# ====================
# Extractors
# ====================

class SystemMetricsExtractor(BaseExtractor):
    """Extract system metrics from psutil."""
    
    def extract(self) -> List[Dict]:
        try:
            import psutil
            import GPUtil
            
            # CPU metrics
            cpu_percent = psutil.cpu_percent(interval=1)
            cpu_count = psutil.cpu_count()
            
            # Memory metrics
            mem = psutil.virtual_memory()
            
            # Disk metrics
            disk = psutil.disk_usage('/')
            
            # Network metrics
            net = psutil.net_io_counters()
            
            # GPU metrics (if available)
            gpu_data = {}
            try:
                gpus = GPUtil.getGPUs()
                if gpus:
                    gpu = gpus[0]
                    gpu_data = {
                        'gpu_percent': gpu.load * 100,
                        'gpu_memory_used': gpu.memoryUsed,
                        'gpu_memory_total': gpu.memoryTotal,
                        'gpu_temperature': gpu.temperature
                    }
            except:
                pass
            
            # Boot time
            boot_time = datetime.fromtimestamp(psutil.boot_time())
            
            record = {
                'timestamp': datetime.utcnow(),
                'cpu_percent': cpu_percent,
                'cpu_count': cpu_count,
                'memory_total': mem.total / (1024**3),  # GB
                'memory_used': mem.used / (1024**3),
                'memory_percent': mem.percent,
                'disk_total': disk.total / (1024**3),
                'disk_used': disk.used / (1024**3),
                'disk_percent': disk.percent,
                'bytes_sent': net.bytes_sent,
                'bytes_recv': net.bytes_recv,
                'boot_time': boot_time,
                **gpu_data
            }
            
            self.stats.records_extracted = 1
            return [record]
            
        except Exception as e:
            self.stats.errors.append(f"System metrics extraction error: {e}")
            return []

class DockerStatsExtractor(BaseExtractor):
    """Extract Docker container stats."""
    
    def extract(self) -> List[Dict]:
        try:
            result = subprocess.run(
                ["docker", "ps", "--format", "{{.Names}}|{{.Status}}|{{.Image}}"],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            containers = []
            for line in result.stdout.strip().split('\n'):
                if line:
                    parts = line.split('|')
                    containers.append({
                        'name': parts[0] if len(parts) > 0 else '',
                        'status': parts[1] if len(parts) > 1 else '',
                        'image': parts[2] if len(parts) > 2 else '',
                        'timestamp': datetime.utcnow()
                    })
            
            self.stats.records_extracted = len(containers)
            return containers
            
        except Exception as e:
            self.stats.errors.append(f"Docker stats error: {e}")
            return []

class ProcessExtractor(BaseExtractor):
    """Extract top processes by resource usage."""
    
    def extract(self) -> List[Dict]:
        try:
            import psutil
            
            processes = []
            for proc in psutil.process_iter(['pid', 'name', 'username', 'cpu_percent', 'memory_percent']):
                try:
                    pinfo = proc.info
                    if pinfo['cpu_percent'] and pinfo['cpu_percent'] > 0.1:
                        processes.append({
                            'timestamp': datetime.utcnow(),
                            'pid': pinfo['pid'],
                            'name': pinfo['name'],
                            'username': pinfo['username'],
                            'cpu_percent': pinfo['cpu_percent'],
                            'memory_percent': pinfo['memory_percent']
                        })
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    pass
            
            # Sort by CPU and get top 20
            processes.sort(key=lambda x: x.get('cpu_percent', 0), reverse=True)
            top_processes = processes[:20]
            
            self.stats.records_extracted = len(top_processes)
            return top_processes
            
        except Exception as e:
            self.stats.errors.append(f"Process extraction error: {e}")
            return []

class LogExtractor(BaseExtractor):
    """Extract recent log entries."""
    
    def __init__(self, config: ETLConfig, log_file: str = "/tmp/system_monitor.log"):
        super().__init__(config)
        self.log_file = log_file
        self.last_position = 0
    
    def extract(self) -> List[Dict]:
        try:
            if not os.path.exists(self.log_file):
                return []
            
            with open(self.log_file, 'r') as f:
                f.seek(self.last_position)
                lines = f.readlines()
                self.last_position = f.tell()
            
            records = []
            for line in lines:
                if line.strip():
                    records.append({
                        'timestamp': datetime.utcnow(),
                        'source': 'system_monitor',
                        'level': 'info',
                        'message': line.strip()
                    })
            
            self.stats.records_extracted = len(records)
            return records
            
        except Exception as e:
            self.stats.errors.append(f"Log extraction error: {e}")
            return []

# ====================
# Loaders
# ====================

class PostgresLoader(BaseLoader):
    """Load data into PostgreSQL."""
    
    def load(self, data: List[Dict], table: str) -> int:
        if not data:
            return 0
        
        try:
            conn = psycopg2.connect(self.connection_string)
            cur = conn.cursor()
            
            if table == 'hardware_metrics':
                for record in data:
                    cur.execute("""
                        INSERT INTO hardware_metrics 
                        (timestamp, cpu_percent, cpu_count, memory_total, memory_used, 
                         memory_percent, disk_total, disk_used, disk_percent, boot_time,
                         gpu_percent, gpu_memory_used, gpu_memory_total, gpu_temperature)
                        VALUES (%(timestamp)s, %(cpu_percent)s, %(cpu_count)s, %(memory_total)s,
                                %(memory_used)s, %(memory_percent)s, %(disk_total)s, %(disk_used)s,
                                %(disk_percent)s, %(boot_time)s, %(gpu_percent)s, %(gpu_memory_used)s,
                                %(gpu_memory_total)s, %(gpu_temperature)s)
                    """, record)
            
            elif table == 'process_metrics':
                for record in data:
                    cur.execute("""
                        INSERT INTO process_metrics
                        (timestamp, pid, name, username, cpu_percent, memory_percent)
                        VALUES (%(timestamp)s, %(pid)s, %(name)s, %(username)s, 
                                %(cpu_percent)s, %(memory_percent)s)
                    """, record)
            
            elif table == 'system_events':
                for record in data:
                    cur.execute("""
                        INSERT INTO system_events
                        (timestamp, event_type, severity, source, message)
                        VALUES (%(timestamp)s, %(event_type)s, %(severity)s, %(source)s, %(message)s)
                    """, record)
            
            conn.commit()
            cur.close()
            conn.close()
            
            return len(data)
            
        except Exception as e:
            print(f"Postgres load error: {e}")
            return 0

# ====================
# ETL Pipeline
# ====================

class ETLPipeline:
    """ETL Pipeline coordinator."""
    
    def __init__(self, name: str, extractor: BaseExtractor, transformer: BaseTransformer, 
                 loader: BaseLoader, table: str):
        self.name = name
        self.extractor = extractor
        self.transformer = transformer
        self.loader = loader
        self.table = table
        self.running = False
    
    async def run(self):
        """Run one ETL cycle."""
        print(f"Running ETL: {self.name}")
        
        # Extract
        raw_data = self.extractor.extract()
        
        # Transform
        transformed_data = self.transformer.transform(raw_data)
        
        # Load
        loaded = self.loader.load(transformed_data, self.table)
        
        stats = self.extractor.get_stats()
        stats.records_loaded = loaded
        stats.end_time = datetime.utcnow()
        
        print(f"  Extracted: {stats.records_extracted}, "
              f"Transformed: {stats.records_transformed}, "
              f"Loaded: {stats.loaded}, "
              f"Duration: {stats.duration():.2f}s")
        
        if stats.errors:
            print(f"  Errors: {stats.errors}")
        
        return stats

class PipelineRunner:
    """Manages multiple ETL pipelines."""
    
    def __init__(self):
        self.pipelines: List[ETLPipeline] = []
        self.running = False
    
    def add_pipeline(self, pipeline: ETLPipeline):
        """Add a pipeline."""
        self.pipelines.append(pipeline)
    
    async def run_all(self):
        """Run all pipelines once."""
        for pipeline in self.pipelines:
            if pipeline.running:
                await pipeline.run()
    
    async def run_continuous(self, interval: int = 60):
        """Run pipelines continuously."""
        self.running = True
        print(f"Starting ETL pipeline runner (interval: {interval}s)")
        print("Press Ctrl+C to stop")
        
        while self.running:
            try:
                await self.run_all()
                await asyncio.sleep(interval)
            except KeyboardInterrupt:
                print("\nStopping ETL runner...")
                self.running = False
                break
    
    def stop(self):
        """Stop the runner."""
        self.running = False


# ====================
# Main
# ====================

def create_default_pipelines() -> PipelineRunner:
    """Create default ETL pipelines."""
    runner = PipelineRunner()
    
    # System metrics pipeline
    sys_config = ETLConfig(source="system_metrics", destination="postgres")
    sys_extractor = SystemMetricsExtractor(sys_config)
    sys_transformer = BaseTransformer()
    sys_loader = PostgresLoader(TELEMETRY_DB)
    runner.add_pipeline(ETLPipeline("System Metrics", sys_extractor, sys_transformer, 
                                     sys_loader, "hardware_metrics"))
    
    # Process metrics pipeline
    proc_config = ETLConfig(source="processes", destination="postgres")
    proc_extractor = ProcessExtractor(proc_config)
    proc_transformer = BaseTransformer()
    runner.add_pipeline(ETLPipeline("Process Metrics", proc_extractor, proc_transformer,
                                     sys_loader, "process_metrics"))
    
    # Docker stats pipeline
    docker_config = ETLConfig(source="docker", destination="postgres")
    docker_extractor = DockerStatsExtractor(docker_config)
    runner.add_pipeline(ETLPipeline("Docker Stats", docker_extractor, BaseTransformer(),
                                     sys_loader, "system_events"))
    
    return runner

async def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(description="ETL Pipeline")
    parser.add_argument("--once", action="store_true", help="Run once instead of continuously")
    parser.add_argument("--interval", type=int, default=60, help="Run interval in seconds")
    
    args = parser.parse_args()
    
    runner = create_default_pipelines()
    
    if args.once:
        await runner.run_all()
    else:
        await runner.run_continuous(args.interval)

if __name__ == "__main__":
    asyncio.run(main())
