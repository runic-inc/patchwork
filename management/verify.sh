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
ASSIGNER_CONTRACT_ADDRESS=""
CHAIN_ID=""
API_KEY=""

case $NETWORK in
  "base")
    CONTRACT_ADDRESS=$BASE_PATCHWORK_ADDRESS
    ASSIGNER_CONTRACT_ADDRESS=$BASE_PATCHWORK_ASSIGNER_ADDRESS
    CHAIN_ID=$BASE_CHAIN_ID
    API_KEY=$BASESCAN_API_KEY
    ;;
  "sepolia")
    CONTRACT_ADDRESS=$SEPOLIA_PATCHWORK_ADDRESS
    ASSIGNER_CONTRACT_ADDRESS=$SEPOLIA_PATCHWORK_ASSIGNER_ADDRESS
    CHAIN_ID=$SEPOLIA_CHAIN_ID
    API_KEY=$ETHERSCAN_API_KEY
    ;;
  *)
    echo "Network not supported"
    exit 1
    ;;
esac


COMPILER_VERSION="0.8.23+commit.f704f362"
OPTIMIZER_RUNS=200

forge verify-contract $ASSIGNER_CONTRACT_ADDRESS src/PatchworkProtocolAssigner.sol:PatchworkProtocolAssigner \
                      --constructor-args "0x0000000000000000000000003fEAb664aAC5550765cddA720Dd10A2874A63601" \
                      --chain-id $CHAIN_ID \
                      --compiler-version $COMPILER_VERSION \
                      --optimizer-runs $OPTIMIZER_RUNS \
                      --etherscan-api-key $API_KEY \
                      --watch

CLEANED_ASSIGNER_CONTRACT_ADDRESS=$(echo "$ASSIGNER_CONTRACT_ADDRESS" | sed 's/^0x//')

forge verify-contract $CONTRACT_ADDRESS src/PatchworkProtocol.sol:PatchworkProtocol \
                      --constructor-args "0x0000000000000000000000003fEAb664aAC5550765cddA720Dd10A2874A63601000000000000000000000000$CLEANED_ASSIGNER_CONTRACT_ADDRESS"\
                      --chain-id $CHAIN_ID \
                      --compiler-version $COMPILER_VERSION \
                      --optimizer-runs $OPTIMIZER_RUNS \
                      --etherscan-api-key $API_KEY \
                      --watch

