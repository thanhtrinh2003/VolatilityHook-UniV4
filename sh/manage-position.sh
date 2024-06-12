#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -x  # Print commands and their arguments as they are executed

# Source the environment variables from .env file
source ../.env

# Export the necessary addresses as environment variables, to be used by the script
# Sepolia Pool Manager address
export POOLMANAGER="0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14"
export LPROUTER_ADDRESS="0x2b925D1036E2E17F79CF9bB44ef91B95a3f9a084"
 # TODO: these contracts below might need to be redeployed on every pool initialization
export SETH_ADDRESS="0x43616E6DD5e344f7F5c8591e15abEd5b004d72bd"
export SUSDC_ADDRESS="0x7714de3399A9daDFa46Cc196E0373FB09b2c2436"
export HOOK_ADDRESS="0x344778Db62D10706df880dAC7B0E680a01DF2080"

# Run the Forge script with the specified RPC URL
forge script ../script/AddLiquidity.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
