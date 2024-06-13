#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -x  # Print commands and their arguments as they are executed

# Source the environment variables from .env file
source ../.env

# Export the necessary addresses as environment variables, to be used by the script
# Sepolia Pool Manager address
export POOL_SWAP_TEST="0xB8b53649b87F0e1eb3923305490a5cB288083f82"
 # TODO: these contracts below might need to be redeployed on every pool initialization
export SETH_ADDRESS="0x43616E6DD5e344f7F5c8591e15abEd5b004d72bd"
export SUSDC_ADDRESS="0x7714de3399A9daDFa46Cc196E0373FB09b2c2436"
export HOOK_ADDRESS="0xcA1e061b4d27EeF981b97D704542B883a089e080"

# Run the Forge script with the specified RPC URL
forge script ../script/Swap.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
