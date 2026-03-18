#!/usr/bin/env bash
set -euo pipefail
echo "hello from shared skill: $(cd "$(dirname "$0")/.." && pwd)"
