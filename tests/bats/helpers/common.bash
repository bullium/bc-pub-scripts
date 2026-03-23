#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2024-2026 Bullium Consulting
# =============================================================================
# File:        tests/bats/helpers/common.bash
# Description: Shared helpers for BATS test files
# Usage:       load "helpers/common"  (from within a .bats file)
# =============================================================================

# Absolute path to the repository root
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"

# -----------------------------------------------------------------------------
# skip_if_not_linux
#
# Skips the current test when not running on Linux. Use for tests that run
# scripts relying on Linux-only paths (/bin/awk, /bin/clear, etc.).
# -----------------------------------------------------------------------------
skip_if_not_linux() {
    if [[ "$(uname)" != "Linux" ]]; then
        skip "Requires Linux — script uses Linux-specific paths (run on RHEL/CentOS target)"
    fi
}

# -----------------------------------------------------------------------------
# mock_command <name> [exit_code] [output]
#
# Creates a mock executable in a temporary directory that is prepended to PATH.
# Subsequent calls to <name> will return the given exit_code and print output.
#
# Example:
#   mock_command "hostname" 0 "myserver"
#   run hostname
#   [ "$output" = "myserver" ]
# -----------------------------------------------------------------------------
mock_command() {
    local cmd="$1"
    local exit_code="${2:-0}"
    local mock_output="${3:-}"
    local mock_dir="${BATS_TMPDIR}/mocks"

    mkdir -p "$mock_dir"
    printf '#!/bin/bash\nprintf "%%s\n" "%s"\nexit %d\n' \
        "$mock_output" "$exit_code" > "${mock_dir}/${cmd}"
    chmod +x "${mock_dir}/${cmd}"
    export PATH="${mock_dir}:${PATH}"
}

# -----------------------------------------------------------------------------
# assert_output_contains <substring>
#
# Fails the test if $output does not contain the given substring.
# -----------------------------------------------------------------------------
assert_output_contains() {
    local substring="$1"
    if [[ "$output" != *"$substring"* ]]; then
        echo "Expected output to contain: '$substring'"
        echo "Actual output: '$output'"
        return 1
    fi
}
