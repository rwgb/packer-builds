#!/bin/bash
# Parallel Packer Build Script
# Builds templates simultaneously on multiple Proxmox nodes

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/templates/linux"
LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create logs directory
mkdir -p "$LOG_DIR"

echo -e "${GREEN}=== Parallel Packer Build ===${NC}"
echo -e "Timestamp: $TIMESTAMP"
echo -e "Template Directory: $TEMPLATE_DIR"
echo -e "Log Directory: $LOG_DIR\n"

# Function to build on a specific node
build_on_node() {
    local template=$1
    local node=$2
    local log_file="$LOG_DIR/${node}_${template}_${TIMESTAMP}.log"
    
    echo -e "${YELLOW}Starting build: $template on $node${NC}"
    
    (
        cd "$TEMPLATE_DIR"
        
        if /usr/local/bin/packer build -var-file="${node}.pkrvars.hcl" "${template}-${node}.pkr.hcl" > "$log_file" 2>&1; then
            echo -e "${GREEN}✓ Success: $template on $node${NC}"
            exit 0
        else
            echo -e "${RED}✗ Failed: $template on $node (see $log_file)${NC}"
            exit 1
        fi
    )
}

# Parse arguments or use defaults
TEMPLATE="${1:-ubuntu}"

# Start parallel builds
echo -e "${YELLOW}Launching parallel builds for $TEMPLATE...${NC}\n"

# Launch builds in background
build_on_node "$TEMPLATE" "skull" &
SKULL_PID=$!

build_on_node "$TEMPLATE" "hades" &
HADES_PID=$!

# Wait for both builds to complete
echo -e "${YELLOW}Waiting for builds to complete...${NC}\n"

SKULL_RESULT=0
HADES_RESULT=0

wait $SKULL_PID || SKULL_RESULT=$?
wait $HADES_PID || HADES_RESULT=$?

# Summary
echo -e "\n${GREEN}=== Build Summary ===${NC}"
if [ $SKULL_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ Skull: Success${NC}"
else
    echo -e "${RED}✗ Skull: Failed (exit code: $SKULL_RESULT)${NC}"
fi

if [ $HADES_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ Hades: Success${NC}"
else
    echo -e "${RED}✗ Hades: Failed (exit code: $HADES_RESULT)${NC}"
fi

# Exit with error if any build failed
if [ $SKULL_RESULT -ne 0 ] || [ $HADES_RESULT -ne 0 ]; then
    echo -e "\n${RED}One or more builds failed. Check logs in $LOG_DIR${NC}"
    exit 1
fi

echo -e "\n${GREEN}All builds completed successfully!${NC}"
exit 0
