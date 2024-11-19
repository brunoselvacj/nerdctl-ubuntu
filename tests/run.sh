#!/bin/bash
set -e

# Change to project root directory
cd "$(dirname "$0")/.."

case "$1" in
  "test")
    docker build -f tests/docker/Dockerfile -t nerdctl-test . && \
    docker run --rm nerdctl-test
    ;;
  *)
    echo "Usage: $0 [test]"
    echo "Commands:"
    echo "  test    Run the installer tests in a Docker container"
    exit 1
    ;;
esac
