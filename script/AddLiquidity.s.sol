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

    // address constant POOLMANAGER = address(0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14);
    // address constant SETH_ADDRESS = address(0x8B392a9bc80c61B700aa7965Af237b60342B21e2);
    // address constant SUSDC_ADDRESS = address(0x8995D3DAA51AF4C3Ab0221Bc9Ac890694720A0e2);
    // address constant HOOK_ADDRESS = address(0x344778Db62D10706df880dAC7B0E680a01DF2080);

    address constant POOLMANAGER = address(0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14);
    address constant SETH_ADDRESS = address(0xcff8733a17a0e5Dbb22D36AdEB806F2E63879858);
    address constant SUSDC_ADDRESS = address(0x6C1234d626C98138fAE37742Dd5B08F43FbA9475);
    address constant HOOK_ADDRESS = address(0x344778Db62D10706df880dAC7B0E680a01DF2080);

    IPoolManager manager = IPoolManager(POOLMANAGER);
    PoolModifyLiquidityTest lpRouter = PoolModifyLiquidityTest(address(0x2b925D1036E2E17F79CF9bB44ef91B95a3f9a084));

    address deployer;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        address token0 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SUSDC_ADDRESS : SETH_ADDRESS;
        address token1 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SETH_ADDRESS : SUSDC_ADDRESS;

        uint24 swapFee = 0x800000;
        int24 tickSpacing = 10;

        uint160 startingPrice = 79228162514264337593543950336;

        PoolKey memory pool = PoolKey({
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
        PoolId id = PoolIdLibrary.toId(pool);
        bytes32 idBytes = PoolId.unwrap(id);
        console.log("Pool ID Below");
        console.logBytes32(bytes32(idBytes));

        //Create pool
        manager.initialize(pool, startingPrice, hookData);

        // Provide 10_000e18 worth of liquidity on the range of [-600, 600]
        lpRouter.modifyLiquidity(pool, IPoolManager.ModifyLiquidityParams(-600, 600, 1000e18, 0), hookData);
    }
}
