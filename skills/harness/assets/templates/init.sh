#!/usr/bin/env bash
# Standard startup + baseline verification. Any agent session runs this first.
# Edit the three command arrays; keep the script idempotent.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

INSTALL_CMD=({{pnpm install}})
VERIFY_CMD=({{pnpm lint && pnpm build — split into array or wrap in bash -c}})
START_CMD=({{pnpm dev}})

echo "==> Working directory: $PWD"

echo "==> Syncing dependencies"
"${INSTALL_CMD[@]}"

echo "==> Running baseline verification"
"${VERIFY_CMD[@]}"
echo "==> Baseline verification PASSED"

echo "==> Startup command:"
printf '    %q ' "${START_CMD[@]}"; printf '\n'

if [ "${RUN_START_COMMAND:-0}" = "1" ]; then
  echo "==> Starting the app"
  exec "${START_CMD[@]}"
fi

echo "Set RUN_START_COMMAND=1 to launch the app directly."
