#!/bin/bash

# verify.sh

# Usage instructions
if [ $# -lt 1 ]; then
  echo "Usage: $0 <network>"
  echo "Supported networks: base, sepolia"
  exit 1
fi

NETWORK=$1

# Load the .env file
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else 
  echo ".env file not found"
  exit 1
fi

# Set the network-specific contract address and chain ID
CONTRACT_ADDRESS=""
CHAIN_ID=""

case $NETWORK in
  "base")
    CONTRACT_ADDRESS=$BASE_PATCHWORK_ADDRESS
    CHAIN_ID=$BASE_CHAIN_ID
    ;;
  "sepolia")
    CONTRACT_ADDRESS=$SEPOLIA_PATCHWORK_ADDRESS
    CHAIN_ID=$SEPOLIA_CHAIN_ID
    ;;
  *)
    echo "Network not supported"
    exit 1
    ;;
esac

forge_options="--optimizer-runs=200 --via-ir"

# Verifying the contract on Etherscan
forge verify-contract --chain-id $CHAIN_ID $CONTRACT_ADDRESS src/PatchworkProtocol.sol:PatchworkProtocol $forge_options  --watch 
