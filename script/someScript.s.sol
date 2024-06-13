// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {PoolSwapTest} from "@v4-core/test/PoolSwapTest.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "@v4-core/PoolManager.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@v4-core/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@v4-core/types/PoolId.sol";
import {TickMath} from "@v4-core/libraries/TickMath.sol";


contract SomeScript is Script {
    // PoolSwapTest Contract address on Goerli
    PoolSwapTest swapRouter = PoolSwapTest(0xB8b53649b87F0e1eb3923305490a5cB288083f82);

    address constant POOLMANAGER = address(0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14); 
    address constant SETH_ADDRESS = address(0x5c2143dA3071627568aB1FA146E688B4B000Bb05); 
    address constant SUSDC_ADDRESS = address(0xC056fd4dD61d1647996Fa8eE076E34113B43E952); 
    address constant HOOK_ADDRESS = address(0x344778Db62D10706df880dAC7B0E680a01DF2080); 

    // slippage tolerance to allow for unlimited price impact
    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_PRICE + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_PRICE - 1;

    address deployer;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        address token0 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SUSDC_ADDRESS : SETH_ADDRESS;
        address token1 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SETH_ADDRESS : SUSDC_ADDRESS;

        // send tokens to the pp
        IERC20(token0).transfer(0x290AAE5e725e98Af06B01Bd91aff5E1Eb84E4D4B, 5e18);
        IERC20(token1).transfer(0x290AAE5e725e98Af06B01Bd91aff5E1Eb84E4D4B, 5e18);
    }
}