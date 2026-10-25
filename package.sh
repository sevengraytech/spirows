#!/bin/bash
# package.sh - Creates a complete deployment package for production (combined container)

set -euo pipefail

PACKAGE_NAME="evilginx-combined-deploy-$(date +%Y%m%d-%H%M%S)"
PACKAGE_DIR="/tmp/${PACKAGE_NAME}"

echo "=== Creating deployment package: ${PACKAGE_NAME} ==="

# Clean and create package directory
rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"

# Copy all project files
echo "Copying project files..."
rsync -av --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' --exclude='.venv' --exclude='venv' --exclude='*.log' \
    --exclude='logs/*' --exclude='config/evilginx/certs/*' \
    ./ "${PACKAGE_DIR}/"

# Ensure required directories exist
mkdir -p "${PACKAGE_DIR}/config/evilginx/phishlets"
mkdir -p "${PACKAGE_DIR}/config/evilginx/certs"
mkdir -p "${PACKAGE_DIR}/logs/evilginx"

# Create empty .gitkeep files for empty dirs
touch "${PACKAGE_DIR}/config/evilginx/certs/.gitkeep"
touch "${PACKAGE_DIR}/logs/evilginx/.gitkeep"

# Verify all required files
echo "Verifying package contents..."
REQUIRED_FILES=(
    "docker-compose.yml"
    "Dockerfile.combined"
    "ui_requirements.txt"
    "ui_config.py"
    "evilginx-entrypoint.sh"
    "supervisord.conf"
    ".env.example"
    "deploy.sh"
)

for f in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "${PACKAGE_DIR}/${f}" ]; then
        echo "ERROR: Missing ${f}"
        exit 1
    fi
    echo "  OK: ${f}"
done

# Check UI directory
UI_FILES=(
    "ui/app.py"
    "ui/ui_requirements.txt"
    "ui/ui_config.py"
    "ui/templates/base.html"
    "ui/templates/dashboard.html"
    "ui/templates/phishlets.html"
    "ui/templates/phishlet_detail.html"
    "ui/templates/logs.html"
    "ui/templates/login.html"
    "ui/static/css/style.css"
    "ui/static/js/app.js"
)

for f in "${UI_FILES[@]}"; do
    if [ ! -f "${PACKAGE_DIR}/${f}" ]; then
        echo "ERROR: Missing UI file ${f}"
        exit 1
    fi
    echo "  OK: ${f}"
done

# Check phishlets
PHISHLET_COUNT=$(ls -1 "${PACKAGE_DIR}/config/evilginx/phishlets/"*.yaml 2>/dev/null | wc -l)
echo "  OK: ${PHISHLET_COUNT} phishlets"

# Create tarball
echo "Creating tarball..."
cd /tmp
tar -czf "${PACKAGE_NAME}.tar.gz" "${PACKAGE_NAME}"

echo ""
echo "=== Package created: /tmp/${PACKAGE_NAME}.tar.gz ==="
echo ""
echo "To deploy on production server:"
echo "  scp /tmp/${PACKAGE_NAME}.tar.gz user@server:/tmp/"
echo "  ssh user@server 'tar -xzf /tmp/${PACKAGE_NAME}.tar.gz -C /var/www/html/ && cd /var/www/html/${PACKAGE_NAME} && ./deploy.sh'"
echo ""
echo "Package size: $(du -h /tmp/${PACKAGE_NAME}.tar.gz | cut -f1)"