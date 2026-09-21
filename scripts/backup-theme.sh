#!/usr/bin/env bash
# Back up the live Shopify theme to a timestamped zip.
#
# Why this exists: the theme is edited in the Shopify UI as well as from this
# repo, and Shopify keeps no version history you can roll back to. Git covers
# what we push; this covers what anyone changes in the admin.
#
# Usage:
#   ./scripts/backup-theme.sh              # back up the live theme
#   ./scripts/backup-theme.sh 192728236311 # back up a specific theme id
#
# Backups land in ~/claude/emberwood/backups/theme/ and the last 30 are kept.

set -euo pipefail

STORE="emberwoodandhearth.myshopify.com"
LIVE_THEME_ID="192720699671"
THEME_ID="${1:-$LIVE_THEME_ID}"
BACKUP_ROOT="$HOME/claude/emberwood/backups/theme"
KEEP=30

# cron runs with a minimal PATH that excludes Homebrew, so add it explicitly.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

command -v shopify >/dev/null 2>&1 || {
  echo "ERROR: shopify CLI not found on PATH ($PATH)" >&2
  exit 1
}

STAMP="$(date +%Y%m%d_%H%M%S)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "Pulling theme $THEME_ID from $STORE ..."
if ! shopify theme pull --store "$STORE" --theme "$THEME_ID" --path "$WORK" >/dev/null 2>&1; then
  echo "ERROR: theme pull failed for $THEME_ID" >&2
  exit 1
fi

# A pull that yields no sections means we got an empty or broken tree. Better to
# fail loudly than to write a useless archive and rotate a good one out.
SECTION_COUNT="$(find "$WORK/sections" -name '*.liquid' 2>/dev/null | wc -l | tr -d ' ')"
if [ "$SECTION_COUNT" -lt 5 ]; then
  echo "ERROR: pulled tree looks wrong ($SECTION_COUNT section files). Not writing a backup." >&2
  exit 1
fi

mkdir -p "$BACKUP_ROOT"
ARCHIVE="$BACKUP_ROOT/theme_${THEME_ID}_${STAMP}.zip"
( cd "$WORK" && zip -qr "$ARCHIVE" . )

# Record what the archive actually contains, so a restore does not have to guess.
MANIFEST="$BACKUP_ROOT/theme_${THEME_ID}_${STAMP}.txt"
{
  echo "store:      $STORE"
  echo "theme_id:   $THEME_ID"
  echo "pulled_at:  $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "sections:   $SECTION_COUNT"
  echo "blocks:     $(find "$WORK/blocks" -name '*.liquid' 2>/dev/null | wc -l | tr -d ' ')"
  echo "templates:  $(find "$WORK/templates" -type f 2>/dev/null | wc -l | tr -d ' ')"
  echo "size:       $(du -h "$ARCHIVE" | cut -f1)"
  echo
  echo "custom blocks present:"
  for b in scent-picker sampler-picker; do
    if [ -f "$WORK/blocks/$b.liquid" ]; then echo "  yes $b"; else echo "  NO  $b  <-- missing"; fi
  done
} > "$MANIFEST"

echo "Wrote $ARCHIVE"
cat "$MANIFEST" | sed 's/^/  /'

# Rotate: keep the newest $KEEP archives and their manifests.
ls -1t "$BACKUP_ROOT"/theme_*.zip 2>/dev/null | tail -n +$((KEEP + 1)) | while read -r old; do
  echo "Rotating out $(basename "$old")"
  rm -f "$old" "${old%.zip}.txt"
done
