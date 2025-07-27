#!/bin/bash

# SaaS Factory Build Script
set -e

echo "🏗️  Building SaaS Factory..."

# Function to build a specific package
build_package() {
    local package_name=$1
    local package_path=$2
    
    echo "📦 Building $package_name..."
    cd $package_path
    
    if [ -f "package.json" ] && grep -q '"build"' package.json; then
        bun run build
    else
        echo "   No build script found for $package_name"
    fi
    
    cd - > /dev/null
}

# Build shared packages first
echo "📦 Building shared packages..."
build_package "types" "packages/types"
build_package "utils" "packages/utils"
build_package "auth" "packages/auth"
build_package "ui" "packages/ui"
build_package "config" "packages/config"

echo ""
echo "🔧 Building API..."
build_package "api" "apps/api"

echo ""
echo "🌐 Building Web..."
build_package "web" "apps/web"

echo ""
echo "✅ Build completed!"
echo "   API build: apps/api/dist/"
echo "   Web build: apps/web/dist/"
