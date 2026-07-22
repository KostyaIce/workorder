#!/bin/bash
################################################################################
# WorkOrder - Git Hooks Setup (Linux/macOS)
# Run: bash utils/hooks/setup-hooks.sh
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "Project root: $PROJECT_ROOT"

if [ ! -f "utils/hooks/install.py" ]; then
    echo "Error: utils/hooks/install.py not found"
    exit 1
fi

if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD=python3
elif command -v python >/dev/null 2>&1; then
    PYTHON_CMD=python
else
    echo "Error: Python 3 not found"
    exit 1
fi

if [ ! -d ".git" ]; then
    echo "Error: Not in a Git repository"
    exit 1
fi

"$PYTHON_CMD" utils/hooks/install.py
