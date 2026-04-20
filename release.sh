#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# BrewStaggerBar · release.sh
#
# Usage: ./release.sh
#
# 1. Reads the version from BrewStaggerBar.toc (## Version: X.Y.Z)
# 2. Commits any pending changes (git add -A + commit)
# 3. Packages the addon into BrewStaggerBar-vX.Y.Z.zip
# 4. Creates an annotated git tag using the matching CHANGELOG.md entry
# ---------------------------------------------------------------------------

ADDON_NAME="BrewStaggerBar"
TOC_FILE="${ADDON_NAME}.toc"
CHANGELOG_FILE="CHANGELOG.md"

# Files/dirs to exclude from the zip (relative to project root)
EXCLUDE_PATTERNS=(
    ".git"
    ".gitignore"
    "release.sh"
    "CHANGELOG.md"
    "README.md"
    "logo.png"
    "*.zip"
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die() { echo "ERROR: $*" >&2; exit 1; }

# Read version from .toc
read_version() {
    grep -oP '## Version:\s*\K[0-9]+\.[0-9]+\.[0-9]+' "$TOC_FILE" \
        || die "Could not read version from $TOC_FILE"
}

# Extract the changelog block for a given version (e.g. "2.0.0")
# Looks for "## v2.0.0" and collects lines until the next "## " heading
extract_changelog() {
    local version="$1"
    local inside=0
    local block=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^##[[:space:]]+v${version}([[:space:]]|$) ]]; then
            inside=1
            continue
        fi
        if [[ $inside -eq 1 ]]; then
            # Stop at the next version heading
            if [[ "$line" =~ ^##[[:space:]]+v[0-9] ]]; then
                break
            fi
            block+="${line}"$'\n'
        fi
    done < "$CHANGELOG_FILE"

    # Trim leading/trailing blank lines
    echo "$block" | sed '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba}'
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

VERSION=$(read_version)
TAG="v${VERSION}"
ZIP_NAME="${ADDON_NAME}-${TAG}.zip"

echo "┌─────────────────────────────────────┐"
echo "│  BrewStaggerBar release              │"
echo "│  Version : ${VERSION}                      │"
echo "│  Tag     : ${TAG}                       │"
echo "└─────────────────────────────────────┘"
echo ""

# 1. Commit pending changes ------------------------------------------------
if [[ -n "$(git status --porcelain)" ]]; then
    echo "── Uncommitted changes detected, staging and committing…"
    git add -A
    git commit -m "v${VERSION}"
    echo "   ✓ Committed"
else
    echo "── Working tree clean, no commit needed"
fi
echo ""

# 2. Check the tag doesn't already exist -----------------------------------
if git rev-parse "$TAG" &>/dev/null; then
    die "Tag $TAG already exists. Delete it first with: git tag -d $TAG"
fi

# 3. Build the zip ---------------------------------------------------------
echo "── Building ${ZIP_NAME}…"

# Build the exclude args for zip
EXCLUDE_ARGS=()
for pat in "${EXCLUDE_PATTERNS[@]}"; do
    EXCLUDE_ARGS+=("--exclude=${ADDON_NAME}/${pat}/*")
    EXCLUDE_ARGS+=("--exclude=${ADDON_NAME}/${pat}")
done

# Create a temp dir with the addon folder name so the zip extracts cleanly
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

ADDON_DIR="${TMPDIR}/${ADDON_NAME}"
mkdir -p "$ADDON_DIR"

# Copy all files, excluding non-addon items
cp -r . "$ADDON_DIR/"
# Remove excluded items from the copy
rm -rf \
    "$ADDON_DIR/.git" \
    "$ADDON_DIR/.gitignore" \
    "$ADDON_DIR/release.sh" \
    "$ADDON_DIR/CHANGELOG.md" \
    "$ADDON_DIR/README.md" \
    "$ADDON_DIR/logo.png"
find "$ADDON_DIR" -maxdepth 1 -name "*.zip" -delete

(cd "$TMPDIR" && zip -r "${OLDPWD}/${ZIP_NAME}" "${ADDON_NAME}/")

echo "   ✓ ${ZIP_NAME} created"
echo ""

# 4. Read changelog for this version ---------------------------------------
CHANGELOG_BODY=""
if [[ -f "$CHANGELOG_FILE" ]]; then
    CHANGELOG_BODY=$(extract_changelog "$VERSION")
fi

if [[ -z "$CHANGELOG_BODY" ]]; then
    CHANGELOG_BODY="Release ${TAG}"
    echo "   ⚠ No CHANGELOG entry found for v${VERSION}, using generic message"
fi

# 5. Create annotated tag --------------------------------------------------
echo "── Creating tag ${TAG}…"
git tag -a "$TAG" -m "${TAG}" -m "$CHANGELOG_BODY"
echo "   ✓ Tag created"
echo ""

# 6. Optionally push -------------------------------------------------------
read -rp "Push tag and commits to origin? [Y/n] " push_confirm
push_confirm=${push_confirm:-Y}

if [[ "$push_confirm" =~ ^[Yy]$ ]]; then
    git push origin HEAD --follow-tags
    echo "   ✓ Pushed"
else
    echo "   Skipped. Push manually:"
    echo "     git push origin HEAD --follow-tags"
fi

echo ""
echo "Done! ${TAG} released → ${ZIP_NAME}"
