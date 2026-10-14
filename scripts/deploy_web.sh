#!/bin/bash
set -e

# Build and deploy the Flutter web app and documentation bundle to the gh-pages branch.
#
# Root layout on gh-pages:
#   /                    <- Landing page (from docs/)
#   /app/                <- Modern NiN Guide Flutter Web app (from build/web/)
#   /v2.3/               <- Frozen NiN 2.3 legacy web app (from archive/v2.3-web/)
#   /privacy_policy.html <- Web privacy policy

DEPLOY=false
REPO_NAME="${GITHUB_PAGES_REPO:-natur-i-norge}"
TARGET_BRANCH="${PAGES_BRANCH:-gh-pages}"
WEB_BASE_HREF=""

for arg in "$@"; do
  case $arg in
    --deploy|-d)
      DEPLOY=true
      ;;
    --repo-name=*)
      REPO_NAME="${arg#*=}"
      ;;
    --branch=*)
      TARGET_BRANCH="${arg#*=}"
      ;;
    --base-href=*)
      WEB_BASE_HREF="${arg#*=}"
      ;;
  esac
done

if [ -z "$WEB_BASE_HREF" ]; then
  WEB_BASE_HREF="/${REPO_NAME}/app/"
fi

# Ensure trailing slash
if [[ "$WEB_BASE_HREF" != */ ]]; then
  WEB_BASE_HREF="${WEB_BASE_HREF}/"
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="${BUILD_NAME:-}"
if [ -z "$VERSION" ] && [ -f pubspec.yaml ]; then
  VERSION=$(sed -n -E 's/^[[:space:]]*version:[[:space:]]*//p' pubspec.yaml | head -n 1 | cut -d '+' -f 1 | tr -cd '0-9.a-zA-Z-')
fi
VERSION="${VERSION:-1.0.0}"

BUILD_NUM="${BUILD_NUMBER:-}"
if [ -z "$BUILD_NUM" ]; then
  BUILD_NUM=$(git rev-list --count HEAD 2>/dev/null || echo 1)
fi

echo "=================================================="
echo "🌐 Flutter Web Build & Deployment"
echo "   App Version:   ${VERSION}"
echo "   Build Number:  ${BUILD_NUM}"
echo "   Base Href:     ${WEB_BASE_HREF}"
echo "   Target Branch: ${TARGET_BRANCH}"
echo "   Deploy Mode:   ${DEPLOY}"
echo "=================================================="

BUILD_DIR="build/web"
STAGING_DIR="build/gh-pages-staging"

echo "🔨 Building Flutter web bundle..."
flutter build web --release --base-href="${WEB_BASE_HREF}" --build-name="${VERSION}" --build-number="${BUILD_NUM}"

echo "📁 Assembling deployment payload in ${STAGING_DIR}/..."
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}/app" "${STAGING_DIR}/v2.3"

# 1. Copy landing page and root static files from docs/
if [ -f docs/.nojekyll ]; then
  cp docs/.nojekyll "${STAGING_DIR}/"
else
  touch "${STAGING_DIR}/.nojekyll"
fi
cp docs/index.html "${STAGING_DIR}/"
cp docs/privacy_policy.html "${STAGING_DIR}/"
cp docs/style.css "${STAGING_DIR}/"
cp docs/logo.png "${STAGING_DIR}/"
if [ -d docs/qr ]; then
  cp -r docs/qr "${STAGING_DIR}/"
fi

# 2. Copy compiled Flutter web app into app/
rsync -a --delete "${BUILD_DIR}/" "${STAGING_DIR}/app/"

# 3. Assemble legacy v2.3 bundle into v2.3/
# shellcheck source=legacy_web_root.sh
source "$(dirname "$0")/legacy_web_root.sh"
if ARCHIVE_WEB="$(_legacy_web_root 2>/dev/null)"; then
  echo "📦 Syncing legacy web from ${ARCHIVE_WEB}..."
  rsync -a "${ARCHIVE_WEB}/" "${STAGING_DIR}/v2.3/"
  if [ -f "$(dirname "$0")/patch_legacy_web_for_pages.py" ]; then
    python3 "$(dirname "$0")/patch_legacy_web_for_pages.py" "/${REPO_NAME}/v2.3/" "${STAGING_DIR}/v2.3"
  fi
elif [ -d "docs/v2.3" ]; then
  echo "📦 Copying legacy web from docs/v2.3/..."
  rsync -a "docs/v2.3/" "${STAGING_DIR}/v2.3/"
fi

# 4. Sync app/ and v2.3/ to local docs/ for local preview compatibility (ignored by git on main)
mkdir -p docs/app docs/v2.3
rsync -a --delete "${BUILD_DIR}/" "docs/app/"
if [ -d "${STAGING_DIR}/v2.3" ]; then
  rsync -a "${STAGING_DIR}/v2.3/" "docs/v2.3/"
fi

PAYLOAD_SIZE=$(du -sh "${STAGING_DIR}" | cut -f1)
echo "✅ Staged web payload ready (${PAYLOAD_SIZE})"
echo "   Preview locally:  ./scripts/preview_web.sh"
echo "   Then open:        http://localhost:8080/${REPO_NAME}/app/"

if [ "$DEPLOY" = false ]; then
  echo ""
  echo "ℹ️  To publish this build to the ${TARGET_BRANCH} branch, run:"
  echo "   ./scripts/deploy_web.sh --deploy"
  echo "   or: ./publish.sh web --deploy"
  exit 0
fi

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "❌ Error: Not inside a git repository"
  exit 1
fi

echo "🚀 Publishing web payload to branch '${TARGET_BRANCH}'..."

# Configure git identity for committing if not already set
export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-$(git config user.name 2>/dev/null || echo 'CI Builder')}"
export GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-$(git config user.email 2>/dev/null || echo 'ci@internal.michaltorma.com')}"
export GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-$GIT_AUTHOR_NAME}"
export GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-$GIT_AUTHOR_EMAIL}"

# Stage tree using isolated index outside work tree
TEMP_INDEX=$(mktemp)
trap 'rm -f "$TEMP_INDEX"' EXIT INT TERM

GIT_INDEX_FILE="$TEMP_INDEX" git read-tree --empty
GIT_INDEX_FILE="$TEMP_INDEX" git --work-tree="${STAGING_DIR}" add -A
TREE=$(GIT_INDEX_FILE="$TEMP_INDEX" git write-tree)
rm -f "$TEMP_INDEX"

# Push target and optional CI credentials
PUSH_REMOTE="origin"
ORIGIN_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [ -n "$GIT_TOKEN" ]; then
  GIT_AUTH_USER="${GIT_USER:-oauth2}"
  if [[ "$ORIGIN_URL" == https://* ]]; then
    PUSH_REMOTE="https://${GIT_AUTH_USER}:${GIT_TOKEN}@${ORIGIN_URL#https://}"
  elif [[ "$ORIGIN_URL" == http://* ]]; then
    PUSH_REMOTE="http://${GIT_AUTH_USER}:${GIT_TOKEN}@${ORIGIN_URL#http://}"
  fi
fi

# Determine parent commit on target branch if it exists on origin or locally
PARENT_COMMIT=""
if git ls-remote --exit-code --heads "$PUSH_REMOTE" "${TARGET_BRANCH}" >/dev/null 2>&1; then
  git fetch "$PUSH_REMOTE" "+${TARGET_BRANCH}:${TARGET_BRANCH}" 2>/dev/null || true
  PARENT_COMMIT=$(git rev-parse --verify "refs/heads/${TARGET_BRANCH}" 2>/dev/null || true)
elif git show-ref --verify --quiet "refs/heads/${TARGET_BRANCH}"; then
  PARENT_COMMIT=$(git rev-parse --verify "refs/heads/${TARGET_BRANCH}" 2>/dev/null || true)
fi

COMMIT_MSG="Deploy web app v${VERSION} (#${BUILD_NUM})"
if [ -n "$PARENT_COMMIT" ]; then
  NEW_COMMIT=$(git commit-tree "$TREE" -p "$PARENT_COMMIT" -m "$COMMIT_MSG")
else
  NEW_COMMIT=$(git commit-tree "$TREE" -m "$COMMIT_MSG")
fi

git update-ref "refs/heads/${TARGET_BRANCH}" "$NEW_COMMIT"

echo "📤 Pushing branch '${TARGET_BRANCH}' to origin..."
git push "$PUSH_REMOTE" "${TARGET_BRANCH}:${TARGET_BRANCH}"

echo "🎉 Deployment to ${TARGET_BRANCH} complete!"
echo "   Landing Page: https://geco-nhm.github.io/${REPO_NAME}/"
echo "   Web App:      https://geco-nhm.github.io/${REPO_NAME}/app/"
if [ -f "${STAGING_DIR}/v2.3/index.html" ]; then
  echo "   Legacy v2.3:  https://geco-nhm.github.io/${REPO_NAME}/v2.3/"
fi
