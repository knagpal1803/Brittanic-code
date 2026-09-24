#!/usr/bin/env python3
import hashlib
import os
from datetime import datetime

TARGET_FILE = "/etc/passwd"
LOG_FILE = "/var/log/passwd_monitor.log"
HASH_CACHE = "/var/local/.passwd_hash"


def calculate_sha256(file_path):
    """Calculates the SHA-256 hash of a file efficiently in chunks."""
    if not os.path.exists(file_path):
        return None
    
    sha256_hash = hashlib.sha256()
    try:
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()
    except Exception as e:
        log_change(f"ERROR: Could not read {file_path}. Details: {str(e)}")
        return None


def log_change(message):
    """Appends a formatted, timestamped record to the log file."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    try:
        with open(LOG_FILE, "a") as lf:
            lf.write(f"[{timestamp}] {message}\n")
    except PermissionError:
        # Graceful fallback printing to stderr if permissions fail
        import sys
        print(f"[{timestamp}] Permissions error writing to {LOG_FILE}: {message}", file=sys.stderr)


def main():
    if not os.path.exists(TARGET_FILE):
        log_change(f"ERROR: Monitored target {TARGET_FILE} does not exist.")
        return

    current_hash = calculate_sha256(TARGET_FILE)
    if not current_hash:
        return

    # If cache file does not exist, initialize monitoring
    if not os.path.exists(HASH_CACHE):
        try:
            # Ensure the tracking directory exists
            os.makedirs(os.path.dirname(HASH_CACHE), exist_ok=True)
            with open(HASH_CACHE, "w") as hf:
                hf.write(current_hash)
            log_change("Monitoring initialized. Baseline cryptographic hash stored.")
        except Exception as e:
            log_change(f"ERROR: Could not write cache file. Details: {str(e)}")
        return

    # Read the previous hash from the cache
    try:
        with open(HASH_CACHE, "r") as hf:
            previous_hash = hf.read().strip()
    except Exception as e:
        log_change(f"ERROR: Could not read cache file. Details: {str(e)}")
        return

    # Evaluate if modifications have occurred
    if current_hash != previous_hash:
        log_change(f"WARNING: Changes detected inside '{TARGET_FILE}'!")
        
        # Update the hash cache with the modified baseline
        try:
            with open(HASH_CACHE, "w") as hf:
                hf.write(current_hash)
        except Exception as e:
            log_change(f"ERROR: Failed updating cache baseline. Details: {str(e)}")


if __name__ == "__main__":
    main()
