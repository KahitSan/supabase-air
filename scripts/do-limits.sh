#!/bin/bash

# DigitalOcean Plan Benchmark Script
# Easily switch between different resource limits and run benchmarks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/../docker"
cd "$DOCKER_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Available plans
get_plan_info() {
  case "$1" in
    512mb) echo "512MB / 1 CPU (\$4/mo)" ;;
    1gb) echo "1GB / 1 CPU (\$6/mo)" ;;
    2gb) echo "2GB / 1 CPU (\$12/mo)" ;;
    2gb-2cpu) echo "2GB / 2 CPUs (\$18/mo)" ;;
    4gb) echo "4GB / 2 CPUs (\$24/mo)" ;;
    8gb) echo "8GB / 4 CPUs (\$48/mo)" ;;
    16gb) echo "16GB / 8 CPUs (\$96/mo)" ;;
    unlimited) echo "No Limits (Development)" ;;
    *) echo "" ;;
  esac
}

show_usage() {
  echo -e "${BLUE}DigitalOcean Plan Benchmark Tool${NC}"
  echo ""
  echo "Usage: $0 <command> [plan]"
  echo ""
  echo "Commands:"
  echo "  start <plan>     - Start services with specified plan limits"
  echo "  stop             - Stop all services"
  echo "  test <plan>      - Run full benchmark on specified plan"
  echo "  test-all         - Run benchmarks on all plans"
  echo "  stats            - Show current resource usage"
  echo "  list             - List available plans"
  echo "  setup             - Quick setup (same as 'start unlimited')"
  echo ""
  echo "Available plans:"
  echo "  512mb - $(get_plan_info 512mb)"
  echo "  1gb - $(get_plan_info 1gb)"
  echo "  2gb - $(get_plan_info 2gb)"
  echo "  2gb-2cpu - $(get_plan_info 2gb-2cpu)"
  echo "  4gb - $(get_plan_info 4gb)"
  echo "  8gb - $(get_plan_info 8gb)"
  echo "  16gb - $(get_plan_info 16gb)"
  echo "  unlimited - $(get_plan_info unlimited)"
  echo ""
  echo "Examples:"
  echo "  $0 start 4gb              # Start with 4GB plan limits"
  echo "  $0 start unlimited        # Start without limits"
  echo "  $0 setup                  # Quick setup without resource limits"
  echo "  $0 test 2gb               # Test 2GB plan"
  echo "  $0 test-all               # Benchmark all plans"
  echo "  $0 stats                  # Show resource usage"
}

start_plan() {
  local plan=$1

  if [ -z "$(get_plan_info "$plan")" ]; then
    echo -e "${RED}Error: Invalid plan '${plan}'${NC}"
    echo "Run './scripts/do-limits.sh list' to see available plans"
    exit 1
  fi

  echo -e "${BLUE}Starting Supabase with $(get_plan_info "$plan")${NC}"
  echo ""
  
  # Stop existing containers
  echo -e "${YELLOW}Stopping existing containers...${NC}"
  docker compose down > /dev/null 2>&1 || true
  
  # Define resource limits for each plan
  local mem_limit cpu_quota
  case "$plan" in
    512mb) 
      mem_limit="512M"
      cpu_quota="100%"  # 1 CPU = 100%
      ;;
    1gb)
      mem_limit="1G"
      cpu_quota="100%"
      ;;
    2gb)
      mem_limit="2G"
      cpu_quota="100%"
      ;;
    2gb-2cpu)
      mem_limit="2G"
      cpu_quota="200%"  # 2 CPUs = 200%
      ;;
    4gb)
      mem_limit="4G"
      cpu_quota="200%"
      ;;
    8gb)
      mem_limit="8G"
      cpu_quota="400%"  # 4 CPUs = 400%
      ;;
    16gb)
      mem_limit="16G"
      cpu_quota="800%"  # 8 CPUs = 800%
      ;;
    unlimited)
      mem_limit=""
      cpu_quota=""
      ;;
  esac

  # Helper: detect systemd
  has_systemd() {
    command -v systemctl >/dev/null 2>&1 && [ -d /etc/systemd/system ]
  }

  # Unlimited path
  if [ "$plan" == "unlimited" ]; then
    echo -e "${BLUE}Starting without resource limits...${NC}"
    docker compose up -d
  else
    # Prefer systemd slice on Linux
    if has_systemd; then
      echo -e "${BLUE}Starting with total limit: $mem_limit RAM, $cpu_quota CPU...${NC}"
      echo -e "${YELLOW}Using systemd slice to enforce limits on entire stack${NC}"

        # Create parent supabase slice if it doesn't exist
      if ! systemctl is-active --quiet supabase.slice 2>/dev/null; then
        echo -e "${YELLOW}Creating parent supabase.slice...${NC}"
        sudo tee /etc/systemd/system/supabase.slice >/dev/null <<'EOF'
[Unit]
Description=Supabase Services Slice
Before=slices.target
Documentation=man:systemd.slice(7)

[Slice]
# No limits - parent slice for organization
EOF
        sudo systemctl daemon-reload
        sudo systemctl start supabase.slice
        echo -e "${GREEN}✓ Created supabase.slice${NC}"
      fi
    # Create a persistent systemd slice with resource limits
      local SLICE_NAME="supabase-limited"

    # Create slice unit file
      echo -e "${YELLOW}Creating ${SLICE_NAME}.slice...${NC}"
      sudo tee /etc/systemd/system/${SLICE_NAME}.slice >/dev/null <<EOF
[Unit]
Description=Supabase Resource Limited Slice ($mem_limit RAM, $cpu_quota CPU)
Before=slices.target
Documentation=man:systemd.slice(7)

[Slice]
MemoryMax=$mem_limit
CPUQuota=$cpu_quota
EOF

    # Reload systemd to recognize the new slice
      sudo systemctl daemon-reload
      sudo systemctl start ${SLICE_NAME}.slice

    # Start Docker Compose with the cgroup parent
      echo -e "${BLUE}Starting containers under ${SLICE_NAME}.slice...${NC}"

    # Create temporary compose file with cgroup_parent set
      TEMP_OVERRIDE=$(mktemp --suffix=.yml)
      cat > "$TEMP_OVERRIDE" << EOF_OVERRIDE
# Temporary override to set cgroup_parent for all services
services:
  studio:    
    cgroup_parent: ${SLICE_NAME}.slice 
  kong:      
    cgroup_parent: ${SLICE_NAME}.slice 
  auth:      
    cgroup_parent: ${SLICE_NAME}.slice 
  rest:      
    cgroup_parent: ${SLICE_NAME}.slice 
  storage:   
    cgroup_parent: ${SLICE_NAME}.slice 
  imgproxy:  
    cgroup_parent: ${SLICE_NAME}.slice 
  meta:      
    cgroup_parent: ${SLICE_NAME}.slice 
  supavisor: 
    cgroup_parent: ${SLICE_NAME}.slice 
  db:        
    cgroup_parent: ${SLICE_NAME}.slice 
EOF_OVERRIDE

      docker compose -f docker-compose.yml -f docker-compose.do-${plan}.yml -f "$TEMP_OVERRIDE" up -d
      rm -f "$TEMP_OVERRIDE"

      echo -e "${GREEN}✓ Containers running under resource-limited slice${NC}"

    else
      # macOS / no systemd fallback:
      echo -e "${YELLOW}Systemd not detected (likely macOS).${NC}"
      echo -e "${BLUE}Using Docker Compose plan overrides only.${NC}"
      echo -e "${YELLOW}Tip:${NC} Put per-service limits inside docker-compose.do-${plan}.yml"

      # Compose resource limits on non-Swarm are typically defined per-service
      # using supported fields (not the Swarm-only deploy section). :contentReference[oaicite:1]{index=1}
      docker compose \
        -f docker-compose.yml \
        -f docker-compose.do-${plan}.yml \
        up -d
    fi
  fi

  echo ""
  echo -e "${BLUE}Waiting for services to be healthy...${NC}"
  sleep 15

  echo ""
  echo -e "${GREEN}✓ Services started!${NC}"
  echo ""
  docker compose ps
  echo ""
  echo "Run './supabase.sh resources' to see resource usage"
}

stop_services() {
  echo -e "${BLUE}Stopping all services...${NC}"
  docker compose down

  # Clean up systemd slice if it exists
  if systemctl is-active --quiet supabase-limited.slice 2>/dev/null; then
    echo -e "${YELLOW}Cleaning up systemd slice...${NC}"
    sudo systemctl stop supabase-limited.slice 2>/dev/null || true
    sudo rm -f /etc/systemd/system/supabase-limited.slice 2>/dev/null || true
    sudo systemctl daemon-reload
  fi

  echo -e "${GREEN}✓ Services stopped${NC}"
}

show_stats() {
  echo -e "${BLUE}Current Resource Usage:${NC}"
  echo ""
  docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
  echo ""

  # Calculate totals
  TOTAL_MEM=$(docker stats --no-stream --format "{{.MemUsage}}" | awk '{print $1}' | sed 's/MiB//g' | awk '{sum+=$1} END {print sum}')
  TOTAL_CPU=$(docker stats --no-stream --format "{{.CPUPerc}}" | sed 's/%//g' | awk '{sum+=$1} END {print sum}')

  echo -e "${BLUE}Totals:${NC}"
  echo "  CPU: ${TOTAL_CPU}%"
  echo "  Memory: ${TOTAL_MEM} MiB ($(awk "BEGIN {printf \"%.2f\", $TOTAL_MEM/1024}") GiB)"

  # Show systemd limits if active
  if systemctl is-active --quiet supabase-limited.slice 2>/dev/null; then
    echo ""
    echo -e "${BLUE}Systemd Resource Limits (supabase-limited.slice):${NC}"
    MEM_MAX=$(systemctl show supabase-limited.slice -p MemoryMax --value)
    CPU_QUOTA=$(systemctl show supabase-limited.slice -p CPUQuotaPerSecUSec --value)

    # Convert memory to human readable
    if [ "$MEM_MAX" = "infinity" ]; then
      echo "  MemoryMax: unlimited"
    elif [ "$MEM_MAX" -lt 1073741824 ] 2>/dev/null; then
      MEM_DISPLAY="$(awk "BEGIN {printf \"%.0f\", $MEM_MAX/1048576}")M"
      echo "  MemoryMax: $MEM_DISPLAY"
    else
      MEM_DISPLAY="$(awk "BEGIN {printf \"%.1f\", $MEM_MAX/1073741824}")G"
      echo "  MemoryMax: $MEM_DISPLAY"
    fi

    # Parse CPU quota (format: "1s" = 100% of 1 CPU, "2s" = 200% = 2 CPUs)
    if [ "$CPU_QUOTA" != "infinity" ]; then
      # Extract number from format like "1s", "2s", etc.
      CPU_SECONDS=$(echo "$CPU_QUOTA" | sed 's/s$//')
      if [[ "$CPU_SECONDS" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        CPU_PERCENT=$(awk "BEGIN {printf \"%.0f\", $CPU_SECONDS * 100}")
        CPU_CORES=$(awk "BEGIN {printf \"%.1f\", $CPU_SECONDS}")
        echo "  CPUQuota: ${CPU_PERCENT}% (${CPU_CORES} CPUs)"
      else
        echo "  CPUQuota: $CPU_QUOTA"
      fi
    else
      echo "  CPUQuota: unlimited"
    fi
  fi
}

run_benchmark() {
  local plan=$1
  local output_file="/tmp/benchmark-${plan}.txt"

  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}Benchmarking: $(get_plan_info "$plan")${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""

  # Start services
  start_plan "$plan"

  # Wait for services to stabilize
  echo ""
  echo -e "${BLUE}Waiting 10s for services to stabilize...${NC}"
  sleep 10

  # Capture initial stats
  echo ""
  echo -e "${BLUE}📊 Initial Resource Usage:${NC}"
  show_stats | tee "${output_file}"

  # Run load test
  echo ""
  echo -e "${BLUE}🧪 Running load test...${NC}"
  "$SCRIPT_DIR/load-test.sh" 2>&1 | tee -a "${output_file}" || true

  # Capture final stats
  echo ""
  echo -e "${BLUE}📊 Final Resource Usage:${NC}"
  show_stats | tee -a "${output_file}"

  # Check health
  echo ""
  echo -e "${BLUE}🏥 Service Health:${NC}"
  docker compose ps | tee -a "${output_file}"

  echo ""
  echo -e "${GREEN}✓ Benchmark complete!${NC}"
  echo -e "${BLUE}Results saved to: ${output_file}${NC}"
  echo ""

  # Stop services
  stop_services

  return 0
}

run_all_benchmarks() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}Running Benchmarks on All Plans${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""

  local results_dir="/tmp/do-benchmarks-$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$results_dir"

  # Test each plan except unlimited
  for plan in 512mb 1gb 2gb 2gb-2cpu 4gb 8gb 16gb; do
    echo ""
    echo -e "${YELLOW}Testing $plan...${NC}"
    run_benchmark "$plan"

    # Move result file
    mv "/tmp/benchmark-${plan}.txt" "$results_dir/"

    # Brief pause between tests
    sleep 5
  done

  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}All Benchmarks Complete!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo -e "${BLUE}Results directory: ${results_dir}${NC}"
  echo ""

  # Generate summary
  echo -e "${BLUE}Generating summary...${NC}"
  generate_summary "$results_dir"
}

generate_summary() {
  local results_dir=$1
  local summary_file="${results_dir}/SUMMARY.md"

  cat > "$summary_file" << 'EOF'
# DigitalOcean Plan Benchmark Summary

Generated: $(date)

## Test Results

EOF

  for plan in 512mb 1gb 2gb 2gb-2cpu 4gb 8gb 16gb; do
    echo "### $plan - $(get_plan_info "$plan")" >> "$summary_file"
    echo "" >> "$summary_file"
    echo '```' >> "$summary_file"
    grep -A 10 "Initial Resource Usage:" "${results_dir}/benchmark-${plan}.txt" | head -15 >> "$summary_file" || echo "No data" >> "$summary_file"
    echo '```' >> "$summary_file"
    echo "" >> "$summary_file"
  done

  echo -e "${GREEN}✓ Summary generated: ${summary_file}${NC}"
}

list_plans() {
  echo -e "${BLUE}Available DigitalOcean Plans:${NC}"
  echo ""
  printf "%-15s %s\n" "Plan" "Specs"
  printf "%-15s %s\n" "----" "-----"
  for plan in 512mb 1gb 2gb 2gb-2cpu 4gb 8gb 16gb unlimited; do
    printf "%-15s %s\n" "$plan" "$(get_plan_info "$plan")"
  done
}

# Main script
case "${1:-}" in
  start)
    if [ -z "${2:-}" ]; then
      echo -e "${RED}Error: Plan name required${NC}"
      show_usage
      exit 1
    fi
    start_plan "$2"
    ;;
  setup)
    start_plan "unlimited"
    ;;
  stop)
    stop_services
    ;;
  test)
    if [ -z "${2:-}" ]; then
      echo -e "${RED}Error: Plan name required${NC}"
      show_usage
      exit 1
    fi
    run_benchmark "$2"
    ;;
  test-all)
    run_all_benchmarks
    ;;
  stats)
    show_stats
    ;;
  list)
    list_plans
    ;;
  *)
    show_usage
    ;;
esac
