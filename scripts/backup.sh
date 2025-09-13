#!/bin/bash

# Backup script for NetBox + Nautobot stack
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="netmgmt_backup_${DATE}"

echo -e "${GREEN}💾 Starting backup process...${NC}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo -e "${RED}❌ .env file not found. Please run 'make init' first.${NC}"
    exit 1
fi

# Create temporary directory for this backup
TEMP_DIR="/tmp/${BACKUP_NAME}"
mkdir -p "${TEMP_DIR}"

echo -e "${YELLOW}📊 Backing up PostgreSQL databases...${NC}"

# Backup NetBox database
echo "  - NetBox database..."
docker compose exec -T postgres pg_dump -U "${POSTGRES_USER}" netbox > "${TEMP_DIR}/netbox.sql"

# Backup Nautobot database
echo "  - Nautobot database..."
docker compose exec -T postgres pg_dump -U "${POSTGRES_USER}" nautobot > "${TEMP_DIR}/nautobot.sql"

echo -e "${YELLOW}📁 Backing up media files...${NC}"

# Backup NetBox media files
echo "  - NetBox media files..."
docker compose exec -T netbox tar -czf - -C /opt/netbox/netbox media > "${TEMP_DIR}/netbox-media.tar.gz"

# Backup Nautobot media files
echo "  - Nautobot media files..."
docker compose exec -T nautobot tar -czf - -C /opt/nautobot media > "${TEMP_DIR}/nautobot-media.tar.gz"

echo -e "${YELLOW}📋 Backing up configuration...${NC}"

# Backup configuration files
cp .env "${TEMP_DIR}/"
cp -r traefik "${TEMP_DIR}/"
cp -r env "${TEMP_DIR}/"

# Create final backup archive
echo -e "${YELLOW}📦 Creating backup archive...${NC}"
cd "${TEMP_DIR}"
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" .
cd - > /dev/null

# Clean up temporary directory
rm -rf "${TEMP_DIR}"

# Show backup information
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)
echo -e "${GREEN}✅ Backup completed successfully!${NC}"
echo -e "   📁 Backup file: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo -e "   📊 Size: ${BACKUP_SIZE}"
echo -e "   📅 Date: ${DATE}"

# Keep only last 10 backups
echo -e "${YELLOW}🧹 Cleaning up old backups (keeping last 10)...${NC}"
cd "${BACKUP_DIR}"
ls -t netmgmt_backup_*.tar.gz | tail -n +11 | xargs -r rm -f
cd - > /dev/null

echo -e "${GREEN}🎉 Backup process completed!${NC}"
