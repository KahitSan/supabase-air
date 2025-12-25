#!/bin/bash

# Load Test Script for DigitalOcean 1GB/1CPU Simulation
# Tests database performance under resource constraints

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}DigitalOcean 1GB/1CPU Load Test${NC}"
echo -e "${BLUE}===================================================${NC}"
echo ""

# Get database password
DB_PASSWORD=$(grep POSTGRES_PASSWORD .env | cut -d'=' -f2)

echo -e "${BLUE}📊 Test 1: Database Connection Test${NC}"
echo "Testing basic connectivity..."
docker exec supabase-db psql -U postgres -c "SELECT version();" > /dev/null 2>&1 && \
  echo -e "${GREEN}✓${NC} Database is accessible" || \
  echo -e "${RED}✗${NC} Database connection failed"

echo ""
echo -e "${BLUE}📊 Test 2: Create Test Table${NC}"
docker exec supabase-db psql -U postgres <<EOF
DROP TABLE IF EXISTS load_test;
CREATE TABLE load_test (
  id SERIAL PRIMARY KEY,
  data TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
EOF
echo -e "${GREEN}✓${NC} Test table created"

echo ""
echo -e "${BLUE}📊 Test 3: Insert Performance (1000 rows)${NC}"
START_TIME=$(date +%s)
docker exec supabase-db psql -U postgres <<EOF
DO \$\$
BEGIN
  FOR i IN 1..1000 LOOP
    INSERT INTO load_test (data) VALUES ('Test data row ' || i);
  END LOOP;
END \$\$;
EOF
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
if [ $DURATION -eq 0 ]; then DURATION=1; fi
if [ $DURATION -eq 0 ]; then DURATION=1; fi
echo -e "${GREEN}✓${NC} Inserted 1000 rows in ${DURATION}s"
echo "   Rate: $((1000 / DURATION)) rows/sec"

echo ""
echo -e "${BLUE}📊 Test 4: Query Performance${NC}"
START_TIME=$(date +%s)
for i in {1..100}; do
  docker exec supabase-db psql -U postgres -c "SELECT COUNT(*) FROM load_test WHERE id < 500;" > /dev/null 2>&1
done
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
if [ $DURATION -eq 0 ]; then DURATION=1; fi
if [ $DURATION -eq 0 ]; then DURATION=1; fi
echo -e "${GREEN}✓${NC} Executed 100 queries in ${DURATION}s"
echo "   Rate: $((100 / DURATION)) queries/sec"

echo ""
echo -e "${BLUE}📊 Test 5: Concurrent Connections${NC}"
echo "Testing with 10 concurrent connections..."
START_TIME=$(date +%s)
for i in {1..10}; do
  (docker exec supabase-db psql -U postgres -c "SELECT pg_sleep(1), * FROM load_test LIMIT 10;" > /dev/null 2>&1) &
done
wait
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
if [ $DURATION -eq 0 ]; then DURATION=1; fi
echo -e "${GREEN}✓${NC} Handled 10 concurrent connections in ${DURATION}s"

echo ""
echo -e "${BLUE}📊 Test 6: Memory Stress Test${NC}"
echo "Creating large result set..."
START_TIME=$(date +%s)
docker exec supabase-db psql -U postgres <<EOF
DO \$\$
BEGIN
  FOR i IN 1..5000 LOOP
    INSERT INTO load_test (data) VALUES (repeat('x', 1000));
  END LOOP;
END \$\$;
EOF
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
if [ $DURATION -eq 0 ]; then DURATION=1; fi
echo -e "${GREEN}✓${NC} Inserted 5000 large rows in ${DURATION}s"

echo ""
echo -e "${BLUE}📊 Test 7: Table Scan Performance${NC}"
START_TIME=$(date +%s)
docker exec supabase-db psql -U postgres -c "SELECT COUNT(*) FROM load_test;" > /dev/null 2>&1
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
if [ $DURATION -eq 0 ]; then DURATION=1; fi
ROW_COUNT=$(docker exec supabase-db psql -U postgres -t -c "SELECT COUNT(*) FROM load_test;" | xargs)
echo -e "${GREEN}✓${NC} Full table scan of ${ROW_COUNT} rows in ${DURATION}s"

echo ""
echo -e "${BLUE}📊 Test 8: Resource Usage${NC}"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep supabase

echo ""
echo -e "${BLUE}📊 Test 9: Database Size${NC}"
DB_SIZE=$(docker exec supabase-db psql -U postgres -t -c "SELECT pg_size_pretty(pg_database_size('postgres'));" | xargs)
echo "Database size: ${DB_SIZE}"

echo ""
echo -e "${BLUE}📊 Test 10: Cleanup${NC}"
docker exec supabase-db psql -U postgres -c "DROP TABLE load_test;" > /dev/null 2>&1
echo -e "${GREEN}✓${NC} Test table dropped"

echo ""
echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}Load Test Complete!${NC}"
echo -e "${BLUE}===================================================${NC}"
