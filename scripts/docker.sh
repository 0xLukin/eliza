#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 {build|run|start|bash}"
    exit 1
fi

# Execute the corresponding command based on the argument
case "$1" in
    build)
        docker build --platform linux/amd64 -t eliza .
        ;;
    run)
        # Ensure the container is not already running
        if [ "$(docker ps -q -f name=eliza)" ]; then
            echo "Container 'eliza' is already running. Stopping it first."
            docker stop eliza
            docker rm eliza
        fi

        # Define base directories to mount
        BASE_MOUNTS=(
            "characters:/app/characters"
            ".env:/app/.env"
            "agent:/app/agent"
            "docs:/app/docs"
            "scripts:/app/scripts"
        )

        # Define package directories to mount
        PACKAGES=(
            "adapter-postgres"
            "adapter-sqlite"
            "adapter-sqljs"
            "adapter-supabase"
            "client-auto"
            "client-direct"
            "client-discord"
            "client-telegram"
            "client-twitter"
            "core"
            "plugin-bootstrap"
            "plugin-image-generation"
            "plugin-node"
            "plugin-solana"
            "plugin-evm"
            "plugin-tee"
        )

        # Start building the docker run command
        CMD="docker run --platform linux/amd64 -p 8080:3000 -d"

        # Add base mounts
        for mount in "${BASE_MOUNTS[@]}"; do
            CMD="$CMD -v \"$(pwd)/$mount\""
        done

        # Add package mounts
        for package in "${PACKAGES[@]}"; do
            CMD="$CMD -v \"$(pwd)/packages/$package/src:/app/packages/$package/src\""
        done

        # Add core types mount separately (special case)
        CMD="$CMD -v \"$(pwd)/packages/core/types:/app/packages/core/types\""

        # Add container name and image and startup command
        CMD="$CMD --name eliza eliza /bin/bash -c 'cd /app && pnpm start --characters=\"characters/ai16zMemeGPT.character.json\"'"

        # Execute the command
        eval $CMD
        ;;
    start)
        docker start -a eliza
        ;;
    bash)
        # Check if the container is running before executing bash
        if [ "$(docker ps -q -f name=eliza)" ]; then
            docker exec -it eliza bash
        else
            echo "Container 'eliza' is not running. Please start it first."
            exit 1
        fi
        ;;
    *)
        echo "Invalid option: $1"
        echo "Usage: $0 {build|run|start|bash}"
        exit 1
        ;;
esac