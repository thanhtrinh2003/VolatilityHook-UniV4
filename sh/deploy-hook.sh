#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -x  # Print commands and their arguments as they are executed

# Source the environment variables from .env file
source ../.env

# Export the necessary addresses as environment variables, to be used by the script
# Sepolia Pool Manager address
export POOLMANAGER="0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14"
 # TODO: these contracts below might need to be redeployed on every pool initialization

# Run the Forge script with the specified RPC URL
forge script ../script/RVHookDeployment.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
