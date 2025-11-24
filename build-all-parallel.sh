#!/bin/bash
# Build All Templates in Parallel
# Builds Debian, Ubuntu, and Windows templates simultaneously on both nodes

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$LOG_DIR"

echo -e "${GREEN}=== Build All Templates (Parallel) ===${NC}"
echo -e "Timestamp: $TIMESTAMP\n"

# Array to track background processes
declare -a PIDS
declare -a NAMES

# Function to launch a build
launch_build() {
    local template=$1
    local node=$2
    local template_dir=$3
    local log_file="$LOG_DIR/${node}_${template}_${TIMESTAMP}.log"
    
    echo -e "${YELLOW}Launching: $template on $node${NC}"
    
    (
        cd "$template_dir"
        if /usr/local/bin/packer build -var-file="${node}.pkrvars.hcl" "${template}-${node}.pkr.hcl" > "$log_file" 2>&1; then
            echo -e "${GREEN}✓ $template on $node${NC}"
            exit 0
        else
            echo -e "${RED}✗ $template on $node${NC}"
            exit 1
        fi
    ) &
    
    PIDS+=($!)
    NAMES+=("${node}:${template}")
}

# Launch all builds
LINUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/templates/linux"
WINDOWS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/templates/windows"

# Ubuntu builds
launch_build "ubuntu" "skull" "$LINUX_DIR"
launch_build "ubuntu" "hades" "$LINUX_DIR"

# Debian builds (if you create debian-skull.pkr.hcl and debian-hades.pkr.hcl)
# launch_build "debian" "skull" "$LINUX_DIR"
# launch_build "debian" "hades" "$LINUX_DIR"

# Windows builds (if you create windows-skull.pkr.hcl and windows-hades.pkr.hcl)
# launch_build "windows-server" "skull" "$WINDOWS_DIR"
# launch_build "windows-server" "hades" "$WINDOWS_DIR"

# Wait for all builds
echo -e "\n${YELLOW}Waiting for all builds to complete...${NC}\n"

FAILED=0
for i in "${!PIDS[@]}"; do
    if wait "${PIDS[$i]}"; then
        echo -e "${GREEN}✓ ${NAMES[$i]} completed${NC}"
    else
        echo -e "${RED}✗ ${NAMES[$i]} failed${NC}"
        FAILED=$((FAILED + 1))
    fi
done

# Summary
echo -e "\n${GREEN}=== Final Summary ===${NC}"
TOTAL=${#PIDS[@]}
SUCCESS=$((TOTAL - FAILED))
echo -e "Total builds: $TOTAL"
echo -e "${GREEN}Successful: $SUCCESS${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
    echo -e "\nCheck logs in: $LOG_DIR"
    exit 1
fi

echo -e "\n${GREEN}All builds completed successfully!${NC}"
exit 0
