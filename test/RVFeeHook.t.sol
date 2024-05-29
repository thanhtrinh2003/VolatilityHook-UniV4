pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {Currency, CurrencyLibrary} from "@v4-core/types/Currency.sol";
import {LPFeeLibrary} from "@v4-core/libraries/LPFeeLibrary.sol";
import {Hooks} from "@v4-core/libraries/Hooks.sol";
import {PoolSwapTest} from "@v4-core/test/PoolSwapTest.sol";
import {TickMath} from "@v4-core/libraries/TickMath.sol";
import {RVFeeHook} from "../src/RVFeeHook.sol";
import {FeeOracle} from "../src/FeeOracle.sol";
import {HookMiner} from "./utils/HookMiner.sol";

import {console} from "forge-std/console.sol";


contract TestRVFeeHook is Test, Deployers {
    using CurrencyLibrary for Currency;

    RVFeeHook hook;

    FeeOracle oracle;

    address oracleOwner = address(0x1);

    function setUp() public {
        // Deploy v4-cores
        deployFreshManagerAndRouters();

        // Deploy, mint tokens, and approve all periphery contracts for two tokens
        (currency0, currency1) = deployMintAndApprove2Currencies();

        // Deploy our oracle
        oracle = new FeeOracle(oracleOwner);

        //Deploy our hook with proper flags
        uint160 flags = uint160(
            Hooks.BEFORE_INITIALIZE_FLAG |  
            Hooks.BEFORE_SWAP_FLAG
        );

        (, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            0,
            type(RVFeeHook).creationCode,
            abi.encodePacked(manager, address(oracle))
        );            
        
        hook = new RVFeeHook{salt: salt}(manager, address(oracle));

        // Initialize a pool
        (key, ) = initPool(
            currency0, 
            currency1, 
            hook,
            LPFeeLibrary.DYNAMIC_FEE_FLAG, 
            SQRT_PRICE_1_1,
            ZERO_BYTES
        );

        // Add some liquidity
        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: 100 ether,
                salt: bytes32(0)
            }),
            ZERO_BYTES
        );
    }

    function test_feeUpdated() public {
        // Set up swap parameters
        PoolSwapTest.TestSettings memory testSettings = PoolSwapTest.TestSettings({
            takeClaims : true, 
            settleUsingBurn : true
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: -0.00001 ether,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
        });

        // 1: Conduct a swap when oracle set fee at 0.5% (5000)
        console.log("Case 1: Conduct a swap when oracle set fee at 0.5% `(5000`)");

        hoax(oracleOwner, oracleOwner);
        oracle.setFee(5000);

        uint256 balanceOfToken1Before = currency1.balanceOfSelf();
        swapRouter.swap(key, params, testSettings, ZERO_BYTES);
        uint256 balanceOfToken1After = currency1.balanceOfSelf();
        uint256 outputFromFeeSwap = balanceOfToken1After - balanceOfToken1Before;

        assertGt(balanceOfToken1After, balanceOfToken1Before);
        console.log("Output from fee swap: ", outputFromFeeSwap);
    }

}