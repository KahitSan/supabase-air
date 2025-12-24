#!/usr/bin/env bash
#
# Supabase Air - Unified Startup Script
# =====================================
#
# Intelligently starts Supabase services with automatic setup detection
# and optional resource limiting.
#
# Usage:
#   ./start.sh [plan]        # Start with optional resource plan
#   ./start.sh --reset       # Reset environment (deletes all data)
#   ./start.sh --help        # Show help
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/docker"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print functions
print_header() {
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if setup is needed
needs_setup() {
    local setup_needed=false
    local reasons=()

    # Check .env file
    if [ ! -f "$DOCKER_DIR/.env" ]; then
        setup_needed=true
        reasons+=(".env file missing")
    fi

    # Check pg_hba.conf
    if [ ! -f "$DOCKER_DIR/volumes/db/pg_hba.conf" ]; then
        setup_needed=true
        reasons+=("Custom pg_hba.conf missing")
    fi

    # Check required initialization files
    local required_files=(
        "volumes/db/_supabase.sql"
        "volumes/db/logs.sql"
        "volumes/db/realtime.sql"
        "volumes/db/roles.sql"
        "volumes/db/webhooks.sql"
        "volumes/db/jwt.sql"
        "volumes/db/pooler.sql"
        "volumes/pooler/pooler.exs"
        "volumes/api/kong.yml"
        "volumes/logs/vector.yml"
    )

    local missing_count=0
    cd "$DOCKER_DIR"
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            ((missing_count++))
        fi
    done
    cd "$SCRIPT_DIR"

    if [ $missing_count -gt 2 ]; then
        setup_needed=true
        reasons+=("$missing_count initialization files missing")
    fi

    # Report and return
    if [ "$setup_needed" = true ]; then
        print_warning "First-time setup required:"
        for reason in "${reasons[@]}"; do
            print_info "  - $reason"
        done
        return 0  # Needs setup
    else
        return 1  # Already set up
    fi
}

# Show interactive plan menu
show_plan_menu() {
    echo -e "${BLUE}Select Resource Limit Plan:${NC}\n" >&2

    echo "Development Plans:" >&2
    echo "  1) unlimited    - No limits (recommended for local dev)" >&2
    echo "" >&2
    echo "DigitalOcean Production Plans:" >&2
    echo "  2) 512mb        - 512MB / 1 CPU (\$4/mo) - Not viable" >&2
    echo "  3) 1gb          - 1GB / 1 CPU (\$6/mo) - Dev/test only" >&2
    echo "  4) 2gb          - 2GB / 1 CPU (\$12/mo) - Minimum production" >&2
    echo "  5) 2gb-2cpu     - 2GB / 2 CPUs (\$18/mo) - Better performance" >&2
    echo "  6) 4gb          - 4GB / 2 CPUs (\$24/mo) - Recommended ⭐" >&2
    echo "  7) 8gb          - 8GB / 4 CPUs (\$48/mo) - High traffic" >&2
    echo "  8) 16gb         - 16GB / 8 CPUs (\$96/mo) - Enterprise" >&2
    echo "" >&2

    while true; do
        read -p "Enter choice (1-8) [default: 1]: " choice
        choice=${choice:-1}

        case $choice in
            1) echo "unlimited"; return 0;;
            2) echo "512mb"; return 0;;
            3) echo "1gb"; return 0;;
            4) echo "2gb"; return 0;;
            5) echo "2gb-2cpu"; return 0;;
            6) echo "4gb"; return 0;;
            7) echo "8gb"; return 0;;
            8) echo "16gb"; return 0;;
            *) print_error "Invalid choice. Please enter 1-8." >&2;;
        esac
    done
}

# Show help message
show_help() {
    cat << EOF
Supabase Air - Unified Startup Script

USAGE:
    ./start.sh [plan]
    ./start.sh --reset
    ./start.sh --help

DESCRIPTION:
    Intelligently starts Supabase services. Automatically detects if first-time
    setup is needed and runs it. Supports optional resource limiting for
    testing different deployment configurations.

OPTIONS:
    [plan]      Optional. Resource limit plan to apply.
                If omitted, shows interactive menu.

    --reset     Reset environment (WARNING: deletes all data)
    --help      Show this help message

PLANS:
    unlimited   No resource limits (default for development)
    512mb       512MB / 1 CPU (\$4/mo DO plan)
    1gb         1GB / 1 CPU (\$6/mo DO plan)
    2gb         2GB / 1 CPU (\$12/mo DO plan)
    2gb-2cpu    2GB / 2 CPUs (\$18/mo DO plan)
    4gb         4GB / 2 CPUs (\$24/mo DO plan) - Recommended
    8gb         8GB / 4 CPUs (\$48/mo DO plan)
    16gb        16GB / 8 CPUs (\$96/mo DO plan)

EXAMPLES:
    ./start.sh                    # Interactive menu
    ./start.sh unlimited          # Start without limits
    ./start.sh 4gb               # Start with 4GB plan limits
    ./start.sh --reset           # Reset environment
    ./start.sh --help            # Show this help

For more information, see README.md and WORKFLOWS.md

EOF
}

# Main function
main() {
    print_header "Supabase Air - Unified Startup"

    # Parse arguments
    PLAN_ARG="${1:-}"

    # Handle --reset flag
    if [ "$PLAN_ARG" = "--reset" ]; then
        print_header "Resetting Environment"
        print_warning "Delegating to setup.sh --reset..."
        "$SCRIPT_DIR/setup.sh" --reset
        exit $?
    fi

    # Handle help
    if [ "$PLAN_ARG" = "--help" ] || [ "$PLAN_ARG" = "-h" ]; then
        show_help
        exit 0
    fi

    # Check prerequisites
    print_info "Checking prerequisites..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed."
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi

    if ! command -v docker compose &> /dev/null; then
        print_error "Docker Compose is not installed."
        exit 1
    fi

    print_success "Docker and Docker Compose are available"

    # Check if setup is needed
    if needs_setup; then
        print_header "Running First-Time Setup"
        print_info "Delegating to setup.sh..."
        "$SCRIPT_DIR/setup.sh"

        print_success "Setup complete!"
        echo ""
        print_info "You can now start services with resource limits if needed."
        print_info "Run: ${BLUE}./start.sh [plan]${NC} to start with specific resource limits"
        exit 0
    fi

    # Setup already complete, proceed with startup
    print_header "Starting Supabase Services"

    # Determine which plan to use
    local plan=""
    if [ -n "$PLAN_ARG" ]; then
        # Validate plan argument
        case "$PLAN_ARG" in
            512mb|1gb|2gb|2gb-2cpu|4gb|8gb|16gb|unlimited)
                plan="$PLAN_ARG"
                print_info "Using specified plan: $plan"
                ;;
            *)
                print_error "Invalid plan: $PLAN_ARG"
                print_info "Valid plans: 512mb, 1gb, 2gb, 2gb-2cpu, 4gb, 8gb, 16gb, unlimited"
                exit 1
                ;;
        esac
    else
        # Show interactive menu
        plan=$(show_plan_menu)
        print_info "Selected plan: $plan"
    fi

    # Delegate to do-limits.sh
    cd "$DOCKER_DIR"
    if [ "$plan" = "unlimited" ]; then
        print_info "Starting without resource limits..."
        ./do-limits.sh setup
    else
        print_info "Starting with $plan resource limits..."
        ./do-limits.sh start "$plan"
    fi

    echo ""
    print_success "Supabase services started successfully!"
    echo ""
    print_info "Access dashboard at: ${BLUE}http://localhost:8000${NC}"
    print_info "To view status: ${BLUE}cd docker && ./do-limits.sh stats${NC}"
    print_info "To stop: ${BLUE}cd docker && ./do-limits.sh stop${NC}"
}

# Error handling
handle_interrupt() {
    echo ""
    print_info "Cancelled by user."
    exit 0
}
trap handle_interrupt SIGINT

# Run main
main "$@"
