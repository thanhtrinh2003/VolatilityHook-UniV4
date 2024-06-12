#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -x  # Print commands and their arguments as they are executed

# Source the environment variables
source ../.env

# Check if SEPOLIA_RPC_URL is set
if [ -z "$SEPOLIA_RPC_URL" ]; then
  echo "Error: SEPOLIA_RPC_URL is not set in the environment variables."
  exit 1
fi

# Run the Forge script
forge script --chain sepolia ../script/DeployERC20s.s.sol --tc DeployTokens --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv


# next, given the contract addresses, use the following script to deploy the 
# sETH: 0x43616E6DD5e344f7F5c8591e15abEd5b004d72bd.
# sUSD: 0x7714de3399A9daDFa46Cc196E0373FB09b2c2436


