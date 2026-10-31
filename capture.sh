#!/usr/bin/env bash
# Capture desktop and mobile screenshots of a running preview.
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
cd "$PROJECT_DIR"

t() { /usr/bin/time -p "$@"; }

: "${CAPTURE_URL:?Set CAPTURE_URL to the preview URL.}"
: "${CAPTURE_DIR:?Set CAPTURE_DIR to an output directory outside the source tree.}"

# Validate inputs before starting a browser. These are script defects, not
# temporary infrastructure failures, so they exit 1.
t node -e '
  const url = new URL(process.env.CAPTURE_URL)
  if (url.protocol !== "http:" && url.protocol !== "https:") throw new Error("CAPTURE_URL must be http(s)")
'

capture_dir="$(t realpath -m "$CAPTURE_DIR")"
project_dir="$(t realpath -m "$PROJECT_DIR")"
case "$capture_dir/" in
  "$project_dir/"*)
    echo "CAPTURE_DIR must be outside PROJECT_DIR ($project_dir)." >&2
    exit 1
    ;;
esac

t mkdir -p "$capture_dir"
echo "Capturing $CAPTURE_URL into $capture_dir"

# default-capture.mjs opens the exact URL, waits for rendered content, writes
# final-desktop.png and final-mobile.png, closes its own browser, and exits 75
# for temporary browser/navigation failures.
t env CAPTURE_URL="$CAPTURE_URL" CAPTURE_DIR="$capture_dir" \
  node "${RUNTIME_DIR:?}/scripts/default-capture.mjs"

echo "Capture complete: $capture_dir/final-desktop.png and $capture_dir/final-mobile.png"
