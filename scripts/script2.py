#!/usr/bin/env python3
import docker
import os
import sys
from datetime import datetime

# --- CONFIGURATION ---
TARGET_CONTAINER = "container_name"

PROM_FILE_PATH = "/var/lib/node_exporter/textfile_collector/docker_container_restarts.prom"
LOG_FILE = "/var/log/docker_monitor.log"

# --- METRIC LABELS CONFIGURATION ---
ENVIRONMENT = "production"  # e.g., production, staging, development
SERVICE_ROLE = "database"   # e.g., web, api, cache, database


def log_message(message):
    """Logs standard timestamped messages to a local log file."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    try:
        with open(LOG_FILE, "a") as lf:
            lf.write(f"[{timestamp}] {message}\n")
    except Exception as e:
        print(f"Failed to write to log file: {e}", file=sys.stderr)


def main():
    try:
        client = docker.from_env()
        container = client.containers.get(TARGET_CONTAINER)
    except docker.errors.NotFound:
        log_message(f"ERROR: Container '{TARGET_CONTAINER}' not found.")
        sys.exit(1)
    except docker.errors.DockerException as e:
        log_message(f"ERROR: Cannot connect to Docker daemon. Details: {e}")
        sys.exit(1)

    # Extract state parameters from the container inspection data
    container_name = container.name
    image_name = container.image.tags[0] if container.image.tags else "unknown"
    restart_count = container.attrs['State']['RestartCount']
    status = container.attrs['State']['Status']

    # --- PROMETHEUS METRIC GENERATION ---
    metric_name = "docker_container_restart_count_total"
    metric_help = "# HELP docker_container_restart_count_total Total number of restarts experienced by the docker container."
    metric_type = "# TYPE docker_container_restart_count_total counter"
    
    # Format labels cleanly into a key-value format
    labels = (
        f'container_name="{container_name}",'
        f'image="{image_name}",'
        f'env="{ENVIRONMENT}",'
        f'role="{SERVICE_ROLE}",'
        f'status="{status}"'
    )
    
    metric_line = f"{metric_name}{{{labels}}} {restart_count}"

    # Write to a temporary file first, then rename atomically to prevent Node Exporter from reading a partial file
    tmp_prom_file = f"{PROM_FILE_PATH}.tmp"
    try:
        os.makedirs(os.path.dirname(PROM_FILE_PATH), exist_ok=True)
        with open(tmp_prom_file, "w") as f:
            f.write(f"{metric_help}\n")
            f.write(f"{metric_type}\n")
            f.write(f"{metric_line}\n")
        
        os.replace(tmp_prom_file, PROM_FILE_PATH)
    except Exception as e:
        log_message(f"ERROR: Failed writing prometheus metric file: {e}")
        sys.exit(1)

    # Optional: Log to standard text file only if a restart event has registered
    if restart_count > 0:
        log_message(f"MONITOR: Container '{container_name}' reports {restart_count} restart(s). Current status: {status}")


if __name__ == "__main__":
    main()
