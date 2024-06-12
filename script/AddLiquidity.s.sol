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

contract AddLiquidityScript is Script {
    using CurrencyLibrary for Currency;

    IPoolManager manager;
    PoolModifyLiquidityTest lpRouter;

    address deployer;

    function run() external {
        address POOLMANAGER = vm.envAddress("POOLMANAGER");
        address SETH_ADDRESS = vm.envAddress("SETH_ADDRESS");
        address SUSDC_ADDRESS = vm.envAddress("SUSDC_ADDRESS");
        address HOOK_ADDRESS = vm.envAddress("HOOK_ADDRESS");
        address LPROUTER_ADDRESS = vm.envAddress("LPROUTER_ADDRESS");
        manager = IPoolManager(POOLMANAGER);
        lpRouter = PoolModifyLiquidityTest(LPROUTER_ADDRESS);


        console.log("lp router manager: ");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        address token0 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SUSDC_ADDRESS : SETH_ADDRESS;
        address token1 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SETH_ADDRESS : SUSDC_ADDRESS;
        
        uint24 swapFee = 0x800000;
        int24 tickSpacing = 600;

        uint160 startingPrice = 79228162514264337593543950336;

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: swapFee,
            tickSpacing: tickSpacing,
            hooks: IHooks(HOOK_ADDRESS)
        });

        // approve tokens to the LP Router
        IERC20(token0).approve(address(lpRouter), 1000e18);
        IERC20(token1).approve(address(lpRouter), 1000e18);

        // optionally specify hookData if the hook depends on arbitrary data for liquidity modification
        bytes memory hookData = new bytes(0);

        // logging the pool ID
        PoolId id = PoolIdLibrary.toId(key);
        bytes32 idBytes = PoolId.unwrap(id);
        console.log("Pool ID Below");
        console.logBytes32(bytes32(idBytes));

        //Create pool
        manager.initialize(key, startingPrice, hookData);

        // Provide 10_000e18 worth of liquidity on the range of [-600, 600]
        lpRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-600, 600, 1000e18, 0), hookData);
    }
}