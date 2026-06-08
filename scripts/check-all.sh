#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR/apps/mobile"
flutter analyze
flutter test

cd "$ROOT_DIR/apps/api"
npm run typecheck
npm test
