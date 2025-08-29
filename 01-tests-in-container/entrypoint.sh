#!/bin/bash

# Docker entrypoint script for QA tests
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Container environment setup
export DOCKER=true
export CI=true
export DISPLAY=:99

echo -e "${BLUE}🐳 Docker QA Test Container${NC}"
echo "==========================="
echo "Environment: Docker"
echo "Chrome: $(chromium --version 2>/dev/null || echo 'Not available')"
echo "Python: $(python --version)"
echo "Pytest: $(python -m pytest --version)"
echo ""

# Default report options for all test runs
REPORT_ARGS="--html=/app/reports/report.html --self-contained-html --junit-xml=/app/reports/junit.xml"

# Function to run tests with reports
run_docker_tests() {
    local test_type="$1"
    local pytest_args="$2"
    
    echo -e "${YELLOW}Running $test_type tests in Docker...${NC}"
    echo "Command: python -m pytest $pytest_args $REPORT_ARGS"
    
    # Create reports directory
    mkdir -p /app/reports
    
    if python -m pytest $pytest_args $REPORT_ARGS; then
        echo -e "${GREEN}✅ $test_type tests completed successfully!${NC}"
        echo "📊 Reports generated:"
        echo "  - HTML: /app/reports/report.html"
        echo "  - JUnit: /app/reports/junit.xml"
        return 0
    else
        echo -e "${RED}❌ $test_type tests failed!${NC}"
        echo "📊 Reports generated (with failures):"
        echo "  - HTML: /app/reports/report.html"
        echo "  - JUnit: /app/reports/junit.xml"
        return 1
    fi
}

# Get test mode from arguments
TEST_MODE="${1:-all}"

echo -e "Selected test mode: ${BLUE}$TEST_MODE${NC}"
echo ""

# Parse test mode and execute appropriate tests
case "$TEST_MODE" in
    "api")
        echo "🌐 Running API tests in Docker container"
        echo "Includes both local (mocked) and remote API tests"
        
        # First run local API tests (always work)
        run_docker_tests "Local API" "tests/test_api_local.py -v"
        
        # Then try remote API tests
        echo -e "\n${YELLOW}Attempting remote API tests...${NC}"
        if curl -s --max-time 5 https://httpbin.org/get > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Internet connection available in container${NC}"
            run_docker_tests "Remote API" "tests/test_api.py -v"
        else
            echo -e "${YELLOW}⚠️ No internet connection, running in offline mode${NC}"
            export OFFLINE_MODE=true
            run_docker_tests "API (Offline)" "tests/test_api.py -v"
        fi
        ;;
        
    "api-local")
        echo "🏠 Running local API tests only (no internet required)"
        run_docker_tests "Local API" "tests/test_api_local.py -v"
        ;;
        
    "ui")
        echo "🖥️ Running UI tests in Docker container"
        echo "Using headless Chrome in container environment"
        
        # Verify Chrome is available
        if command -v chromium &> /dev/null; then
            echo -e "${GREEN}✅ Chromium detected: $(chromium --version)${NC}"
            run_docker_tests "UI" "tests/test_ui.py -v"
        else
            echo -e "${RED}❌ Chrome/Chromium not available in container${NC}"
            echo "UI tests cannot run without a browser"
            exit 1
        fi
        ;;
        
    "smoke")
        echo "💨 Running smoke tests in Docker container"
        run_docker_tests "Smoke" "-m smoke -v"
        ;;
        
    "fast")
        echo "⚡ Running fast tests (local API only) in Docker"
        run_docker_tests "Fast" "tests/test_api_local.py -v --tb=short"
        ;;
        
    "all")
        echo "🚀 Running full test suite in Docker container"
        
        # Step 1: Local API tests (always work)
        echo -e "${BLUE}Step 1/3: Local API tests${NC}"
        run_docker_tests "Local API" "tests/test_api_local.py -v"
        
        # Step 2: Remote API tests (if internet available)
        echo -e "\n${BLUE}Step 2/3: Remote API tests${NC}"
        if curl -s --max-time 5 https://httpbin.org/get > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Internet connection available${NC}"
            run_docker_tests "Remote API" "tests/test_api.py -v"
        else
            echo -e "${YELLOW}⚠️ No internet connection, running API tests in offline mode${NC}"
            export OFFLINE_MODE=true
            run_docker_tests "API (Offline)" "tests/test_api.py -v"
        fi
        
        # Step 3: UI tests (if Chrome available)
        echo -e "\n${BLUE}Step 3/3: UI tests${NC}"
        if command -v chromium &> /dev/null; then
            echo -e "${GREEN}✅ Chromium detected, running UI tests${NC}"
            run_docker_tests "UI" "tests/test_ui.py -v" || echo -e "${YELLOW}⚠️ UI tests failed, but continuing...${NC}"
        else
            echo -e "${YELLOW}⚠️ Chrome not available, skipping UI tests${NC}"
        fi
        ;;
        
    "help"|"--help"|"-h")
        echo -e "${BLUE}Docker Test Container Usage${NC}"
        echo ""
        echo "Available test modes:"
        echo "  api         - Run API tests (local + remote if internet available)"
        echo "  api-local   - Run local API tests only (offline, with mocking)"
        echo "  ui          - Run UI tests (requires Chrome in container)"
        echo "  smoke       - Run smoke tests only"
        echo "  fast        - Run fast tests only (local API)"
        echo "  all         - Run full test suite (default)"
        echo "  help        - Show this help message"
        echo ""
        echo "Docker run examples:"
        echo "  docker run qa-tests api         # API tests only"
        echo "  docker run qa-tests ui          # UI tests only"
        echo "  docker run qa-tests all         # Full test suite"
        echo ""
        echo "With volume mount for reports:"
        echo "  docker run -v \$(pwd)/reports:/app/reports qa-tests api"
        echo ""
        exit 0
        ;;
        
    *)
        echo -e "${RED}❌ Unknown test mode: $TEST_MODE${NC}"
        echo "Available modes: api, api-local, ui, smoke, fast, all, help"
        echo "Use 'help' to see detailed usage information"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}🎉 Docker test execution completed!${NC}"
echo "📁 Reports are available in /app/reports/"

# List generated reports
if [ -d "/app/reports" ] && [ "$(ls -A /app/reports)" ]; then
    echo "📊 Generated files:"
    ls -la /app/reports/
else
    echo "⚠️ No reports generated"
fi
