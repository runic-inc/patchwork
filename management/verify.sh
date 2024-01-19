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


COMPILER_VERSION="0.8.23+commit.f704f362"
OPTIMIZER_RUNS=200

#forge_options="--optimizer-runs=200 --via-ir "

# Verifying the contract on Etherscan
#forge verify-contract $CONTRACT_ADDRESS --chain-id $CHAIN_ID  src/PatchworkProtocol.sol:PatchworkProtocol $forge_options  --watch 

forge verify-contract $CONTRACT_ADDRESS src/PatchworkProtocol.sol:PatchworkProtocol \
                      --chain-id $CHAIN_ID \
                      --compiler-version $COMPILER_VERSION \
                      --optimizer-runs $OPTIMIZER_RUNS \
                      --via-ir \
                      --etherscan-api-key $ETHERSCAN_API_KEY \
                      --watch