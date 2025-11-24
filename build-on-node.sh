#!/bin/bash
# Build Packer templates on specific Proxmox nodes
# Usage: ./build-on-node.sh <node> <template>
# Example: ./build-on-node.sh skull debian
# Example: ./build-on-node.sh hades ubuntu

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo "Usage: $0 <node> <template>"
    echo ""
    echo "Available nodes: skull, hades"
    echo "Available templates: debian, ubuntu, windows-server, windows-client, configured"
    echo ""
    echo "Examples:"
    echo "  $0 skull debian"
    echo "  $0 hades ubuntu"
    echo "  $0 skull configured"
    exit 1
fi

NODE=$1
TEMPLATE=$2

# Validate node
if [[ ! "$NODE" =~ ^(skull|hades)$ ]]; then
    echo -e "${RED}Error: Invalid node '$NODE'${NC}"
    echo "Valid nodes: skull, hades"
    exit 1
fi

# Validate template
if [[ ! "$TEMPLATE" =~ ^(debian|ubuntu|windows-server|windows-client|configured)$ ]]; then
    echo -e "${RED}Error: Invalid template '$TEMPLATE'${NC}"
    echo "Valid templates: debian, ubuntu, windows-server, windows-client, configured"
    exit 1
fi

# Set template file based on OS
case $TEMPLATE in
    debian|ubuntu|configured)
        TEMPLATE_DIR="linux"
        ;;
    windows-server|windows-client)
        TEMPLATE_DIR="windows"
        ;;
esac

VAR_FILE="${NODE}.pkrvars.hcl"
TEMPLATE_FILE="${TEMPLATE}.pkr.hcl"

echo -e "${GREEN}Building $TEMPLATE on node $NODE${NC}"
echo -e "${YELLOW}Template: $TEMPLATE_FILE${NC}"
echo -e "${YELLOW}Variables: $VAR_FILE${NC}"
echo ""

# Check if variable file exists
if [ ! -f "$VAR_FILE" ]; then
    echo -e "${RED}Error: Variable file $VAR_FILE not found${NC}"
    exit 1
fi

# Build the template
cd "templates/${TEMPLATE_DIR}"

echo -e "${GREEN}Initializing Packer...${NC}"
packer init "$TEMPLATE_FILE"

echo -e "${GREEN}Validating template...${NC}"
packer validate -var-file="$VAR_FILE" "$TEMPLATE_FILE"

echo -e "${GREEN}Building template...${NC}"
packer build -var-file="$VAR_FILE" "$TEMPLATE_FILE"

echo -e "${GREEN}✓ Build completed successfully!${NC}"
