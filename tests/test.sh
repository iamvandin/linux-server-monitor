#!/bin/bash

set -e

echo "Running Linux Server Monitor tests..."

bash -n monitor.sh

echo "✓ Bash syntax test passed"

echo "All tests passed!"
