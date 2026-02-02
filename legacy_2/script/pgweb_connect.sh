#!/bin/bash

# pgweb PostgreSQL Web UI Connection Script
# Supports both local development and Railway production environments

echo "🔗 PGWeb Connection Helper"
echo "=========================="

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo ""
    echo "❌ DATABASE_URL not set"
    echo ""
    echo "📝 For Local Development:"
    echo "   Set DATABASE_URL environment variable:"
    echo "   export DATABASE_URL='postgres://postgres:password@localhost:5432/reading_pro_development'"
    echo ""
    echo "   OR run with inline:"
    echo "   DATABASE_URL='postgres://user:password@localhost:5432/dbname' pgweb"
    echo ""
    echo "📝 For Railway Production:"
    echo "   Get DATABASE_URL from Railway:"
    echo "   railway link"
    echo "   Then export and run pgweb"
    echo ""
    exit 1
fi

echo "✅ DATABASE_URL found"
echo ""

# Option 1: Using pgweb if installed
if command -v pgweb &> /dev/null; then
    echo "🚀 Starting pgweb with:"
    echo "   URL: $DATABASE_URL"
    echo ""
    echo "   Web UI will be available at: http://localhost:8081"
    echo ""
    pgweb --url "$DATABASE_URL"
else
    echo "❌ pgweb not installed"
    echo ""
    echo "📦 Installation:"
    echo "   macOS/Linux:"
    echo "     brew install pgweb"
    echo ""
    echo "   Windows (using Scoop):"
    echo "     scoop install pgweb"
    echo ""
    echo "   Or download from:"
    echo "     https://sosedoff.com/pgweb/"
    echo ""
fi
