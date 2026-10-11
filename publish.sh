#!/bin/bash
set -e

# DEPRECATED: This script is being deprecated in favor of mobile-ops and Jenkins shared library (flutterPipeline).
# Retained temporarily for screenshot automation reference (see scripts/automate_screenshots.sh and scripts/automate_ios_screenshots.sh).
echo "⚠️  NOTE: publish.sh is deprecated. Prefer CI/CD via mobile-ops and Jenkins flutterPipeline." >&2

# publish.sh - Non-interactive publication script for iOS, Android, and Web

# 1. Parse arguments
PLATFORM=""
RUN_SCREENSHOTS=false
DEPLOY_WEB=false
PREVIEW_WEB=false
GITHUB_RELEASE=false

for arg in "$@"; do
  case $arg in
    ios|android|both|web|all)
      PLATFORM=$arg
      ;;
    --screenshots|-s)
      RUN_SCREENSHOTS=true
      ;;
    --deploy|-d)
      DEPLOY_WEB=true
      ;;
    --preview|-p)
      PREVIEW_WEB=true
      ;;
    --github-release|-r)
      GITHUB_RELEASE=true
      ;;
    *)
      # Ignore unknown arguments for now
      ;;
  esac
done

if [ -z "$PLATFORM" ]; then
  echo "Usage: ./publish.sh [ios|android|both|web|all] [options]"
  echo ""
  echo "  ios|android|both  Publish to App Store / Google Play (requires .env)"
  echo "  web               Build Flutter web app for GitHub Pages"
  echo "  all               Publish iOS + Android, then build web"
  echo ""
  echo "  --deploy|-d         With 'web': commit docs/app/ (+ docs/v2.3/ if archive exists) and push"
  echo "  --preview|-p        With 'web': serve local preview (GitHub Pages layout)"
  echo "  --github-release|-r After Android publish: create GitHub release with signed APK"
  echo "                      (triggers Zenodo; requires gh auth login)"
  echo ""
  echo "  Legacy v2.3: copy prod web/ to archive/v2.3-web/web/, then ./scripts/sync_legacy_web_to_docs.sh"
  exit 1
fi

if [ "$GITHUB_RELEASE" = true ] && [[ "$PLATFORM" != "android" && "$PLATFORM" != "both" && "$PLATFORM" != "all" ]]; then
  echo "❌ --github-release requires android, both, or all"
  exit 1
fi

if [ "$PREVIEW_WEB" = true ] && [ "$PLATFORM" != "web" ]; then
  echo "❌ --preview can only be used with 'web'"
  exit 1
fi

# 2. Load environment variables from .env (required for mobile, optional for web)
NEEDS_ENV=false
if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "android" || "$PLATFORM" == "both" || "$PLATFORM" == "all" ]]; then
  NEEDS_ENV=true
fi

if [ "$NEEDS_ENV" = true ]; then
  if [ -f .env ]; then
    echo "🔑 Loading environment variables from .env..."
    export $(grep -v '^#' .env | xargs)
  else
    echo "⚠️  No .env file found. Please create one from .env.template"
    exit 1
  fi

  if [ -z "$FASTLANE_USER" ]; then
    echo "❌ Error: FASTLANE_USER is not set in .env"
    exit 1
  fi
fi

# 3. Optional: Run Screenshots
if [ "$RUN_SCREENSHOTS" = true ]; then
  echo "📸 Starting automated screenshot generation..."

  if [[ "$PLATFORM" == "android" || "$PLATFORM" == "both" || "$PLATFORM" == "all" ]]; then
    echo "🤖 Generating Android screenshots..."
    ./scripts/automate_screenshots.sh
  fi

  if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "both" || "$PLATFORM" == "all" ]]; then
    echo "🍏 Generating iOS screenshots..."
    ./scripts/automate_ios_screenshots.sh
  fi

  echo "✅ All requested screenshots generated successfully."
fi

# 4. Execute Publication
publish_mobile() {
  local target=$1
  case $target in
    ios)
      echo "🍏 Starting iOS Publication..."
      echo "📦 Ensuring CocoaPods are up to date..."
      (cd ios && pod install)
      bundle exec fastlane ios deploy
      ;;
    android)
      echo "🤖 Starting Android Publication..."
      bundle exec fastlane android deploy
      if [ "$GITHUB_RELEASE" = true ]; then
        ./scripts/create_github_release.sh
      fi
      ;;
    both)
      echo "🚀 Starting Full Publication (iOS + Android)..."
      echo "📦 Ensuring iOS CocoaPods are up to date..."
      (cd ios && pod install)
      bundle exec fastlane ios deploy
      bundle exec fastlane android deploy
      if [ "$GITHUB_RELEASE" = true ]; then
        ./scripts/create_github_release.sh
      fi
      ;;
  esac
}

case $PLATFORM in
  ios|android|both)
    publish_mobile "$PLATFORM"
    ;;
  web)
    if [ "$PREVIEW_WEB" = true ]; then
      ./scripts/preview_web.sh
    else
      DEPLOY_ARGS=()
      if [ "$DEPLOY_WEB" = true ]; then
        DEPLOY_ARGS+=(--deploy)
      fi
      ./scripts/deploy_web.sh "${DEPLOY_ARGS[@]}"
    fi
    ;;
  all)
    publish_mobile both
    DEPLOY_ARGS=()
    if [ "$DEPLOY_WEB" = true ]; then
      DEPLOY_ARGS+=(--deploy)
    fi
    ./scripts/deploy_web.sh "${DEPLOY_ARGS[@]}"
    ;;
esac

# Note: GitHub release (Zenodo trigger) runs after Android publish and before web
# deploy when using: ./publish.sh all --github-release --deploy

echo "✅ Publication process completed!"
