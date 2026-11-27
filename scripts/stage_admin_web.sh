#!/usr/bin/env bash
set -euo pipefail

# Builds Flutter Web with the correct base href and copies artifacts into
# ./admin/ at the repository root so Firebase Hosting can serve them at /admin/.
#
# Usage (from repo root):
#   chmod +x scripts/stage_admin_web.sh
#   ./scripts/stage_admin_web.sh
#   firebase deploy --only hosting

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADMIN_DIR="${ROOT}/admin"

cd "${ADMIN_DIR}"

echo ">> flutter pub get"
flutter pub get

echo ">> flutter build web --base-href /admin/ --release --no-tree-shake-icons"
flutter build web --base-href /admin/ --release --no-tree-shake-icons

echo ">> Copying build/web/* -> ${ADMIN_DIR}/ (Hosting artifacts)"
cd "${ADMIN_DIR}"
cp -R build/web/* .

echo ">> Done. Deploy with: firebase deploy --only hosting"
