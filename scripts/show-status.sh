#!/bin/bash

# Change to docker directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/../docker"
cd "$DOCKER_DIR"

# Load environment variables (properly handle spaces)
while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ $key =~ ^#.*$ ]] && continue
    [[ -z $key ]] && continue
    # Remove quotes from value if present
    value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
    export "$key"="$value"
done < .env

# Get main version from Studio
STUDIO_VERSION=$(docker inspect supabase-studio --format '{{.Config.Image}}' | sed 's/supabase\/studio://')
echo "════════════════════════════════════════════════════════════════════════════════"
echo "                   SUPABASE DOCKER STATUS (${STUDIO_VERSION})"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

# Extract versions from docker images
echo "📦 Supabase Components & Versions:"
echo "─────────────────────────────────────────────────────────────────────────────"
echo "Studio:               $(docker inspect supabase-studio --format '{{.Config.Image}}' | sed 's/supabase\/studio://')"
echo "Auth (GoTrue):        $(docker inspect supabase-auth --format '{{.Config.Image}}' | sed 's/supabase\/gotrue://')"
echo "PostgREST:            $(docker inspect supabase-rest --format '{{.Config.Image}}' | sed 's/postgrest\/postgrest://')"
echo "Realtime:             $(docker inspect realtime-dev.supabase-realtime --format '{{.Config.Image}}' | sed 's/supabase\/realtime://')"
echo "Storage API:          $(docker inspect supabase-storage --format '{{.Config.Image}}' | sed 's/supabase\/storage-api://')"
echo "PostgreSQL:           $(docker inspect supabase-db --format '{{.Config.Image}}' | sed 's/supabase\/postgres://')"
echo "Kong:                 $(docker inspect supabase-kong --format '{{.Config.Image}}' | sed 's/kong://')"
echo "Analytics (Logflare): $(docker inspect supabase-analytics --format '{{.Config.Image}}' | sed 's/supabase\/logflare://')"
echo "Postgres Meta:        $(docker inspect supabase-meta --format '{{.Config.Image}}' | sed 's/supabase\/postgres-meta://')"
echo "Edge Runtime:         $(docker inspect supabase-edge-functions --format '{{.Config.Image}}' | sed 's/supabase\/edge-runtime://')"
echo "Supavisor (Pooler):   $(docker inspect supabase-pooler --format '{{.Config.Image}}' | sed 's/supabase\/supavisor://')"
echo "ImgProxy:             $(docker inspect supabase-imgproxy --format '{{.Config.Image}}' | sed 's/darthsim\/imgproxy://')"
echo "Vector:               $(docker inspect supabase-vector --format '{{.Config.Image}}' | sed 's/timberio\/vector://')"
echo ""
echo "🗓️  Release Info:"
echo "─────────────────────────────────────────────────────────────────────────────"
echo "Studio Release:       June 30, 2025 (${STUDIO_VERSION})"
echo "Deployment:           Docker Compose (Self-hosted)"
echo "Architecture:         $(uname -m)/$(docker version --format '{{.Server.Os}}')"
echo "Docker Version:       $(docker version --format '{{.Server.Version}}')"
echo "Colima Version:       $(colima version 2>/dev/null | head -1 | cut -d' ' -f3 || echo 'N/A')"
echo ""

# Check service status
echo "🚀 Services Status:"
echo "─────────────────────────────────────────────────────────────────────────────"
docker compose ps --format "table {{.Service}}\t{{.State}}\t{{.Status}}" | sed 's/SERVICE/Service/' | sed 's/STATE/State/' | sed 's/STATUS/Status/'
echo ""

# API URLs and Ports
echo "🌐 API URLs & Ports:"
echo "─────────────────────────────────────────────────────────────────────────────"
echo "API URL:              $API_EXTERNAL_URL"
echo "GraphQL URL:          $API_EXTERNAL_URL/graphql/v1"
echo "S3 Storage URL:       $API_EXTERNAL_URL/storage/v1/s3"
echo "Studio URL:           $API_EXTERNAL_URL (via Kong - requires auth)"
echo "Analytics URL:        http://localhost:4000"
echo ""
echo "Kong (API Gateway):   localhost:$KONG_HTTP_PORT (HTTP)"
echo "                      localhost:$KONG_HTTPS_PORT (HTTPS)"
echo "PostgreSQL DB:        localhost:$POSTGRES_PORT"
echo "Pooler Proxy:         localhost:$POOLER_PROXY_PORT_TRANSACTION"
echo ""

# Database Connection
echo "🗄️  Database:"
echo "─────────────────────────────────────────────────────────────────────────────"
echo "Host:                 localhost"
echo "Port:                 $POSTGRES_PORT"
echo "Database:             $POSTGRES_DB"
echo "User:                 postgres"
echo "Password:             [HIDDEN - check .env file]"
echo ""

# API Keys
echo "🔑 API Keys:"
echo "─────────────────────────────────────────────────────────────────────────────"
echo "Anon key:             $ANON_KEY"
echo ""
echo "Service_role key:     $SERVICE_ROLE_KEY"
echo ""

# Dashboard Credentials
echo "📊 Dashboard Access:"
echo "─────────────────────────────────────────────────────────────────────────────"
echo "Studio URL:           $API_EXTERNAL_URL"
echo "Username:             $DASHBOARD_USERNAME"
echo "Password:             [HIDDEN - check .env file]"
echo "Note:                 Dashboard accessible via Kong (port $KONG_HTTP_PORT) with basic auth"
echo ""

# Connection strings
echo "🔗 Connection Strings:"
echo "─────────────────────────────────────────────────────────────────────────────"
echo "PostgreSQL:           postgresql://postgres:[YOUR_PASSWORD]@localhost:$POSTGRES_PORT/$POSTGRES_DB"
echo "Connection Pool:      postgresql://postgres:[YOUR_PASSWORD]@localhost:$POOLER_PROXY_PORT_TRANSACTION/$POSTGRES_DB"
echo ""

# JWT Configuration
echo "🛡️  Authentication:"
echo "─────────────────────────────────────────────────────────────────────────────"
echo "JWT Secret:           [HIDDEN - check .env file]"
echo "JWT Expiry:           ${JWT_EXPIRY}s"
echo "Site URL:             $SITE_URL"
echo ""

echo "💡 Quick Commands:"
echo "─────────────────────────────────────────────────────────────────────────────"
echo "View logs:            docker compose logs -f [service_name]"
echo "Stop all:             docker compose down"
echo "Restart:              docker compose restart"
echo "Reset everything:     docker compose down -v --remove-orphans"
echo ""
