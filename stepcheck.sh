#!/bin/bash


for value in "$CPU_THRESHOLD" "$MEMORY_THRESHOLD" "$DISK_THRESHOLD"; do
    if ! [[ "$value" =~ ^[0-9]+$ ]] || (( value < 0 || value > 100 )); then
        echo "Invalid threshold: $value"
        exit 1
    fi
done

echo "All thresholds are valid."
