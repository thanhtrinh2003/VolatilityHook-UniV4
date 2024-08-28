pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {Currency, CurrencyLibrary} from "@v4-core/types/Currency.sol";
import {LPFeeLibrary} from "@v4-core/libraries/LPFeeLibrary.sol";
import {Hooks} from "@v4-core/libraries/Hooks.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@v4-core/types/PoolId.sol";
import {PoolSwapTest} from "@v4-core/test/PoolSwapTest.sol";
import {TickMath} from "@v4-core/libraries/TickMath.sol";
import {OracleBasedFeeHook} from "../src/OracleBasedFeeHook.sol";
import {OracleBasedFeeHookImp} from "./implementation/OracleBasedFeeHookImp.sol";
import {SnarkBasedVolatilityOracle} from "../src/SnarkBasedVolatilityOracle.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {HookMiner} from "contracts/utils/HookMiner.sol";
import {BalanceDelta} from "@v4-core/types/BalanceDelta.sol";
import {CalcFeeLib} from "../src/Calc/CalcFeeLib.sol";
import {QuoterWrapper} from "contracts/QuoterWrapper.sol";
import {Quoter} from "@v4-periphery/lens/Quoter.sol";
import {IQuoter} from "@v4-periphery/interfaces/IQuoter.sol";
import {console} from "forge-std/console.sol";

contract TestQuoter is Test {
    Quoter quoter;
    QuoterWrapper quoterWrapper;

    IPoolManager poolManager = IPoolManager(0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14);
    PoolSwapTest swapRouter = PoolSwapTest(0xB8b53649b87F0e1eb3923305490a5cB288083f82);

    address hook = 0xB7d34aa3AF1BE6Be2Adf1af3E4e179867cf9e080;
    address SETH_ADDRESS = 0x000D25621951a6C10F22377fef91df9a7Eb3042C;
    address SUSDC_ADDRESS = 0xb3a9E7d346982164404949bB5647A1A7C44cC025;

    function setUp() public {
        // Choose Fork
        vm.createSelectFork("https://sepolia.gateway.tenderly.co", 6418636);

        // Deploy Quoter
        quoter = Quoter(0x52f09Df7814BF3274812785b9fb249020e7412d0);
        quoterWrapper = new QuoterWrapper(address(quoter), SETH_ADDRESS, SUSDC_ADDRESS, hook);
        
    }

    function testQuoter() public {
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

         //QUOTER WRAPPER
        console.log("_________________Wrapper_________________________");
        (uint amountIn, uint sqrtPrice) = quoterWrapper.getOutputAmount(0, 1e18);
        console.log("Amount in: ",amountIn/1e18);
        console.log("Sqrt Price After: ", sqrtPrice);

        (amountIn, sqrtPrice) = quoterWrapper.getOutputAmount(1, 3600e18);
        console.log("Amount in: ",amountIn/1e18);
        console.log("Sqrt Price After: ", sqrtPrice);

        (amountIn, sqrtPrice) = quoterWrapper.getInputAmount(0, 3600e18);
        console.log("Amount in: ",amountIn/1e18);
        console.log("Sqrt Price After: ", sqrtPrice);

        (amountIn, sqrtPrice) = quoterWrapper.getInputAmount(1, 1e18);
        console.log("Amount in: ",amountIn/1e18);
        console.log("Sqrt Price After: ", sqrtPrice);
    
    }
}
