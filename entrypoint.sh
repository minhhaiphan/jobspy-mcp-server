#!/bin/sh
set -e

echo "Checking if JobSpy Docker image exists..."

# Check if jobspy image exists
if ! docker images | grep -q "^jobspy "; then
    echo "JobSpy image not found. Building it now..."
    
    # Check if jobspy directory exists in the container
    if [ -d "/jobspy-build" ]; then
        echo "Building JobSpy image from /jobspy-build..."
        docker build -t jobspy /jobspy-build
        echo "JobSpy image built successfully!"
    else
        echo "ERROR: /jobspy-build directory not found in container"
        echo "Please build the JobSpy image manually on the host:"
        echo "  docker build -t jobspy ./jobspy"
        exit 1
    fi
else
    echo "JobSpy image already exists. Skipping build."
fi

echo "Starting JobSpy MCP Server..."
exec node src/index.js
