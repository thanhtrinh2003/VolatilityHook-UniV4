## Volatility Hook for Uniswap V4

**Description**

This repo contains code for a votality v4-hook. 

## testing on Sepolia

There is a full deploy script to deploy the snark based verifier and usage in the `sh` folder. Setup the variables int he `.env.example` to use it.]
It currently only works for Sepolia testnet. The scripts are separated into a few, that have to be run in order:

-  `deploy-tokens.sh`, to deploy the mock sETH and sUSDC;
- `deploy-rv-hook.sh` to deploy the realized volatility hook;
- `manage-position.sh` to deploy and to modify liquidity in the deployed pool;
-   `initialize-pool.sh` to initialize a pool with the given pair deployed before;
-  `swap.sh` to run a swap. 

The minimal setup involves running in the following order:

1. `deploy-tokens.sh`, to deploy the mock sETH and sUSDC;
2. (OPTIONAL) `deploy-rv-hook.sh` to deploy the realized volatility hook;
3. Save the mock tokens in the `manage-position.sh` envs script and run it;
4. `swap.sh` to run a swap. 

Step 2 is optional because it is possible to reuse a previously deployed hook.

**Notice that all contract addresses from each section have to be set individually on each script before running them**.

For the `PoolManager`, `PoolSwapTest`  contracts on Sepolia testnet, we are using the ones [defined by uniswap here](https://uniswaphooks.com/chains). Except for the `LPROUTER_ADDRESS`, which was used instead `0x2b925D1036E2E17F79CF9bB44ef91B95a3f9a084`, and `POOL_SWAP_TEST`, which goes by `0xB8b53649b87F0e1eb3923305490a5cB288083f82`
