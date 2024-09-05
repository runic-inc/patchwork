#!/bin/bash

# Change working directory to the root of the repo
cd "$(dirname "$0")/../"

# Run forge build
forge build

# Make artifacts directory if it doesn't exist
mkdir -p artifacts
# Empty artifacts directory
rm -rf artifacts/*

# Copy .json files to /artifacts from directories with the format *.sol, excluding directories with the format *.t.sol
find out -type f -name "*.json" -not -path "*/.t.sol/*" -exec cp {} artifacts \;