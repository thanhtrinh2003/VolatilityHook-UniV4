// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {PoolModifyLiquidityTest} from "@v4-core/test/PoolModifyLiquidityTest.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "@v4-core/PoolManager.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@v4-core/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@v4-core/types/PoolId.sol";
import {Faucet} from "contracts/Faucet.sol";

contract FaucetScript is Script {
    using CurrencyLibrary for Currency;

    address constant SETH_ADDRESS = address(0x5c2143dA3071627568aB1FA146E688B4B000Bb05); 
    address constant SUSDC_ADDRESS = address(0xC056fd4dD61d1647996Fa8eE076E34113B43E952); 

    address deployer;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        address token0 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SUSDC_ADDRESS : SETH_ADDRESS;
        address token1 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SETH_ADDRESS : SUSDC_ADDRESS;

        // Deploy Faucet
        Faucet faucet = new Faucet();

        // // approve tokens to the LP Router
        // IERC20(token0).transfer(address(faucet), IERC20(token0).balanceOf(address(deployer))*80/100);
        // IERC20(token1).transfer(address(faucet), IERC20(token1).balanceOf(address(deployer))*80/100);
    }
}