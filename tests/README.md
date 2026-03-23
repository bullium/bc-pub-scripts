# Tests

## Framework

Tests use [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core).

**Install BATS (if not already installed):**
```bash
# macOS
brew install bats-core

# RHEL/CentOS
dnf install bats

# Manual (any platform)
git clone https://github.com/bats-core/bats-core.git
cd bats-core && ./install.sh /usr/local
```

## Running Tests

```bash
# Run the full suite (from repo root)
bats tests/bats/

# Run PVE tests
bats tests/bats/pve.bats

# TAP output (useful for CI integration)
bats --tap tests/bats/

# Verbose output
bats --verbose-run tests/bats/
```

## Directory Structure

```
tests/
├── bats/
│   ├── helpers/
│   │   └── common.bash          # Shared helpers: REPO_ROOT, mock_command(),
│   │                            # assert_output_contains()
│   └── pve.bats                 # Structural tests for pve/ scripts
└── README.md                    # This file
```

## Writing New Tests

1. Create a new `.bats` file in `tests/bats/` named after the script category.
2. Load shared helpers at the top: `load "helpers/common"`
3. Set `cd "$REPO_ROOT"` in `setup()` so script paths resolve correctly.
4. Name tests descriptively: `@test "script_name: what it should do"`

**Example:**
```bash
#!/usr/bin/env bats

load "helpers/common"

setup() {
    cd "$REPO_ROOT"
}

@test "my_script: exits 0 on success" {
    run bash pve/my_script.sh
    [ "$status" -eq 0 ]
}

@test "my_script: outputs expected header" {
    run bash pve/my_script.sh
    assert_output_contains "Expected Header Text"
}
```

## Scope

Only read-only, non-destructive scripts are tested directly.
Scripts that modify system state (reboots, package installs, drive replacement)
are tested via structural checks (file exists, `set -euo pipefail` present,
shellcheck passes) rather than execution.
