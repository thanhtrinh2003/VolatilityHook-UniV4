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
import {stdJson} from "forge-std/StdJson.sol";
import {HookMiner} from "contracts/utils/HookMiner.sol";
import {BalanceDelta} from "@v4-core/types/BalanceDelta.sol";
import {CalcFeeLib} from "../src/Calc/CalcFeeLib.sol";
import {PricePoolManager} from "../src/PricePoolManager.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {console} from "forge-std/console.sol";

contract TestPricePoolManager is Test {
    IPoolManager public poolManager;
    PoolSwapTest public swapRouter;
    PoolModifyLiquidityTest public liquidityRouter;
    ERC20 public seth;
    ERC20 public susdc;

    address hookAddr;
    address poolManagerAddr;
    address swapRouterAddr;
    address liquidityRouterAddr;
    address sethAddr;
    address susdcAddr;

    function setUp() public {
        // Choose Fork
        vm.createSelectFork("https://sepolia.gateway.tenderly.co");

        // Set up Address
        hookAddr = vm.envAddress("HOOK_ADDRESS");
        poolManagerAddr = vm.envAddress("POOL_MANAGER_ADDRESS");
        swapRouterAddr = vm.envAddress("SWAP_ROUTER_ADDRESS");
        liquidityRouterAddr = vm.envAddress("LIQUIDITY_ROUTER_ADDRESS");
        sethAddr = vm.envAddress("SETH_ADDRESS");
        susdcAddr = vm.envAddress("SUSDC_ADDRESS");

        // Set up Contract
        poolManager = IPoolManager(poolManagerAddr);
        swapRouter = PoolSwapTest(swapRouterAddr);
        liquidityRouter = PoolModifyLiquidityTest(liquidityRouterAddr);
        seth = ERC20(sethAddr);
        susdc = ERC20(susdcAddr);

        console.log("Hook:", hookAddr);

        // Deploy Price Pool Manager
        PricePoolManager pricePoolManager =
            new PricePoolManager(poolManagerAddr, liquidityRouterAddr, hookAddr, oracleAddr, sethAddr, susdcAddr);
    }

    function testGetLiquidity() public {
        //Get Current Liquidity
    }
}
