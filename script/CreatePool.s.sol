// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "@v4-core/PoolManager.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@v4-core/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@v4-core/types/PoolId.sol";

contract CreatePoolScript is Script {
    using CurrencyLibrary for Currency;

    //addresses with contracts deployed
    address constant POOLMANAGER = address(0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14); 
    address constant SETH_ADDRESS = address(0xcff8733a17a0e5Dbb22D36AdEB806F2E63879858); 
    address constant SUSDC_ADDRESS = address(0x6C1234d626C98138fAE37742Dd5B08F43FbA9475); 
    address constant HOOK_ADDRESS = address(0x344778Db62D10706df880dAC7B0E680a01DF2080); 
    
    IPoolManager manager = IPoolManager(POOLMANAGER);

    function run() external {
        // sort the tokens!
        address token0 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SUSDC_ADDRESS : SETH_ADDRESS;
        address token1 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SETH_ADDRESS : SUSDC_ADDRESS;
        uint24 swapFee = 0x800000;
        int24 tickSpacing = 10;

        // floor(sqrt(1) * 2^96)
        uint160 startingPrice = 79228162514264337593543950336;

        bytes memory hookData = abi.encode(block.timestamp);

        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: swapFee,
            tickSpacing: tickSpacing,
            hooks: IHooks(HOOK_ADDRESS)
        });

        // Turn the Pool into an ID so you can use it for modifying positions, swapping, etc.
        PoolId id = PoolIdLibrary.toId(pool);
        bytes32 idBytes = PoolId.unwrap(id);

        console.log("Pool ID Below");
        console.logBytes32(bytes32(idBytes));

        vm.broadcast();
        manager.initialize(pool, startingPrice, hookData);
    }
}