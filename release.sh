#!/usr/bin/env bash
set -euo pipefail

#-----------------------------------------------------------------------
# StaggerBar · release.sh
# Usage:
#   ./release.sh 1.2.0              — release with manual version
#   ./release.sh 1.2.0 "Fixed glow" — release with one-line changelog
#   ./release.sh patch               — auto-bump patch  (1.1.0 → 1.1.1)
#   ./release.sh minor               — auto-bump minor  (1.1.0 → 1.2.0)
#   ./release.sh major               — auto-bump major  (1.1.0 → 2.0.0)
#-----------------------------------------------------------------------

TOC_FILE="BrewStaggerBar.toc"
README_FILE="README.md"
CHANGELOG_FILE="CHANGELOG.md"
DATE=$(date +%Y-%m-%d)

#-----------------------------------------------------------------------
# Read current version from .toc
#-----------------------------------------------------------------------
current_version() {
    grep -oP '## Version: \K[0-9]+\.[0-9]+\.[0-9]+' "$TOC_FILE"
}

#-----------------------------------------------------------------------
# Auto-bump version
#-----------------------------------------------------------------------
bump_version() {
    local cur="$1"
    local part="$2"
    local major minor patch
    IFS='.' read -r major minor patch <<< "$cur"

    case "$part" in
        major) echo "$((major + 1)).0.0" ;;
        minor) echo "${major}.$((minor + 1)).0" ;;
        patch) echo "${major}.${minor}.$((patch + 1))" ;;
        *)     echo "$part" ;;  # treat as literal version
    esac
}

#-----------------------------------------------------------------------
# Validate semver format
#-----------------------------------------------------------------------
validate_version() {
    if ! [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: '$1' is not a valid semver (X.Y.Z)"
        exit 1
    fi
}

#-----------------------------------------------------------------------
# Main
#-----------------------------------------------------------------------
if [[ $# -lt 1 ]]; then
    echo "Usage: ./release.sh <version|patch|minor|major> [changelog message]"
    echo "Current version: $(current_version)"
    exit 1
fi

CUR=$(current_version)
NEW=$(bump_version "$CUR" "$1")
validate_version "$NEW"

CHANGELOG_MSG="${2:-}"

echo "╔══════════════════════════════════════╗"
echo "║  BrewStaggerBar Release              ║"
echo "║  $CUR → $NEW                         ║"
echo "╚══════════════════════════════════════╝"
echo ""

#-----------------------------------------------------------------------
# 1. Update version in .toc
#-----------------------------------------------------------------------
sed -i "s/## Version: .*/## Version: $NEW/" "$TOC_FILE"
echo "✓ Updated $TOC_FILE"

#-----------------------------------------------------------------------
# 2. Update version badge in README
#-----------------------------------------------------------------------
if [[ -f "$README_FILE" ]]; then
    # Update any explicit version mentions in badges or text
    sed -i "s/Version-[0-9]\+\.[0-9]\+\.[0-9]\+/Version-$NEW/g" "$README_FILE"
    echo "✓ Updated $README_FILE"
fi

#-----------------------------------------------------------------------
# 3. Prepend changelog entry
#-----------------------------------------------------------------------
if [[ -f "$CHANGELOG_FILE" ]]; then
    TMPFILE=$(mktemp)

    # Header
    echo "# StaggerBar Changelog" > "$TMPFILE"
    echo "" >> "$TMPFILE"
    echo "## v${NEW} (${DATE})" >> "$TMPFILE"

    if [[ -n "$CHANGELOG_MSG" ]]; then
        # Single message passed as argument
        echo "- $CHANGELOG_MSG" >> "$TMPFILE"
    else
        # Collect git log since last tag
        LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
        if [[ -n "$LAST_TAG" ]]; then
            echo "### Changes since ${LAST_TAG}:" >> "$TMPFILE"
            git log "${LAST_TAG}..HEAD" --pretty=format:"- %s" --no-merges >> "$TMPFILE"
        else
            echo "- Release v${NEW}" >> "$TMPFILE"
        fi
    fi

    echo "" >> "$TMPFILE"
    echo "" >> "$TMPFILE"

    # Append old changelog (skip first header line to avoid duplicates)
    tail -n +2 "$CHANGELOG_FILE" >> "$TMPFILE"

    mv "$TMPFILE" "$CHANGELOG_FILE"
    echo "✓ Updated $CHANGELOG_FILE"
fi

#-----------------------------------------------------------------------
# 4. Normalize line endings to LF
#-----------------------------------------------------------------------
echo ""
echo "Normalizing line endings (CRLF → LF)..."
find . -name "*.lua" -o -name "*.xml" -o -name "*.toc" -o -name "*.md" -o -name "*.txt" \
    | while read -r file; do
        if file "$file" | grep -q CRLF; then
            sed -i 's/\r$//' "$file"
            echo "  ✓ Fixed: $file"
        fi
    done
echo "✓ Line endings normalized"

#-----------------------------------------------------------------------
# 5. Stage, commit and tag
#-----------------------------------------------------------------------
echo ""
read -rp "Stage, commit and tag v${NEW}? [Y/n] " confirm
confirm=${confirm:-Y}

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    git add -A
    git commit -m "Release v${NEW}" -m "$(cat <<EOF
Version: $NEW
Date: $DATE
${CHANGELOG_MSG:+
Changes: $CHANGELOG_MSG}
EOF
)"
    git tag -a "v${NEW}" -m "Release v${NEW}"

    echo ""
    echo "✓ Committed and tagged v${NEW}"
    echo ""

    read -rp "Push to origin (with tags)? [Y/n] " push_confirm
    push_confirm=${push_confirm:-Y}
    if [[ "$push_confirm" =~ ^[Yy]$ ]]; then
        git push origin HEAD --follow-tags
        echo "✓ Pushed to origin"
    else
        echo "Skipped push. Run manually:"
        echo "  git push origin HEAD --follow-tags"
    fi
else
    echo "Skipped commit. Files are modified — review and commit manually."
fi

echo ""
echo "Done! v${NEW} ready."
