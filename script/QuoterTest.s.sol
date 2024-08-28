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
import {QuoterWrapper} from "contracts/QuoterWrapper.sol";
import {Faucet} from "contracts/Faucet.sol";
import {Quoter} from "@v4-periphery/lens/Quoter.sol";
import {IQuoter} from "@v4-periphery/interfaces/IQuoter.sol";

contract QuoterTest is Script {
    using CurrencyLibrary for Currency;

    address poolManager = 0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14;
    Quoter quoter = Quoter(0x52f09Df7814BF3274812785b9fb249020e7412d0);

    address hook = 0x01acEbd7a1117b3D52C6089D9df296F323D12080;
    address SETH_ADDRESS = 0xCAf4d4a10Ff8D5A1f6B45f6956F037F1A4E99356;
    address SUSDC_ADDRESS = 0xDbAbbF55373421fb029c9E7394F4a4FE5d47D698;
    address deployer;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        QuoterWrapper quoterWrapper = new QuoterWrapper(address(quoter), SETH_ADDRESS, SUSDC_ADDRESS, hook);

        address token0 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SUSDC_ADDRESS : SETH_ADDRESS;
        address token1 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SETH_ADDRESS : SUSDC_ADDRESS;

        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 0x800000,
            tickSpacing: 60,
            hooks: IHooks(hook)
        });

        // ______________________________________________
        IQuoter.QuoteExactSingleParams memory  param = IQuoter.QuoteExactSingleParams({
            poolKey: pool,
            zeroForOne: true,
            recipient: address(this),
            exactAmount: 1e18,
            sqrtPriceLimitX96: 4295128740,
            hookData: ""
        });

        (int128[] memory deltaAmounts, uint160 sqrtPriceX96After, uint32 initializedTicksLoaded) = quoter.quoteExactInputSingle(param);
        
        console.log(token0);

        console.log("_____quoteExactInputSingle_____");
        console.log(uint(int256(deltaAmounts[0])));  
        console.log(uint(-int256(deltaAmounts[1])));  
        console.log("sqrtPriceX96After: ", sqrtPriceX96After);
        console.log("initializedTicksLoaded: ", initializedTicksLoaded);


        (deltaAmounts,  sqrtPriceX96After,  initializedTicksLoaded) = quoter.quoteExactOutputSingle(param);
        
        console.log("_____quoteExactOutputSingle_____");
        console.log(uint(int256(deltaAmounts[0])));  
        console.log(uint(-int256(deltaAmounts[1])));  
        console.log("sqrtPriceX96After: ", sqrtPriceX96After);
        console.log("initializedTicksLoaded: ", initializedTicksLoaded);

        param = IQuoter.QuoteExactSingleParams({
            poolKey: pool,
            zeroForOne: false,
            recipient: address(this),
            exactAmount: 3100e18,
            sqrtPriceLimitX96: 5819260982861451012142998631604,
            hookData: ""
        });

        (deltaAmounts,  sqrtPriceX96After,  initializedTicksLoaded) = quoter.quoteExactInputSingle(param);
        
        console.log("_____quoteExactInputSingle_____");
        console.log(uint(-int256(deltaAmounts[0])));  
        console.log(uint(int256(deltaAmounts[1])));  
        console.log("sqrtPriceX96After: ", sqrtPriceX96After);
        console.log("initializedTicksLoaded: ", initializedTicksLoaded);

        (deltaAmounts,  sqrtPriceX96After,  initializedTicksLoaded) = quoter.quoteExactOutputSingle(param);

        console.log("_____quoteExactOutputSingle_____");
        console.log(uint(-int256(deltaAmounts[0])));  
        console.log(uint(int256(deltaAmounts[1])));  
        console.log("sqrtPriceX96After: ", sqrtPriceX96After);
        console.log("initializedTicksLoaded: ", initializedTicksLoaded);
    

       

        


    }
}