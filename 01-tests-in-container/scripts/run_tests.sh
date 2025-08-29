#!/bin/bash

# Test runner script with different modes
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 QA Test Runner${NC}"
echo "=================="

# Function to run tests with specific options
run_tests() {
    local test_type="$1"
    local pytest_args="$2"
    
    echo -e "\n${YELLOW}Running $test_type tests...${NC}"
    echo "Command: python -m pytest $pytest_args"
    
    if python -m pytest $pytest_args; then
        echo -e "${GREEN}✅ $test_type tests passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ $test_type tests failed!${NC}"
        return 1
    fi
}

# Parse arguments
case "${1:-all}" in
    "api")
        echo "🌐 Running API tests only (with internet connection check)"
        run_tests "API" "tests/test_api.py -v"
        ;;
        
    "api-local")
        echo "🏠 Running local API tests (no internet required)"
        run_tests "Local API" "tests/test_api_local.py -v"
        ;;
        
    "api-offline")
        echo "📡 Running API tests in offline mode"
        export OFFLINE_MODE=true
        run_tests "Offline API" "tests/test_api.py -v"
        ;;
        
    "ui")
        echo "🖥️ Running UI tests"
        run_tests "UI" "tests/test_ui.py -v" || echo -e "${YELLOW}⚠️ UI tests may fail without Chrome setup${NC}"
        ;;
        
    "smoke")
        echo "💨 Running smoke tests"
        run_tests "Smoke" "-m smoke -v"
        ;;
        
    "fast")
        echo "⚡ Running fast tests (API local only)"
        run_tests "Fast" "tests/test_api_local.py -v --tb=short"
        ;;
        
    "all")
        echo "🚀 Running all tests"
        
        # Run local tests first (always work)
        run_tests "Local API" "tests/test_api_local.py -v"
        
        # Try to run remote API tests
        echo -e "\n${YELLOW}Checking internet connectivity for remote API tests...${NC}"
        if curl -s --max-time 5 https://httpbin.org/get > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Internet connection available${NC}"
            run_tests "Remote API" "tests/test_api.py -v"
        else
            echo -e "${YELLOW}⚠️ No internet connection, skipping remote API tests${NC}"
            export OFFLINE_MODE=true
            run_tests "API (Offline)" "tests/test_api.py -v"
        fi
        
        # Try to run UI tests
        if command -v google-chrome &> /dev/null || command -v chromium &> /dev/null; then
            echo -e "\n${YELLOW}Chrome detected, attempting UI tests...${NC}"
            run_tests "UI" "tests/test_ui.py -v" || echo -e "${YELLOW}⚠️ UI tests failed - Chrome may not be properly configured${NC}"
        else
            echo -e "${YELLOW}⚠️ Chrome not detected, skipping UI tests${NC}"
        fi
        ;;
        
    "help"|"--help"|"-h")
        echo -e "\n${BLUE}Usage: ./run_tests.sh [mode]${NC}"
        echo ""
        echo "Available modes:"
        echo "  api         - Run API tests (requires internet)"
        echo "  api-local   - Run local API tests (offline, with mocking)"
        echo "  api-offline - Force API tests to run in offline mode"
        echo "  ui          - Run UI tests (requires Chrome)"
        echo "  smoke       - Run smoke tests only"
        echo "  fast        - Run fast tests only"
        echo "  all         - Run all applicable tests (default)"
        echo "  help        - Show this help message"
        echo ""
        echo "Examples:"
        echo "  ./run_tests.sh api-local    # Run only mocked API tests"
        echo "  ./run_tests.sh fast         # Quick test run"
        echo "  ./run_tests.sh all          # Full test suite"
        echo ""
        exit 0
        ;;
        
    *)
        echo -e "${RED}❌ Unknown test mode: $1${NC}"
        echo "Use './run_tests.sh help' to see available options"
        exit 1
        ;;
esac

echo -e "\n${GREEN}🎉 Test run completed!${NC}"
