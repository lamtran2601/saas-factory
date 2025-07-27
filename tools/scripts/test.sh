#!/bin/bash

# SaaS Factory Test Runner Script
set -e

echo "🧪 Running SaaS Factory tests..."

# Function to run tests for a specific package
run_tests() {
    local package_name=$1
    local package_path=$2
    
    echo "🔍 Testing $package_name..."
    cd $package_path
    
    if [ -f "package.json" ] && grep -q '"test"' package.json; then
        bun run test
    else
        echo "   No tests found for $package_name"
    fi
    
    cd - > /dev/null
}

# Test all packages
echo "📦 Testing shared packages..."
run_tests "types" "packages/types"
run_tests "utils" "packages/utils"
run_tests "auth" "packages/auth"
run_tests "ui" "packages/ui"

echo ""
echo "🔧 Testing API..."
run_tests "api" "apps/api"

echo ""
echo "🌐 Testing Web..."
run_tests "web" "apps/web"

echo ""
echo "✅ All tests completed!"
