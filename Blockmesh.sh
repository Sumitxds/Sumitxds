#!/bin/bash

# Update and upgrade system packages
apt update && apt upgrade -y

# Clean up old files
rm -rf blockmesh-cli.tar.gz target

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# Install Docker Compose
DOCKER_COMPOSE_VERSION="1.29.2"
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || {
    echo "Error: Failed to download Docker Compose. Exiting..."
    exit 1
}
chmod +x /usr/local/bin/docker-compose

# Create a target directory for extraction
mkdir -p target/release

# Download and extract the latest BlockMesh CLI
echo "Downloading and extracting BlockMesh CLI..."
BLOCKMESH_CLI_URL="https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.420/block-mesh-manager-worker-x86_64-unknown-linux-gnu.tar.gz"
curl -L "$BLOCKMESH_CLI_URL" -o blockmesh-cli.tar.gz || {
    echo "Error: Failed to download BlockMesh CLI. Exiting..."
    exit 1
}
tar -xzf blockmesh-cli.tar.gz --strip-components=3 -C target/release || {
    echo "Error: Failed to extract BlockMesh CLI. Exiting..."
    exit 1
}

# Verify extraction results
if [[ ! -f target/release/blockmesh-cli ]]; then
    echo "Error: blockmesh-cli executable not found in target/release. Exiting..."
    exit 1
fi

# Prompt for email and password
read -p "Enter your BlockMesh email: " email
read -s -p "Enter your BlockMesh password: " password
echo

# Use BlockMesh CLI to create a Docker container
echo "Creating Docker container for BlockMesh CLI..."
docker run -it --rm \
    --name blockmesh-cli-container \
    -v "$(pwd)/target/release:/app" \
    -e EMAIL="$email" \
    -e PASSWORD="$password" \
    --workdir /app \
    ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password" || {
    echo "Error: Failed to run BlockMesh CLI container. Exiting..."
    exit 1
}
