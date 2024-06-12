#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -x  # Print commands and their arguments as they are executed

# Source the environment variables from .env file
source ../.env

# Export the necessary addresses as environment variables, to be used by the script
# Sepolia Pool Manager address
 # TODO: these contracts below might need to be redeployed on every pool initialization
export FEE_ORACLE="0x0DCC248cDb4212F6f7234c1C58d41c55c164CfA5"

# Run the Forge script with the specified RPC URL
forge script ../script/setFee.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
