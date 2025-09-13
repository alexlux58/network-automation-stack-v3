#!/bin/bash

# First-run setup script for NetBox + Nautobot stack
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting first-run setup...${NC}"

# Check if .env exists, if not copy from .env.example
if [ ! -f .env ]; then
    echo -e "${YELLOW}📋 Creating .env from .env.example...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✅ .env file created. Please review and update as needed.${NC}"
else
    echo -e "${GREEN}✅ .env file already exists.${NC}"
fi

# Load environment variables
set -a
source .env
set +a

# Generate secret keys if they are still set to default values
if [ "$NETBOX_SECRET_KEY" = "to_be_generated" ]; then
    echo -e "${YELLOW}🔐 Generating NetBox secret key...${NC}"
    NETBOX_SECRET_KEY=$(openssl rand -hex 32)
    sed -i.bak "s/NETBOX_SECRET_KEY=to_be_generated/NETBOX_SECRET_KEY=$NETBOX_SECRET_KEY/" .env
    echo -e "${GREEN}✅ NetBox secret key generated.${NC}"
fi

if [ "$NAUTOBOT_SECRET_KEY" = "to_be_generated" ]; then
    echo -e "${YELLOW}🔐 Generating Nautobot secret key...${NC}"
    NAUTOBOT_SECRET_KEY=$(openssl rand -hex 32)
    sed -i.bak "s/NAUTOBOT_SECRET_KEY=to_be_generated/NAUTOBOT_SECRET_KEY=$NAUTOBOT_SECRET_KEY/" .env
    echo -e "${GREEN}✅ Nautobot secret key generated.${NC}"
fi

# Clean up backup files
rm -f .env.bak

# Check if Docker and Docker Compose are available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed or not in PATH${NC}"
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed or not in PATH${NC}"
    exit 1
fi

# Check if openssl is available
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}❌ OpenSSL is not installed or not in PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites are available.${NC}"

# Create necessary directories
echo -e "${YELLOW}📁 Creating necessary directories...${NC}"
mkdir -p traefik
mkdir -p env
mkdir -p scripts

echo -e "${GREEN}🎉 First-run setup completed successfully!${NC}"
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "   1. Review and update .env file if needed"
echo -e "   2. Run 'make up' to start the stack"
echo -e "   3. Add DNS entries for ${NETBOX_HOST} and ${NAUTOBOT_HOST} pointing to ${SERVER_IP}"
