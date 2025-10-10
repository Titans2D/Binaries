#!/bin/bash
#
# clean_xpm.sh — convierte un XPM con wrapper C en XPM “puro”
#
SRC="team_logo.xpm"
TMP="team_logo.clean.xpm"

if [ ! -f "$SRC" ]; then
  echo "❌ No encuentro $SRC en $(pwd)" >&2
  exit 1
fi

awk '/^"/ {
  line = $0
  sub(/^"/, "", line)
  sub(/",?$/, "", line)
  print line
}' "$SRC" > "$TMP"

mv "$TMP" "$SRC"
echo "✅ $SRC convertido a XPM puro."
