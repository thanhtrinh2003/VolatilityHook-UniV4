pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {Currency, CurrencyLibrary} from "@v4-core/types/Currency.sol";
import {LPFeeLibrary} from "@v4-core/libraries/LPFeeLibrary.sol";
import {Hooks} from "@v4-core/libraries/Hooks.sol";
import {PoolSwapTest} from "@v4-core/test/PoolSwapTest.sol";
import {TickMath} from "@v4-core/libraries/TickMath.sol";
import {OracleBasedFeeHook} from "../src/OracleBasedFeeHook.sol";
import {OracleBasedFeeHookImp} from "./implementation/OracleBasedFeeHookImp.sol";
import {FeeOracle} from "../src/FeeOracle.sol";
import {HookMiner} from "./utils/HookMiner.sol";

import {console} from "forge-std/console.sol";


contract TestOracleBasedFeeHook is Test, Deployers {
    using CurrencyLibrary for Currency;

    OracleBasedFeeHook hook;

    FeeOracle oracle;

    address oracleOwner = address(1);

    function setUp() public {
        // Deploy v4-cores
        deployFreshManagerAndRouters();

        // Deploy, mint tokens, and approve all periphery contracts for two tokens
        (currency0, currency1) = deployMintAndApprove2Currencies();

        // Deploy our hook
        hook = OracleBasedFeeHook(address(uint160(Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG)));
        
        // Deploy our oracle
        oracle = new FeeOracle(oracleOwner);

        // // Deploy our hook with proper flags - Normal way
        // uint160 flags = uint160(
        //     Hooks.BEFORE_INITIALIZE_FLAG |  
        //     Hooks.BEFORE_SWAP_FLAG
        // );

        // (, bytes32 salt) = HookMiner.find(
        //     address(this),
        //     flags,
        //     0,
        //     type(OracleBasedFeeHook).creationCode,
        //     abi.encodePacked(manager, address(oracle))
        // );            
        
        // hook = new OracleBasedFeeHook{salt: salt}(manager, address(oracle));

        // Deploy our hook in testing environment using etch, so that we dont need to find an address to fit the flag

        OracleBasedFeeHookImp hookImp = new OracleBasedFeeHookImp(manager, hook, address(oracle));
        (, bytes32[] memory writes) = vm.accesses(address(hookImp));
        vm.etch(address(hook), address(hookImp).code);

        unchecked {
            for (uint256 i = 0; i < writes.length; i++) {
                bytes32 slot = writes[i];
                vm.store(address(hook), slot, vm.load(address(hookImp), slot));
            }
        }

        // Set up the oracle - Just in testing environment
        hoax(hook.owner(), hook.owner());
        hook.setFeeOracle(address(oracle));

        console.log("Implementation Fee Oracle: ", hookImp.getFeeOracle());
        console.log("Hook Fee Oracle: ", hook.getFeeOracle());

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

        //label contract
        vm.label(address(hook), "OracleBasedFeeHook");
        vm.label(address(oracle), "FeeOracle");
    }

    function test_feeUpdated() public {
        // Set up swap parameters
        PoolSwapTest.TestSettings memory testSettings = PoolSwapTest.TestSettings({
            takeClaims : false, 
            settleUsingBurn : false
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: -0.00001 ether,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
        });

        // 0: Conduct a swap when oracle set fee at 0
        console.log("Case 1: Conduct a swap when oracle set fee at 0.5% `(5000`)");

        hoax(oracleOwner, oracleOwner);
        oracle.setFee(0);

        uint256 balanceOfToken1Before = currency1.balanceOfSelf();
        swapRouter.swap(key, params, testSettings, ZERO_BYTES);
        uint256 balanceOfToken1After = currency1.balanceOfSelf();
        uint256 outputFromFeeSwap = balanceOfToken1After - balanceOfToken1Before;

        console.log("Balance of token1 before swap: ", balanceOfToken1Before);
        console.log("Balance of token1 after swap: ", balanceOfToken1After);

        assertGt(balanceOfToken1After, balanceOfToken1Before);
        console.log("Output from fee swap: ", outputFromFeeSwap);

        // 1: Conduct a swap when oracle set fee at 0.5% (5000)
        console.log("Case 1: Conduct a swap when oracle set fee at 0.5% `(5000`)");

        hoax(oracleOwner, oracleOwner);
        oracle.setFee(5000);

        balanceOfToken1Before = currency1.balanceOfSelf();
        swapRouter.swap(key, params, testSettings, ZERO_BYTES);
        balanceOfToken1After = currency1.balanceOfSelf();
        outputFromFeeSwap = balanceOfToken1After - balanceOfToken1Before;

        console.log("Balance of token1 before swap: ", balanceOfToken1Before);
        console.log("Balance of token1 after swap: ", balanceOfToken1After);

        assertGt(balanceOfToken1After, balanceOfToken1Before);
        console.log("Output from fee swap: ", outputFromFeeSwap);
    }

}