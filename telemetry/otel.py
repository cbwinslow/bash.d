#!/usr/bin/env python3
"""
OpenTelemetry Integration for bash.d
Provides distributed tracing, metrics, and observability.
"""

import os
import time
from datetime import datetime
from typing import Dict, Any, Optional
from opentelemetry import trace, metrics
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.resources import Resource
from opentelemetry.exporter.otlp.proto.grpc.trace.exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.metric.exporter import OTLPMetricExporter
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.trace import Status, StatusCode
from opentelemetry.instrumentation.system_metrics import SystemMetricsInstrumenter
from opentelemetry.instrumentation.process_instrumentation import ProcessInstrumentation

# Config
SERVICE_NAME = os.getenv("OTEL_SERVICE_NAME", "bash.d")
OTEL_ENDPOINT = os.getenv("OTEL_ENDPOINT", "http://localhost:4317")

class OpenTelemetrySetup:
    """OpenTelemetry setup and configuration."""
    
    def __init__(self, service_name: str = SERVICE_NAME):
        self.service_name = service_name
        self.resource = Resource.create({
            "service.name": service_name,
            "service.version": "1.0.0",
            "host.name": os.getenv("HOSTNAME", "localhost"),
        })
        self.tracer = None
        self.meter = None
        self._initialized = False
    
    def init_tracing(self, endpoint: str = OTEL_ENDPOINT):
        """Initialize tracing."""
        try:
            # Create tracer provider
            provider = TracerProvider(resource=self.resource)
            
            # Add OTLP exporter
            try:
                exporter = OTLPSpanExporter(endpoint=endpoint, insecure=True)
                processor = BatchSpanProcessor(exporter)
                provider.add_span_processor(processor)
            except Exception as e:
                print(f"OTLP export not available: {e}")
            
            trace.set_tracer_provider(provider)
            self.tracer = trace.get_tracer(__name__)
            self._initialized = True
            print(f"Tracing initialized for {self.service_name}")
        except Exception as e:
            print(f"Failed to initialize tracing: {e}")
    
    def init_metrics(self, endpoint: str = OTEL_ENDPOINT):
        """Initialize metrics."""
        try:
            # Create metric reader
            try:
                reader = PeriodicExportingMetricReader(
                    OTLPMetricExporter(endpoint=endpoint, insecure=True)
                )
            except Exception as e:
                print(f"OTLP metrics not available: {e}")
                reader = None
            
            # Create meter provider
            if reader:
                provider = MeterProvider(resource=self.resource, metric_readers=[reader])
            else:
                provider = MeterProvider(resource=self.resource)
            
            metrics.set_meter_provider(provider)
            self.meter = metrics.get_meter(__name__)
            print(f"Metrics initialized for {self.service_name}")
        except Exception as e:
            print(f"Failed to initialize metrics: {e}")
    
    def init_all(self, endpoint: str = OTEL_ENDPOINT):
        """Initialize all OpenTelemetry components."""
        self.init_tracing(endpoint)
        self.init_metrics(endpoint)
        
        # Auto-instrument system metrics
        try:
            SystemMetricsInstrumenter()
            print("System metrics instrumentation enabled")
        except Exception as e:
            print(f"System instrumentation not available: {e}")
        
        try:
            ProcessInstrumentation()
            print("Process instrumentation enabled")
        except Exception as e:
            print(f"Process instrumentation not available: {e}")
    
    def get_tracer(self):
        """Get tracer instance."""
        if not self.tracer:
            self.init_tracing()
        return self.tracer
    
    def get_meter(self):
        """Get meter instance."""
        if not self.meter:
            self.init_metrics()
        return self.meter


# Global instance
_otel = None

def get_otel() -> OpenTelemetrySetup:
    """Get global OpenTelemetry instance."""
    global _otel
    if _otel is None:
        _otel = OpenTelemetrySetup()
    return _otel


# ====================
# Decorators & Context Managers
# ====================

def trace_function(name: str = None):
    """Decorator to trace a function."""
    def decorator(func):
        def wrapper(*args, **kwargs):
            otel = get_otel()
            tracer = otel.get_tracer()
            span_name = name or func.__name__
            
            with tracer.start_as_current_span(span_name) as span:
                span.set_attribute("function.name", func.__name__)
                span.set_attribute("function.module", func.__module__)
                
                try:
                    result = func(*args, **kwargs)
                    span.set_status(Status(StatusCode.OK))
                    return result
                except Exception as e:
                    span.set_status(Status(StatusCode.ERROR, str(e)))
                    span.record_exception(e)
                    raise
        
        return wrapper
    return decorator


class TracingContext:
    """Context manager for manual tracing."""
    
    def __init__(self, name: str, attributes: Dict[str, Any] = None):
        self.name = name
        self.attributes = attributes or {}
        self.span = None
    
    def __enter__(self):
        otel = get_otel()
        tracer = otel.get_tracer()
        self.span = tracer.start_span(self.name)
        
        for key, value in self.attributes.items():
            self.span.set_attribute(key, value)
        
        return self.span
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            self.span.set_status(Status(StatusCode.ERROR, str(exc_val)))
            self.span.record_exception(exc_val)
        else:
            self.span.set_status(Status(StatusCode.OK))
        
        self.span.end()


# ====================
# Custom Metrics
# ====================

class BashDMetrics:
    """Custom metrics for bash.d."""
    
    def __init__(self):
        otel = get_otel()
        self.meter = otel.get_meter()
        self._init_metrics()
    
    def _init_metrics(self):
        """Initialize metrics."""
        # Counters
        self.script_runs = self.meter.create_counter(
            "bash.d.script.runs",
            description="Number of script executions"
        )
        
        self.agent_invocations = self.meter.create_counter(
            "bash.d.agent.invocations",
            description="Number of AI agent invocations"
        )
        
        self.errors = self.meter.create_counter(
            "bash.d.errors",
            description="Number of errors"
        )
        
        # Gauges
        self.active_processes = self.meter.create_up_down_counter(
            "bash.d.active_processes",
            description="Number of active processes"
        )
        
        self.memory_usage = self.meter.create_up_down_counter(
            "bash.d.memory.usage",
            description="Memory usage in bytes"
        )
        
        # Histograms
        self.script_duration = self.meter.create_histogram(
            "bash.d.script.duration",
            description="Script execution duration",
            unit="ms"
        )
        
        self.agent_latency = self.meter.create_histogram(
            "bash.d.agent.latency",
            description="Agent response latency",
            unit="ms"
        )
    
    def record_script_run(self, script_name: str, duration_ms: float):
        """Record a script execution."""
        self.script_runs.add(1, {"script.name": script_name})
        self.script_duration.record(duration_ms, {"script.name": script_name})
    
    def record_agent_invocation(self, agent_name: str, latency_ms: float):
        """Record an agent invocation."""
        self.agent_invocations.add(1, {"agent.name": agent_name})
        self.agent_latency.record(latency_ms, {"agent.name": agent_name})
    
    def record_error(self, error_type: str, component: str):
        """Record an error."""
        self.errors.add(1, {"error.type": error_type, "component": component})


# ====================
# CLI Interface
# ====================

def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(description="OpenTelemetry Integration")
    parser.add_argument("--init", action="store_true", help="Initialize OpenTelemetry")
    parser.add_argument("--status", action="store_true", help="Check status")
    parser.add_argument("--endpoint", default=OTEL_ENDPOINT, help="OTLP endpoint")
    
    args = parser.parse_args()
    
    if args.init:
        print(f"Initializing OpenTelemetry for {SERVICE_NAME}")
        otel = get_otel()
        otel.init_all(args.endpoint)
        print("OpenTelemetry initialized!")
    
    elif args.status:
        otel = get_otel()
        print(f"Service: {SERVICE_NAME}")
        print(f"Initialized: {otel._initialized}")
        print(f"Tracer: {otel.tracer is not None}")
        print(f"Meter: {otel.meter is not None}")
    
    else:
        print("Usage: otel.py --init")
        print("       otel.py --status")


if __name__ == "__main__":
    main()
