#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2024-2026 Bullium Consulting
###############################################################################
# Developer environment setup script
# Run once after cloning to configure git hooks and verify dependencies
#
# Usage: bash setup.sh
#
# Author: Bullium Consulting <support@bullium.com>
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Bullium Consulting — Developer Setup ==="
echo ""

# Configure git hooks
echo "[1/4] Configuring git hooks..."
git config core.hooksPath .githooks
echo "  ✓ Git hooks path set to .githooks/"

# Check for shellcheck
echo "[2/4] Checking linting dependencies..."
if command -v shellcheck >/dev/null 2>&1; then
    echo "  ✓ shellcheck $(shellcheck --version | head -2 | tail -1)"
else
    echo "  ✗ shellcheck not found — install via: brew install shellcheck (macOS) or apt install shellcheck (Linux)"
fi

# Check for bats
if command -v bats >/dev/null 2>&1; then
    echo "  ✓ bats $(bats --version)"
else
    echo "  ✗ bats not found — install via: brew install bats-core (macOS) or apt install bats (Linux)"
fi

# Check for runtime dependencies
echo "[3/4] Checking runtime dependencies..."
if command -v nmap >/dev/null 2>&1; then
    echo "  ✓ nmap $(nmap --version | head -1)"
else
    echo "  ✗ nmap not found — install via: brew install nmap (macOS) or sudo apt-get install -y nmap (Linux)"
fi

if command -v jq >/dev/null 2>&1; then
    echo "  ✓ jq $(jq --version)"
else
    echo "  ✗ jq not found — install via: brew install jq (macOS) or sudo apt-get install -y jq (Linux)"
fi

# Verify hooks are executable
echo "[4/4] Verifying hooks..."
if [ -x "${SCRIPT_DIR}/.githooks/pre-commit" ]; then
    echo "  ✓ pre-commit hook is executable"
else
    chmod +x "${SCRIPT_DIR}/.githooks/pre-commit"
    echo "  ✓ pre-commit hook made executable"
fi

if [ -x "${SCRIPT_DIR}/.githooks/commit-msg" ] 2>/dev/null; then
    echo "  ✓ commit-msg hook is executable"
fi

echo ""
echo "Setup complete! Git hooks and linting are now active."
