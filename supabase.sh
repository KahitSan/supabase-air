#!/usr/bin/env bash
#
# Supabase Air - Unified CLI
# ===========================
#
# Manage Supabase services with a unified command-line interface.
#
# Usage:
#   ./supabase.sh start [--plan=<plan>]
#   ./supabase.sh stop
#   ./supabase.sh stats
#   ./supabase.sh status
#   ./supabase.sh logs [service]
#   ./supabase.sh reset
#   ./supabase.sh help
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
Supabase Air - Unified CLI

USAGE:
    ./supabase.sh <command> [options]

COMMANDS:
    start [--plan=<plan>]      Start Supabase services
                               If --plan not specified, shows interactive menu
    stop                       Stop all Supabase services
    status                     Show project status (URLs, credentials, keys)
                               Requires sudo authentication for security
    container-status           Show container health status
    resources                  Show resource usage statistics
    logs [service]             Show logs (all services or specific)
    reset [--hard]             Reset database (fast by default, ~1s)
                               --hard: Full reset (stops containers, slower)
    help                       Show this help message

START OPTIONS:
    --plan=<plan>          Resource limit plan to apply
                           Plans: unlimited, 512mb, 1gb, 2gb, 2gb-2cpu, 4gb, 8gb, 16gb

EXAMPLES:
    ./supabase.sh start                    # Interactive plan selection
    ./supabase.sh start --plan=unlimited   # Start without limits
    ./supabase.sh start --plan=4gb         # Start with 4GB plan
    ./supabase.sh stop                     # Stop services
    ./supabase.sh status                   # Show project info
    ./supabase.sh container-status         # Container health
    ./supabase.sh resources                # Resource usage
    ./supabase.sh reset                    # Fast reset (~1 second)
    ./supabase.sh reset --hard             # Full reset (slower)

For more information, see README.md

EOF
}

# Command: start
cmd_start() {
    local plan=""

    # Parse --plan= argument
    for arg in "$@"; do
        case $arg in
            --plan=*)
                plan="${arg#*=}"
                shift
                ;;
            *)
                print_error "Unknown argument: $arg"
                echo "Usage: ./supabase.sh start [--plan=<plan>]"
                exit 1
                ;;
        esac
    done

    print_header "Supabase Air - Start"

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
        print_info "Delegating to scripts/setup.sh..."
        "$SCRIPT_DIR/scripts/setup.sh"

        print_success "Setup complete!"
        echo ""
        print_info "Run ${BLUE}./supabase.sh start${NC} to start services."
        exit 0
    fi

    # Setup already complete, proceed with startup
    print_header "Starting Supabase Services"

    # Determine which plan to use
    if [ -z "$plan" ]; then
        # Show interactive menu
        plan=$(show_plan_menu)
        print_info "Selected plan: $plan"
    else
        # Validate plan argument
        case "$plan" in
            512mb|1gb|2gb|2gb-2cpu|4gb|8gb|16gb|unlimited)
                print_info "Using specified plan: $plan"
                ;;
            *)
                print_error "Invalid plan: $plan"
                print_info "Valid plans: 512mb, 1gb, 2gb, 2gb-2cpu, 4gb, 8gb, 16gb, unlimited"
                exit 1
                ;;
        esac
    fi

    # Delegate to do-limits.sh
    cd "$DOCKER_DIR"
    if [ "$plan" = "unlimited" ]; then
        print_info "Starting without resource limits..."
        ../scripts/do-limits.sh setup
    else
        print_info "Starting with $plan resource limits..."
        ../scripts/do-limits.sh start "$plan"
    fi

    echo ""
    print_success "Supabase services started successfully!"
    echo ""
    print_info "View project info: ${BLUE}./supabase.sh status${NC}"
    print_info "View containers: ${BLUE}./supabase.sh container-status${NC}"
    print_info "View resources: ${BLUE}./supabase.sh resources${NC}"
    print_info "Stop services: ${BLUE}./supabase.sh stop${NC}"
}

# Command: stop
cmd_stop() {
    print_header "Supabase Air - Stop"
    "$SCRIPT_DIR/scripts/do-limits.sh" stop
}

# Command: status (project info)
cmd_status() {
    # Require sudo authentication for viewing sensitive information
    print_info "Sudo access required to view sensitive credentials and API keys"
    if ! sudo -v; then
        print_error "Sudo authentication failed. Cannot display sensitive information."
        exit 1
    fi

    # Load environment variables
    if [ ! -f "$DOCKER_DIR/.env" ]; then
        print_error "No .env file found. Please start Supabase first."
        exit 1
    fi

    # Extract values from .env using grep
    local POSTGRES_PASSWORD=$(grep "^POSTGRES_PASSWORD=" "$DOCKER_DIR/.env" | cut -d'=' -f2-)
    local DASHBOARD_USERNAME=$(grep "^DASHBOARD_USERNAME=" "$DOCKER_DIR/.env" | cut -d'=' -f2-)
    local DASHBOARD_PASSWORD=$(grep "^DASHBOARD_PASSWORD=" "$DOCKER_DIR/.env" | cut -d'=' -f2-)
    local ANON_KEY=$(grep "^ANON_KEY=" "$DOCKER_DIR/.env" | cut -d'=' -f2-)
    local SERVICE_ROLE_KEY=$(grep "^SERVICE_ROLE_KEY=" "$DOCKER_DIR/.env" | cut -d'=' -f2-)

    print_header "Supabase Project Status"

    echo -e "${BLUE}🌐 Access URLs:${NC}"
    echo "  Dashboard:     http://localhost:8000"
    echo "  API URL:       http://localhost:8000"
    echo "  Database:      postgresql://postgres:${POSTGRES_PASSWORD}@localhost:54322/postgres"
    echo ""

    echo -e "${BLUE}🔐 Credentials:${NC}"
    echo "  Dashboard:     ${DASHBOARD_USERNAME} / ${DASHBOARD_PASSWORD}"
    echo "  Database:      postgres / ${POSTGRES_PASSWORD}"
    echo ""

    echo -e "${BLUE}🔑 API Keys:${NC}"
    echo "  Anon Key:      ${ANON_KEY}"
    echo "  Service Key:   ${SERVICE_ROLE_KEY}"
    echo ""

    echo -e "${BLUE}📡 Connection Info:${NC}"
    echo "  PostgreSQL:    localhost:54322"
    echo "  Kong Gateway:  localhost:8000"
    echo "  Pooler:        localhost:6543"
    echo ""

    echo -e "${BLUE}💡 Quick Tips:${NC}"
    echo "  View containers: ./supabase.sh container-status"
    echo "  View resources:  ./supabase.sh resources"
    echo "  View logs:       ./supabase.sh logs [service]"
}

# Command: container-status
cmd_container_status() {
    "$SCRIPT_DIR/scripts/dev-utils.sh" status
}

# Command: resources
cmd_resources() {
    "$SCRIPT_DIR/scripts/do-limits.sh" stats
}

# Command: logs
cmd_logs() {
    local service="${1:-}"
    if [ -n "$service" ]; then
        "$SCRIPT_DIR/scripts/dev-utils.sh" logs "$service"
    else
        "$SCRIPT_DIR/scripts/dev-utils.sh" logs
    fi
}

# Command: reset [--hard]
cmd_reset() {
    local hard_mode=false

    # Parse --hard argument
    for arg in "$@"; do
        case $arg in
            --hard)
                hard_mode=true
                ;;
            *)
                print_error "Unknown argument: $arg"
                echo "Usage: ./supabase.sh reset [--hard]"
                exit 1
                ;;
        esac
    done

    if [ "$hard_mode" = true ]; then
        print_header "Hard Resetting Environment"
        print_warning "This will stop all containers and delete all data. Are you sure? [y/N]: "
    else
        print_header "Resetting Database"
        print_warning "This will delete all data. Are you sure? [y/N]: "
    fi

    read -r confirmation
    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        print_info "Reset cancelled."
        exit 0
    fi

    local start_time=$(date +%s)

    if [ "$hard_mode" = true ]; then
        # Hard reset: stop containers and remove volumes
        print_info "Stopping and removing all containers and volumes..."
        cd "$DOCKER_DIR"
        docker compose down -v 2>/dev/null || true

        print_info "Clearing database data..."
        sudo rm -rf volumes/db/data 2>/dev/null || true
        sudo mkdir -p volumes/db/data 2>/dev/null || true
        sudo chown 105:106 volumes/db/data 2>/dev/null || true

        local end_time=$(date +%s)
        local elapsed=$((end_time - start_time))

        print_success "Hard reset complete in ${elapsed}s!"
        echo ""
        print_info "Run ${BLUE}./supabase.sh start${NC} when you're ready to set up and start again."
    else
        # Fast reset: keep containers running
        if ! docker ps --format '{{.Names}}' | grep -q "alpha-supabase-db"; then
            print_error "Database container is not running. Start Supabase first with ./supabase.sh start"
            exit 1
        fi

        print_info "Resetting database (fast mode - keeping containers running)..."

        # Drop and recreate public schema (removes all user tables)
        print_info "Dropping public schema..."
        docker exec alpha-supabase-db psql -U postgres -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO postgres; GRANT ALL ON SCHEMA public TO anon; GRANT ALL ON SCHEMA public TO authenticated; GRANT ALL ON SCHEMA public TO service_role;" 2>/dev/null

        # Truncate auth tables
        print_info "Clearing auth data..."
        docker exec alpha-supabase-db psql -U postgres -c "
            TRUNCATE auth.users CASCADE;
            TRUNCATE auth.sessions CASCADE;
            TRUNCATE auth.refresh_tokens CASCADE;
            TRUNCATE auth.mfa_factors CASCADE;
            TRUNCATE auth.mfa_challenges CASCADE;
            TRUNCATE auth.mfa_amr_claims CASCADE;
            TRUNCATE auth.flow_state CASCADE;
            TRUNCATE auth.one_time_tokens CASCADE;
            TRUNCATE auth.audit_log_entries CASCADE;
        " 2>/dev/null

        # Clear storage files
        print_info "Clearing storage files..."
        cd "$DOCKER_DIR"
        sudo rm -rf volumes/storage/* 2>/dev/null || true

        local end_time=$(date +%s)
        local elapsed=$((end_time - start_time))

        print_success "Reset complete in ${elapsed}s!"
        echo ""
        print_info "Database is ready. Run migrations with: cd pillar-api && bun run migrate:fresh && bun run seed"
    fi
}

# Main function
main() {
    local command="${1:-}"

    # Handle empty command or help
    if [ -z "$command" ] || [ "$command" = "help" ] || [ "$command" = "--help" ] || [ "$command" = "-h" ]; then
        show_help
        exit 0
    fi

    # Route to command handlers
    case "$command" in
        start)
            shift
            cmd_start "$@"
            ;;
        stop)
            cmd_stop
            ;;
        status)
            cmd_status
            ;;
        container-status)
            cmd_container_status
            ;;
        resources)
            cmd_resources
            ;;
        logs)
            shift
            cmd_logs "$@"
            ;;
        reset)
            shift
            cmd_reset "$@"
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            echo "Run './supabase.sh help' for usage information"
            exit 1
            ;;
    esac
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
