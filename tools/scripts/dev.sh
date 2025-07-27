#!/bin/bash

# SaaS Factory Development Server Script
set -e

echo "🚀 Starting SaaS Factory development servers..."

# Function to kill background processes on exit
cleanup() {
    echo "🛑 Stopping development servers..."
    kill $(jobs -p) 2>/dev/null || true
    exit
}

# Set up cleanup on script exit
trap cleanup EXIT INT TERM

# Start API server
echo "🔧 Starting API server on http://localhost:8787..."
cd apps/api
bun run dev &
API_PID=$!
cd ../..

# Wait a moment for API to start
sleep 2

# Start Web server
echo "🌐 Starting Web server on http://localhost:3000..."
cd apps/web
bun run dev &
WEB_PID=$!
cd ../..

echo ""
echo "✅ Development servers started!"
echo "   API:  http://localhost:8787"
echo "   Web:  http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop all servers"

# Wait for background processes
wait
