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
import {PoolModifyLiquidityTest} from "@v4-core/test/PoolModifyLiquidityTest.sol";
import {TickMath} from "@v4-core/libraries/TickMath.sol";
import {OracleBasedFeeHook} from "../src/OracleBasedFeeHook.sol";
import {OracleBasedFeeHookImp} from "./implementation/OracleBasedFeeHookImp.sol";
import {LiquidityAmounts} from "@v4-periphery/libraries/LiquidityAmounts.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {StateLibrary} from "@v4-core/libraries/StateLibrary.sol";
import {HookMiner} from "contracts/utils/HookMiner.sol";
import {BalanceDelta} from "@v4-core/types/BalanceDelta.sol";
import {SafeCast} from "@v4-core/libraries/SafeCast.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {FullMath} from "@v4-core/libraries/FullMath.sol";
import {CalcFeeLib} from "../src/Calc/CalcFeeLib.sol";
import {PricePoolManager} from "../src/PricePoolManager.sol";
import {IChainlinkOracle} from "../src/interfaces/IChainlinkOracle.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {console} from "forge-std/console.sol";

contract TestPricePoolManager is Test {
    using CurrencyLibrary for Currency;
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using FixedPointMathLib for uint256;
    using FullMath for uint256;

    IPoolManager public poolManager;
    PoolSwapTest public swapRouter;
    PoolModifyLiquidityTest public liquidityRouter;
    IChainlinkOracle public oracle;
    PricePoolManager public pricePoolManager;
    PoolKey public poolKey;

    ERC20 public seth;
    ERC20 public susdc;
    address public token0;
    address public token1;

    address hookAddr;
    address poolManagerAddr;
    address swapRouterAddr;
    address liquidityRouterAddr;
    address sethAddr;
    address susdcAddr;
    address oracleAddr;

    int24 public constant MIN_TICK = -887272;
    int24 public constant MAX_TICK = 887272;
    uint24 public constant SWAP_FEE = 0x800000;
    int24 public constant TICK_SPACING = 60;

    address dev = 0x32ac74279777aB4E4885f1deF2ED09D78048081C;

    function setUp() public {
        // Choose Fork
        vm.createSelectFork("https://sepolia.gateway.tenderly.co");

        // Set up Address
        hookAddr = vm.envAddress("HOOK_ADDRESS");
        poolManagerAddr = vm.envAddress("POOL_MANAGER_ADDRESS");
        oracleAddr = vm.envAddress("ORACLE_ADDRESS");
        swapRouterAddr = vm.envAddress("POOLSWAPTEST_ADDRESS");
        liquidityRouterAddr = vm.envAddress("LIQUIDITY_ROUTER_ADDRESS");
        sethAddr = vm.envAddress("SETH_ADDRESS");
        susdcAddr = vm.envAddress("SUSDC_ADDRESS");

        // Set up Contract
        poolManager = IPoolManager(poolManagerAddr);
        swapRouter = PoolSwapTest(swapRouterAddr);
        liquidityRouter = PoolModifyLiquidityTest(liquidityRouterAddr);

        // Set Up Tokens
        seth = ERC20(sethAddr);
        susdc = ERC20(susdcAddr);
        token0 = uint160(susdcAddr) < uint160(sethAddr) ? susdcAddr : sethAddr;
        token1 = uint160(susdcAddr) < uint160(sethAddr) ? sethAddr : susdcAddr;

        console.log("Hook:", hookAddr);

        // Set Up Current Pool Key
        poolKey = PoolKey({
            currency0: Currency.wrap(susdcAddr),
            currency1: Currency.wrap(sethAddr),
            fee: SWAP_FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(hookAddr)
        });

        // Deploy Price Pool Manager
        pricePoolManager =
            new PricePoolManager(poolManagerAddr, liquidityRouterAddr, hookAddr, oracleAddr, sethAddr, susdcAddr);
    }

    function testGetLiquidity() public {
        // User Balance of sETH and sUSDC
        uint256 userBalance = ERC20(sethAddr).balanceOf(address(pricePoolManager));
        console.log("User Balance of sETH:", userBalance);
        userBalance = ERC20(susdcAddr).balanceOf(address(pricePoolManager));
        console.log("User Balance of sUSDC:", userBalance);

        // Get Pool Current SqrtX96 Price
        PoolId poolId = poolKey.toId();
        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(poolId);

        // Get Pool Balance of sETH and sUSDC
        uint256 token0Amount = ERC20(token0).balanceOf(address(poolManager));
        uint256 token1Amount = ERC20(token1).balanceOf(address(poolManager));

        // Get Current Liquidity
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(MIN_TICK),
            TickMath.getSqrtPriceAtTick(MAX_TICK),
            token0Amount,
            token1Amount
        );

        console.log("Liquidity:", liquidity);

        // Withdraw Liquidity from Old Pool
        IPoolManager.ModifyLiquidityParams memory param =
            IPoolManager.ModifyLiquidityParams(MIN_TICK, MAX_TICK, -(liquidity.toInt256()), 0);

        hoax(dev, dev);
        liquidityRouter.modifyLiquidity(poolKey, param, new bytes(0));

        // User Balance of sETH and sUSDC
        userBalance = ERC20(sethAddr).balanceOf(address(pricePoolManager));
        console.log("User Balance of sETH:", userBalance);
        userBalance = ERC20(susdcAddr).balanceOf(address(pricePoolManager));
        console.log("User Balance of sUSDC:", userBalance);
    }
}
