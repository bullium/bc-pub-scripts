# Contributing to bc-scritps-public

Thank you for your interest in contributing! This guide covers conventions and
workflows for the netvuln-tool repository.

## Getting Started

```bash
# Clone the repository
git clone https://github.com/bullium/bc-pub-scripts.git

# Set up development environment (git hooks, verify dependencies)
bash setup.sh
```

## Code Style

### Bash Scripts

- **File naming**: Underscores only — `my_script.sh` (never `my-script.sh`)
- **Strict mode**: All scripts must begin with `set -euo pipefail`
- **Functions**: Use descriptive names in `snake_case`
- **Variables**: `UPPER_CASE` for constants, `lower_case` for locals
- **Linting**: All scripts must pass `shellcheck` before commit
- **Library functions**: Use `nv_*` prefix (netvuln_common.sh) or `et_*` prefix (exec_template.sh)
- **Header comments**: Include purpose, author, version, and usage

### Shell Template

```bash
#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2024-2026 Bullium Consulting
###############################################################################
# Script Name: example_script.sh
# Description: Brief description of what this script does
# Author: Your Name (Business or OSS project name) <name@email.com>
# Version: X.Y.Z
###############################################################################

set -euo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/netvuln_common.sh"

# ... script body ...
```

## Branching Strategy

- `main` — stable releases only
- `dev` — integration branch for active development
- `feature/*` — new features (branch from `dev`)
- `bugfix/*` — bug fixes (branch from `dev`)

### Workflow

1. Create a feature branch from `dev`: `git checkout -b feature/my-feature dev`
2. Make changes, commit with conventional format
3. Push branch and create a pull request on Gitea
4. After approval, merge to `dev`
5. Release: merge `dev` → `main`, tag with `vX.Y.Z`
6. Sync: `git checkout dev && git merge main && git push origin dev`

## Commit Messages

Use [conventional commits](https://www.conventionalcommits.org/):

```
feat: add network discovery module
fix: correct CIDR validation edge case
docs: update API contract documentation
test: add BATS tests for upload scripts
chore: update shellcheck configuration
refactor: extract common validation functions
```

**Do NOT include** AI attribution markers (Co-Authored-By, "Generated with", etc.).

## Testing

```bash
# Run all tests (735 tests)
bats tests/

# Run specific test file
bats tests/test_submit_session.bats
```

## License

This project is licensed under the [Apache License 2.0](LICENSE).

By contributing, you agree that your contributions will be licensed under the
Apache License 2.0 that covers this project. You also certify that you have the
right to submit the work under this license, per the
[Developer Certificate of Origin (DCO)](https://developercertificate.org/).

### SPDX Headers

All new scripts must include the SPDX license identifier after the shebang line:

```bash
#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2024-2026 Bullium Consulting
```

## Questions?

Open an issue on the repository or contact support@bullium.com.
