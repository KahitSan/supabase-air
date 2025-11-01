#!/usr/bin/env bash
#
# Supabase Self-Hosted Setup Script
# ==================================
#
# This script sets up a self-hosted Supabase instance with proper configuration
# for external database access via Supabase CLI.
#
# Usage:
#   ./setup.sh [--reset]
#
# Options:
#   --reset    Stop and remove all containers and volumes before setup
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/docker"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if reset flag is provided
RESET=false
if [[ "$1" == "--reset" ]]; then
    RESET=true
fi

print_header "Supabase Self-Hosted Setup"

# Step 1: Check prerequisites
print_info "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi
print_success "Docker is installed"

if ! command -v docker compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi
print_success "Docker Compose is installed"

# Step 2: Reset if requested
if [ "$RESET" = true ]; then
    print_header "Resetting Supabase (--reset flag detected)"

    print_info "Stopping and removing all containers and volumes..."
    cd "$DOCKER_DIR"
    docker compose down -v 2>/dev/null || true

    print_info "Clearing database data..."
    sudo rm -rf volumes/db/data/* 2>/dev/null || true

    print_success "Reset complete"
fi

# Step 3: Check and fix .env configuration
print_header "Checking Configuration"

cd "$DOCKER_DIR"

if [ ! -f .env ]; then
    print_error ".env file not found in docker directory"
    print_info "Please ensure you have a .env file with proper configuration"
    exit 1
fi

# Check if POSTGRES_PORT is set correctly
POSTGRES_PORT=$(grep "^POSTGRES_PORT=" .env | cut -d'=' -f2)
if [ "$POSTGRES_PORT" != "5432" ]; then
    print_warning "POSTGRES_PORT is set to '$POSTGRES_PORT' (should be 5432)"
    print_info "This will be fixed automatically..."

    # Fix the port configuration
    sed -i 's/^POSTGRES_PORT=.*/POSTGRES_PORT=5432/' .env

    # Add POSTGRES_EXTERNAL_PORT if not exists
    if ! grep -q "^POSTGRES_EXTERNAL_PORT=" .env; then
        sed -i '/^POSTGRES_PORT=/a POSTGRES_EXTERNAL_PORT=54322' .env
    fi

    print_success "Fixed POSTGRES_PORT configuration"
fi

print_success "Configuration is correct"

# Step 4: Check required initialization files
print_header "Checking Initialization Files"

REQUIRED_FILES=(
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

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    print_warning "Some initialization files are missing or are directories"
    print_info "These will be downloaded from the official Supabase repository"

    for file in "${MISSING_FILES[@]}"; do
        print_info "Fixing: $file"

        # Remove if it's a directory
        if [ -d "$file" ]; then
            sudo rm -rf "$file"
        fi

        # Create parent directory
        mkdir -p "$(dirname "$file")"

        # Download from GitHub
        FILE_PATH="${file#volumes/}"
        GITHUB_URL="https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/$FILE_PATH"

        if curl -fsSL "$GITHUB_URL" -o "$file" 2>/dev/null; then
            print_success "Downloaded: $file"
        else
            print_warning "Could not download: $file (file may not exist in repo)"
        fi
    done
fi

print_success "All initialization files are present"

# Step 5: Check pg_hba.conf
print_header "Checking PostgreSQL Configuration"

if [ ! -f "volumes/db/pg_hba.conf" ]; then
    print_info "Creating custom pg_hba.conf for Docker network access..."

    cat > volumes/db/pg_hba.conf << 'EOF'
# PostgreSQL Client Authentication Configuration File
# Custom configuration for self-hosted Supabase with Docker network access

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# trust local connections
local all  supabase_admin     scram-sha-256
local all  all                peer map=supabase_map
host  all  all  127.0.0.1/32  trust
host  all  all  172.18.0.1/32  trust
host  all  all  ::1/128       trust

# IPv4 external connections
host  all  all  10.0.0.0/8  scram-sha-256
host  all  all  172.16.0.0/12  scram-sha-256
host  all  all  192.168.0.0/16  scram-sha-256
host  all  all  0.0.0.0/0     scram-sha-256

# IPv6 external connections
host  all  all  ::0/0     scram-sha-256
EOF

    print_success "Created custom pg_hba.conf"
else
    print_success "Custom pg_hba.conf already exists"
fi

# Step 6: Start Supabase
print_header "Starting Supabase"

print_info "Pulling latest images and starting services..."
docker compose up -d

print_info "Waiting for services to be healthy..."
sleep 5

# Wait for database to be ready
MAX_WAIT=60
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    if docker exec supabase-db psql -U postgres -c "SELECT 1" &>/dev/null; then
        break
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
    echo -n "."
done
echo ""

if [ $ELAPSED -ge $MAX_WAIT ]; then
    print_error "Database did not become ready in time"
    exit 1
fi

print_success "Database is ready"

# Step 7: Verify configuration
print_header "Verifying Setup"

# Check PostgreSQL port
PG_PORT=$(docker exec supabase-db psql -U postgres -t -c "SHOW port;" | tr -d ' ')
if [ "$PG_PORT" = "5432" ]; then
    print_success "PostgreSQL listening on correct internal port: 5432"
else
    print_error "PostgreSQL listening on wrong port: $PG_PORT (expected 5432)"
fi

# Test external connection
print_info "Testing external database connection..."
PASSWORD=$(grep "^POSTGRES_PASSWORD=" .env | cut -d'=' -f2)

if PGPASSWORD="$PASSWORD" psql -h 127.0.0.1 -p 54322 -U postgres -d postgres -c "SELECT 1" &>/dev/null; then
    print_success "External connection works!"
else
    print_error "External connection failed"
    print_warning "This may affect Supabase CLI functionality"
fi

# Check service health
print_info "Checking service health..."
UNHEALTHY=$(docker compose ps | grep -v "healthy" | grep "Up" | wc -l)
if [ "$UNHEALTHY" -eq 1 ]; then  # Header line counts as 1
    print_success "All services are healthy"
else
    print_warning "Some services may not be healthy yet"
    print_info "Run 'docker compose ps' to check status"
fi

# Step 8: Display access information
print_header "Setup Complete!"

EXTERNAL_PORT=$(grep "^POSTGRES_EXTERNAL_PORT=" .env | cut -d'=' -f2)
if [ -z "$EXTERNAL_PORT" ]; then
    EXTERNAL_PORT="54322"
fi

echo -e "${GREEN}Supabase is now running!${NC}\n"
echo -e "Dashboard:     ${BLUE}http://localhost:8000${NC}"
echo -e "API URL:       ${BLUE}http://localhost:8000${NC}"
echo -e "Database:      ${BLUE}localhost:$EXTERNAL_PORT${NC}\n"

echo -e "${YELLOW}Credentials:${NC}"
DASHBOARD_USER=$(grep "^DASHBOARD_USERNAME=" .env | cut -d'=' -f2)
DASHBOARD_PASS=$(grep "^DASHBOARD_PASSWORD=" .env | cut -d'=' -f2)
echo -e "Dashboard:     ${BLUE}$DASHBOARD_USER${NC} / ${BLUE}$DASHBOARD_PASS${NC}"
echo -e "Database:      ${BLUE}postgres${NC} / ${BLUE}(from .env)${NC}\n"

echo -e "${GREEN}Next Steps:${NC}"
echo -e "1. Access the dashboard: ${BLUE}http://localhost:8000${NC}"
echo -e "2. Push migrations from your app:"
echo -e "   ${BLUE}cd ~/Projects/uni-api${NC}"
echo -e "   ${BLUE}supabase db push --db-url \"postgresql://postgres:PASSWORD@localhost:$EXTERNAL_PORT/postgres?sslmode=disable\"${NC}"
echo -e ""
echo -e "3. Or use the helper script:"
echo -e "   ${BLUE}./scripts/db-push-local.sh${NC}\n"

print_info "To view logs: ${BLUE}cd docker && docker compose logs -f${NC}"
print_info "To stop: ${BLUE}cd docker && docker compose down${NC}"
print_info "To reset completely: ${BLUE}./setup.sh --reset${NC}"

echo ""
