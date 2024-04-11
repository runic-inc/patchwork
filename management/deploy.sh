#!/bin/bash

# deploy.sh

# Usage instructions
if [ $# -lt 1 ]; then
  echo "Usage: $0 <network> [--broadcast]"
  echo "Supported networks: base, sepolia, base-sepolia"
  exit 1
fi

# Load the .env file
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else 
  echo ".env file not found"
  exit 1
fi

NETWORK=$1
PATCHWORK_OWNER=""
RPC_URL=""
ASSSIGNER_SALT=0x3feab664aac5550765cdda720dd10a2874a6360108b55e5621d332ed92bacd8a
PATCHWORK_SALT=0x3feab664aac5550765cdda720dd10a2874a63601e0d0bf13a0f99b10db97638b

case $NETWORK in
  "base")
    PATCHWORK_OWNER=$BASE_PATCHWORK_OWNER
    RPC_URL=$BASE_RPC_URL
    ;;
  "sepolia")
    PATCHWORK_OWNER=$SEPOLIA_PATCHWORK_OWNER
    RPC_URL=$SEPOLIA_RPC_URL
    ;;
  "base-sepolia")
    PATCHWORK_OWNER=$BASE_SEPOLIA_PATCHWORK_OWNER
    RPC_URL=$BASE_SEPOLIA_RPC_URL
    ;;
  *)
    echo "Network not supported"
    exit 1
    ;;
esac

# Check for broadcast flag
if [[ " $* " =~ " --broadcast " ]]; then
  echo "Broadcasting is enabled"
  forge_options="$forge_options --broadcast"
fi

# Export the owner address as an environment variable
export PATCHWORK_OWNER

# Execute the Solidity script with the environment variable
forge script $forge_options --optimize --optimizer-runs 200 ./deploy.s.sol:DeterministicPatchworkDeploy \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
