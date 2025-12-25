#!/bin/bash

# Supabase Development Utilities
# Collection of useful commands for daily development

set -e

# Change to docker directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/../docker"
cd "$DOCKER_DIR"

show_help() {
    echo "🔧 Supabase Development Utilities"
    echo ""
    echo "Usage: ./dev-utils.sh <command>"
    echo ""
    echo "Commands:"
    echo "  status      - Show status of all services"
    echo "  logs        - Show logs for all services (follow mode)"
    echo "  logs <svc>  - Show logs for specific service"
    echo "  restart     - Restart all services"
    echo "  restart <svc> - Restart specific service"
    echo "  shell       - Open shell in database container"
    echo "  psql        - Connect to database with psql"
    echo "  backup      - Create database backup"
    echo "  restore     - Restore database from backup"
    echo "  clean       - Clean up Docker resources"
    echo "  update      - Pull latest images and restart"
    echo "  env         - Show environment configuration"
    echo ""
    echo "Services: db, auth, rest, realtime, storage, studio, kong, analytics"
}

check_env() {
    if [ ! -f ".env" ]; then
        echo "❌ .env file not found. Run ./setup.sh first."
        exit 1
    fi
    source .env
}

show_status() {
    echo "📊 Service Status:"
    docker compose ps
    echo ""
    echo "🔍 Service Health:"
    docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"
}

show_logs() {
    service=${1:-}
    if [ -n "$service" ]; then
        echo "📜 Showing logs for $service..."
        docker compose logs -f "$service"
    else
        echo "📜 Showing logs for all services..."
        docker compose logs -f
    fi
}

restart_services() {
    service=${1:-}
    if [ -n "$service" ]; then
        echo "🔄 Restarting $service..."
        docker compose restart "$service"
    else
        echo "🔄 Restarting all services..."
        docker compose restart
    fi
}

open_shell() {
    echo "🐚 Opening shell in database container..."
    docker compose exec db bash
}

connect_psql() {
    echo "🗃️  Connecting to PostgreSQL..."
    docker compose exec db psql -U postgres -d postgres
}

backup_db() {
    timestamp=$(date +"%Y%m%d_%H%M%S")
    backup_file="backup_${timestamp}.sql"
    
    echo "💾 Creating database backup: $backup_file"
    docker compose exec -T db pg_dump -U postgres -d postgres > "$backup_file"
    echo "✅ Backup created: $backup_file"
}

restore_db() {
    echo "📂 Available backup files:"
    ls -la backup_*.sql 2>/dev/null || echo "   No backup files found"
    echo ""
    read -p "Enter backup file name: " backup_file
    
    if [ ! -f "$backup_file" ]; then
        echo "❌ Backup file not found: $backup_file"
        exit 1
    fi
    
    echo "⚠️  This will replace all current data!"
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo "🔄 Restoring database from $backup_file..."
        docker compose exec -T db psql -U postgres -d postgres < "$backup_file"
        echo "✅ Database restored"
    else
        echo "❌ Restore cancelled"
    fi
}

clean_docker() {
    echo "🧹 Cleaning up Docker resources..."
    docker compose down
    docker system prune -f
    docker volume prune -f
    echo "✅ Cleanup complete"
}

update_services() {
    echo "📥 Updating to latest images..."
    docker compose down
    docker compose pull
    docker compose up -d
    echo "✅ Update complete"
}

show_env() {
    check_env
    echo "🔧 Environment Configuration:"
    echo ""
    echo "Database:"
    echo "  Host: $POSTGRES_HOST:$POSTGRES_PORT"
    echo "  Database: $POSTGRES_DB"
    echo ""
    echo "Dashboard:"
    echo "  URL: http://localhost:8000"
    echo "  Username: $DASHBOARD_USERNAME"
    echo ""
    echo "Studio:"
    echo "  URL: http://localhost:54323"
    echo ""
    echo "API:"
    echo "  URL: http://localhost:$KONG_HTTP_PORT"
    echo "  Anon Key: ${ANON_KEY:0:20}..."
    echo ""
}

# Main command handler
case "${1:-}" in
    "status")
        show_status
        ;;
    "logs")
        show_logs "${2:-}"
        ;;
    "restart")
        restart_services "${2:-}"
        ;;
    "shell")
        open_shell
        ;;
    "psql")
        connect_psql
        ;;
    "backup")
        backup_db
        ;;
    "restore")
        restore_db
        ;;
    "clean")
        clean_docker
        ;;
    "update")
        update_services
        ;;
    "env")
        show_env
        ;;
    "help"|"-h"|"--help"|"")
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac