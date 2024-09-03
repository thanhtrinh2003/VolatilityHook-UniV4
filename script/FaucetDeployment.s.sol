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

contract FaucetDeployment is Script {
    using CurrencyLibrary for Currency;

    address constant SETH_ADDRESS = address(0x000D25621951a6C10F22377fef91df9a7Eb3042C);
    address constant SUSDC_ADDRESS = address(0xb3a9E7d346982164404949bB5647A1A7C44cC025);

    address deployer;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        // Deploy Faucet
        Faucet faucet = new Faucet(SETH_ADDRESS, SUSDC_ADDRESS);
        IERC20(SETH_ADDRESS).transfer(address(faucet), IERC20(SETH_ADDRESS).balanceOf(deployer) - 100e18);
        IERC20(SUSDC_ADDRESS).transfer(address(faucet), IERC20(SUSDC_ADDRESS).balanceOf(deployer) - 100e18);
    }
}
