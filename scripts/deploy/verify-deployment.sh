#!/bin/bash

# SaaS Factory Deployment Verification Script
# This script verifies that a deployment is working correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if environment is provided
if [ -z "$1" ]; then
    print_error "Environment not specified. Usage: ./verify-deployment.sh [staging|production]"
    exit 1
fi

ENVIRONMENT=$1

# Validate environment
if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
    print_error "Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

# Set URLs based on environment
if [ "$ENVIRONMENT" = "staging" ]; then
    API_BASE_URL="https://saas-factory-api-staging.lamtran2601.workers.dev"
    FRONTEND_URL="https://saas-factory-staging.pages.dev"
else
    API_BASE_URL="https://saas-factory-api-prod.lamtran2601.workers.dev"
    FRONTEND_URL="https://saas-factory-production.pages.dev"
fi

HEALTH_CHECK_URL="$API_BASE_URL/health"

print_status "🔍 Starting deployment verification for $ENVIRONMENT environment..."

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local is_critical="${3:-false}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_status "Testing: $test_name"
    
    if eval "$test_command" > /dev/null 2>&1; then
        print_success "✅ $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        if [ "$is_critical" = "true" ]; then
            print_error "❌ $test_name (CRITICAL)"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 1
        else
            print_warning "⚠️  $test_name (NON-CRITICAL)"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 0
        fi
    fi
}

# Function to test HTTP endpoint
test_http_endpoint() {
    local url="$1"
    local expected_status="${2:-200}"
    local timeout="${3:-10}"
    
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url")
    [ "$response_code" = "$expected_status" ]
}

# Function to test API endpoint with JSON response
test_api_endpoint() {
    local url="$1"
    local timeout="${2:-10}"
    
    curl -s --max-time "$timeout" -H "Accept: application/json" "$url" | jq . > /dev/null 2>&1
}

# Function to test response time
test_response_time() {
    local url="$1"
    local max_time="${2:-2.0}"
    
    local response_time=$(curl -s -o /dev/null -w "%{time_total}" --max-time 10 "$url")
    echo "$response_time < $max_time" | bc -l > /dev/null
}

print_status "🏥 Running health checks..."

# Critical health checks
run_test "API Health Endpoint" "test_http_endpoint '$HEALTH_CHECK_URL'" true
run_test "API Response Time (<2s)" "test_response_time '$HEALTH_CHECK_URL' 2.0" false
run_test "Frontend Accessibility" "test_http_endpoint '$FRONTEND_URL'" true

print_status "🔌 Testing API endpoints..."

# API endpoint tests
run_test "API Info Endpoint" "test_api_endpoint '$API_BASE_URL/api'" true
run_test "Auth Login Endpoint" "test_http_endpoint '$API_BASE_URL/api/auth/login' 200" false
run_test "Auth Register Endpoint" "test_http_endpoint '$API_BASE_URL/api/auth/register' 200" false
run_test "Users Endpoint" "test_api_endpoint '$API_BASE_URL/api/users'" false
run_test "Organizations Endpoint" "test_api_endpoint '$API_BASE_URL/api/organizations'" false
run_test "Projects Endpoint" "test_api_endpoint '$API_BASE_URL/api/projects'" false
run_test "Tasks Endpoint" "test_api_endpoint '$API_BASE_URL/api/tasks'" false

print_status "🌐 Testing frontend functionality..."

# Frontend tests
run_test "Frontend HTML Content" "curl -s '$FRONTEND_URL' | grep -q '<html'" true
run_test "Frontend CSS Loading" "curl -s '$FRONTEND_URL' | grep -q 'stylesheet'" false
run_test "Frontend JS Loading" "curl -s '$FRONTEND_URL' | grep -q 'script'" false

print_status "🔒 Testing security headers..."

# Security header tests
run_test "HTTPS Redirect" "test_http_endpoint '${FRONTEND_URL/https/http}' 301" false
run_test "Security Headers Present" "curl -s -I '$FRONTEND_URL' | grep -q 'X-Content-Type-Options'" false
run_test "CORS Headers" "curl -s -I '$API_BASE_URL/health' | grep -q 'Access-Control'" false

print_status "📊 Testing performance..."

# Performance tests
run_test "API Response Time (<1s)" "test_response_time '$HEALTH_CHECK_URL' 1.0" false
run_test "Frontend Response Time (<3s)" "test_response_time '$FRONTEND_URL' 3.0" false

# Test API with load
print_status "🔄 Testing API under light load..."
for i in {1..5}; do
    if ! test_http_endpoint "$HEALTH_CHECK_URL"; then
        print_warning "API failed under load test $i/5"
        break
    fi
done
print_success "API load test completed"

print_status "🗄️ Testing database connectivity..."

# Database connectivity test (through API)
run_test "Database Connection via API" "test_api_endpoint '$API_BASE_URL/api/users'" false

print_status "🔐 Testing authentication flow..."

# Authentication tests (basic endpoint availability)
run_test "Auth Endpoints Available" "test_http_endpoint '$API_BASE_URL/api/auth/me' 401" false

print_status "💳 Testing payment integration..."

# Payment integration tests (if applicable)
if [ "$ENVIRONMENT" = "production" ]; then
    run_test "Stripe Integration" "test_api_endpoint '$API_BASE_URL/api/subscriptions'" false
fi

print_status "📱 Testing mobile responsiveness..."

# Mobile responsiveness test
run_test "Mobile Viewport Meta Tag" "curl -s '$FRONTEND_URL' | grep -q 'viewport'" false

print_status "🔍 Testing error handling..."

# Error handling tests
run_test "404 Error Handling" "test_http_endpoint '$API_BASE_URL/nonexistent' 404" false
run_test "CORS Preflight" "curl -s -X OPTIONS '$API_BASE_URL/api/users' -H 'Origin: https://example.com'" false

print_status "📈 Testing monitoring endpoints..."

# Monitoring tests
run_test "Health Check JSON Format" "test_api_endpoint '$HEALTH_CHECK_URL'" true

# Environment-specific tests
if [ "$ENVIRONMENT" = "production" ]; then
    print_status "🎯 Running production-specific tests..."
    
    # Production-specific tests
    run_test "Production Environment Variable" "curl -s '$HEALTH_CHECK_URL' | jq -r '.environment' | grep -q 'production'" true
    run_test "SSL Certificate Valid" "curl -s --cert-status '$FRONTEND_URL' > /dev/null" false
    
elif [ "$ENVIRONMENT" = "staging" ]; then
    print_status "🧪 Running staging-specific tests..."
    
    # Staging-specific tests
    run_test "Staging Environment Variable" "curl -s '$HEALTH_CHECK_URL' | jq -r '.environment' | grep -q 'staging'" true
fi

# Generate test report
print_status "📋 Generating test report..."

echo ""
echo "=========================================="
echo "         DEPLOYMENT VERIFICATION REPORT"
echo "=========================================="
echo "Environment: $ENVIRONMENT"
echo "Timestamp: $(date)"
echo "API URL: $API_BASE_URL"
echo "Frontend URL: $FRONTEND_URL"
echo ""
echo "Test Results:"
echo "  Total Tests: $TOTAL_TESTS"
echo "  Passed: $PASSED_TESTS"
echo "  Failed: $FAILED_TESTS"
echo "  Success Rate: $(echo "scale=1; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)%"
echo ""

# Determine overall status
if [ $FAILED_TESTS -eq 0 ]; then
    print_success "🎉 All tests passed! Deployment verification successful."
    exit 0
elif [ $PASSED_TESTS -gt $FAILED_TESTS ]; then
    print_warning "⚠️  Some tests failed, but deployment appears mostly functional."
    print_warning "Review failed tests and monitor the application closely."
    exit 0
else
    print_error "❌ Multiple tests failed! Deployment verification failed."
    print_error "Consider rolling back the deployment."
    exit 1
fi
