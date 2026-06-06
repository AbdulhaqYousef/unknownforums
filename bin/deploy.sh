#!/bin/bash
#
# Deploy script for UnknownForums
# Usage: ./bin/deploy.sh [options]
#
# Options:
#   --no-cache    Build without cache (slower, use when gems/base image changed)
#   --full        Also clear application cache after deploy
#

set -e

# Auto-detect app directory, or fallback to fixed path
APP_DIR="${FORUMS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$APP_DIR"

NO_CACHE=false
FULL=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --no-cache)
      NO_CACHE=true
      shift
      ;;
    --full)
      FULL=true
      shift
      ;;
    --help|-h)
      echo "Usage: ./bin/deploy.sh [options]"
      echo ""
      echo "Options:"
      echo "  --no-cache    Build without cache (slower, use when gems/Dockerfile changed)"
      echo "  --full        Also clear application cache after deploy"
      echo "  --help, -h    Show this help"
      exit 0
      ;;
  esac
done

echo "=========================================="
echo "🚀 Starting deploy..."
echo "=========================================="
echo ""

# Check if we're in a git repo
if [ ! -d .git ]; then
  echo "❌ Error: Not a git repository"
  exit 1
fi

# Pull latest code
echo "📥 Pulling latest code..."
git pull origin main
echo ""

# Build arguments
BUILD_ARGS=""
if [ "$NO_CACHE" = true ]; then
  echo "🔨 Building without cache..."
  BUILD_ARGS="--no-cache"
else
  echo "🔨 Building with cache..."
fi

# Build
docker compose build $BUILD_ARGS
echo ""

# Restart containers
echo "🔄 Restarting containers..."
docker compose up -d
echo ""

echo "🗄️  Running database migrations..."
docker compose exec web bin/rails db:migrate
echo ""

# Clear cache if full deploy
if [ "$FULL" = true ]; then
  echo "🧹 Clearing application cache..."
  docker compose exec web bin/rails runner 'Rails.cache.clear'
  echo ""
fi

# Show status
echo "=========================================="
echo "✅ Deploy complete!"
echo "=========================================="
echo ""
echo "💡 Tip: Install 'forums-deploy' system-wide:"
echo "   sudo cp bin/forums-deploy /usr/local/bin/"
echo "   sudo chmod +x /usr/local/bin/forums-deploy"
echo "   Then run 'forums-deploy' from anywhere"
echo ""
echo "Container status:"
docker compose ps
echo ""
echo "Recent logs:"
docker compose logs --tail=5 web
