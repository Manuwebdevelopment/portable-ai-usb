#!/usr/bin/env bash
# populate_checksums.sh — Download models and populate SHA256 checksums in models.json
# Usage: ./scripts/manage/populate_checksums.sh [--dry-run]
#
# Downloads each model from its HuggingFace primary URL, computes SHA256,
# and writes the checksum into config/models.json.
#
# This script is meant to be run once on a machine with fast internet.
# After completion, push the updated models.json to the repo.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_DIR/config/models.json"
CACHE_DIR="$PROJECT_DIR/.cache/models"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

mkdir -p "$CACHE_DIR"

echo "=== Portable AI USB — Checksum Populator ==="
echo "Config: $CONFIG_FILE"
echo "Cache:  $CACHE_DIR"
echo "Dry run: $DRY_RUN"
echo ""

# Parse models.json with python (available on all platforms)
python3 << 'PYTHON_SCRIPT'
import json, hashlib, urllib.request, os, sys

CACHE_DIR = os.environ.get("CACHE_DIR", "/tmp/portable-ai-checksum")
CONFIG_FILE = os.environ.get("CONFIG_FILE", "config/models.json")
DRY_RUN = os.environ.get("DRY_RUN", "false") == "true"
os.makedirs(CACHE_DIR, exist_ok=True)

with open(CONFIG_FILE) as f:
    data = json.load(f)

updated = False
for model in data["models"]:
    url = model["downloads"].get("huggingface_primary", "")
    if not url:
        print(f"  SKIP {model['id']}: no URL")
        continue

    fname = url.split("/")[-1]
    target = os.path.join(CACHE_DIR, fname)

    print(f"  MODEL: {model['id']}")
    sys.stdout.flush()

    # Check if already downloaded and verified
    if os.path.exists(target):
        # Try to read checksum from existing file if stored alongside
        sha_file = target + ".sha256"
        if os.path.exists(sha_file):
            with open(sha_file) as sf:
                checksum = sf.read().strip()
            if checksum and not model["downloads"].get("checksum"):
                model["downloads"]["checksum"] = checksum
                print(f"    ✓ checksum from cache: {checksum[:16]}...")
                updated = True
                continue
            print(f"    ✓ cached ({os.path.getsize(target)} bytes)")
            continue

        # Compute checksum from cached file
        sha = hashlib.sha256()
        with open(target, "rb") as f:
            while True:
                chunk = f.read(1024 * 1024)  # 1MB chunks
                if not chunk:
                    break
                sha.update(chunk)
        hex_sha = sha.hexdigest()
        size = os.path.getsize(target)

        if DRY_RUN:
            print(f"    ✓ dry-run checksum: sha256:{hex_sha} ({size:,} bytes)")
        else:
            model["downloads"]["checksum"] = f"sha256:{hex_sha}"
            # Save checksum alongside file
            with open(sha_file, "w") as sf:
                sf.write(f"sha256:{hex_sha}")
            print(f"    ✓ checksum: sha256:{hex_sha} ({size:,} bytes)")
            updated = True
        continue

    # Download file
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "Portable-AI-USB/1.0",
            "Accept-Encoding": "identity"  # don't ask for compressed
        })
        with urllib.request.urlopen(req, timeout=30) as resp:
            if resp.status == 404:
                print(f"    ⚠ 404 not found")
                continue
            data_stream = resp.read()

        sha = hashlib.sha256(data_stream).hexdigest()
        size = len(data_stream)

        # Save to cache
        with open(target, "wb") as f:
            f.write(data_stream)

        # Save checksum alongside
        sha_file = target + ".sha256"
        with open(sha_file, "w") as sf:
            sf.write(f"sha256:{sha}")

        if DRY_RUN:
            print(f"    ✓ dry-run checksum: sha256:{sha} ({size:,} bytes)")
        else:
            model["downloads"]["checksum"] = f"sha256:{sha}"
            updated = True
            print(f"    ✓ checksum: sha256:{sha} ({size:,} bytes)")

    except Exception as e:
        print(f"    ⚠ error: {e}")
        continue

if updated and not DRY_RUN:
    with open(CONFIG_FILE, "w") as f:
        json.dump(data, f, indent=2)
    print(f"\n✓ Updated {CONFIG_FILE}")

PYTHON_SCRIPT

echo ""
echo "=== Done ==="
echo "Next steps:"
echo "  1. Verify the updated config/models.json"
echo "  2. Commit and push to git"
echo "  3. All models now have SHA256 checksums for download verification"
