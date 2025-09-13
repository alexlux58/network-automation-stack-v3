#!/bin/bash

# Restore script for NetBox + Nautobot stack
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="./backups"

# Check if backup date is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Please provide backup date.${NC}"
    echo "Usage: $0 <backup_date>"
    echo "Available backups:"
    ls -la "${BACKUP_DIR}"/*.tar.gz 2>/dev/null | awk '{print $9}' | sed 's/.*netmgmt_backup_//' | sed 's/\.tar\.gz$//' | sort -r
    exit 1
fi

BACKUP_DATE="$1"
BACKUP_FILE="${BACKUP_DIR}/netmgmt_backup_${BACKUP_DATE}.tar.gz"

# Check if backup file exists
if [ ! -f "${BACKUP_FILE}" ]; then
    echo -e "${RED}❌ Backup file not found: ${BACKUP_FILE}${NC}"
    echo "Available backups:"
    ls -la "${BACKUP_DIR}"/*.tar.gz 2>/dev/null | awk '{print $9}' | sed 's/.*netmgmt_backup_//' | sed 's/\.tar\.gz$//' | sort -r
    exit 1
fi

echo -e "${GREEN}📥 Starting restore process...${NC}"
echo -e "   📁 Backup file: ${BACKUP_FILE}"

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo -e "${RED}❌ .env file not found. Please run 'make init' first.${NC}"
    exit 1
fi

# Create temporary directory for restore
TEMP_DIR="/tmp/restore_${BACKUP_DATE}_$$"
mkdir -p "${TEMP_DIR}"

echo -e "${YELLOW}📦 Extracting backup...${NC}"
tar -xzf "${BACKUP_FILE}" -C "${TEMP_DIR}"

# Check if stack is running
if ! docker compose ps | grep -q "Up"; then
    echo -e "${YELLOW}⚠️  Stack is not running. Starting stack first...${NC}"
    docker compose up -d
    echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
    sleep 30
fi

echo -e "${YELLOW}📊 Restoring PostgreSQL databases...${NC}"

# Restore NetBox database
echo "  - NetBox database..."
docker compose exec -T postgres psql -U "${POSTGRES_USER}" -d netbox -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
docker compose exec -T postgres psql -U "${POSTGRES_USER}" -d netbox < "${TEMP_DIR}/netbox.sql"

# Restore Nautobot database
echo "  - Nautobot database..."
docker compose exec -T postgres psql -U "${POSTGRES_USER}" -d nautobot -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
docker compose exec -T postgres psql -U "${POSTGRES_USER}" -d nautobot < "${TEMP_DIR}/nautobot.sql"

echo -e "${YELLOW}📁 Restoring media files...${NC}"

# Restore NetBox media files
echo "  - NetBox media files..."
docker compose exec -T netbox rm -rf /opt/netbox/netbox/media/*
docker compose exec -T netbox tar -xzf - -C /opt/netbox/netbox < "${TEMP_DIR}/netbox-media.tar.gz"

# Restore Nautobot media files
echo "  - Nautobot media files..."
docker compose exec -T nautobot rm -rf /opt/nautobot/media/*
docker compose exec -T nautobot tar -xzf - -C /opt/nautobot < "${TEMP_DIR}/nautobot-media.tar.gz"

echo -e "${YELLOW}🔄 Restarting applications...${NC}"
docker compose restart netbox nautobot

# Clean up temporary directory
rm -rf "${TEMP_DIR}"

echo -e "${GREEN}✅ Restore completed successfully!${NC}"
echo -e "${YELLOW}📝 Note: You may need to run 'make nb-collectstatic' for NetBox static files.${NC}"

echo -e "${GREEN}🎉 Restore process completed!${NC}"
