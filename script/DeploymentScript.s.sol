// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "@v4-core/PoolManager.sol";
import {PoolSwapTest} from "@v4-core/test/PoolSwapTest.sol";
import {PoolModifyLiquidityTest} from "@v4-core/test/PoolModifyLiquidityTest.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "contracts/utils/HookMiner.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@v4-core/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@v4-core/types/PoolId.sol";

import {SemioticsUSDC} from "./mocks/SemioticsUSDC.sol";
import {SemioticsETH} from "./mocks/SemioticsETH.sol";
import {RvVerifier} from "src/RvVerifier.sol";
import {Faucet} from "src/Faucet.sol";
import {SnarkBasedVolatilityOracle} from "src/SnarkBasedVolatilityOracle.sol";
import {OracleBasedFeeHook} from "src/OracleBasedFeeHook.sol";

import {CalcFeeLib} from "src/Calc/CalcFeeLib.sol";

contract DeploymentScript is Script {
    using CurrencyLibrary for Currency;

    address create2 = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    IPoolManager poolManager = IPoolManager(0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14);
    PoolSwapTest swapRouter = PoolSwapTest(0xB8b53649b87F0e1eb3923305490a5cB288083f82);
    PoolModifyLiquidityTest lpRouter = PoolModifyLiquidityTest(0x2b925D1036E2E17F79CF9bB44ef91B95a3f9a084);

    address deployer;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        //________________________________ Deploy Tokens _________________________________________//
        SemioticsUSDC usdc = new SemioticsUSDC();
        SemioticsETH eth = new SemioticsETH();

        address SETH_ADDRESS = address(eth);
        address SUSDC_ADDRESS = address(usdc);

        //________________________________ Deploy Verifier/Oracle ________________________________//
        bytes32 programKey = 0x00dc70908ac47157cd47feacd62a458f405707ffbcea526fcd5620aedd5d828d;
        SnarkBasedVolatilityOracle oracle = new SnarkBasedVolatilityOracle(programKey);
        CalcFeeLib calcLib = new CalcFeeLib(address(oracle));

        console.log("here");

        //________________________________ Deploy Hook ___________________________________________//
        uint160 flags = uint160(Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG);

        (, bytes32 salt) = HookMiner.find(
            create2,
            flags,
            type(OracleBasedFeeHook).creationCode,
            abi.encode(IPoolManager(poolManager), address(calcLib))
        );

        OracleBasedFeeHook hook = new OracleBasedFeeHook{salt: salt}(IPoolManager(poolManager), address(calcLib));

        //________________________________ Modifying Pool ___________________________________________//
        address token0 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SUSDC_ADDRESS : SETH_ADDRESS;
        address token1 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SETH_ADDRESS : SUSDC_ADDRESS;

        uint24 swapFee = 0x800000;
        int24 tickSpacing = 60;

        uint160 startingPrice = 4411237397794263893240602165248;

        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: swapFee,
            tickSpacing: tickSpacing,
            hooks: IHooks(hook)
        });

        IERC20(token0).approve(address(poolManager), type(uint256).max);
        IERC20(token1).approve(address(poolManager), type(uint256).max);

        // approve tokens to the LP Router
        IERC20(token0).approve(address(lpRouter), type(uint256).max);
        IERC20(token1).approve(address(lpRouter), type(uint256).max);

        // optionally specify hookData if the hook depends on arbitrary data for liquidity modification
        bytes memory hookData = new bytes(0);

        // logging the pool ID
        PoolId id = PoolIdLibrary.toId(pool);
        bytes32 idBytes = PoolId.unwrap(id);
        console.log("Pool ID Below");
        console.logBytes32(bytes32(idBytes));

        //Create pool
        poolManager.initialize(pool, startingPrice, hookData);

        // Provide 10_000e18 worth of liquidity on the range of [-600, 600]
        lpRouter.modifyLiquidity(pool, IPoolManager.ModifyLiquidityParams(-887220, 887220, 10000000e18, 0), hookData);

        //________________________________ Test Swap Addresses _________________________________________//

        // approve tokens to the swap router
        IERC20(token0).approve(address(swapRouter), type(uint256).max);
        IERC20(token1).approve(address(swapRouter), type(uint256).max);

        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        //Swap 1e18 token0 into token1 params
        IPoolManager.SwapParams memory params_0 =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: -1e18, sqrtPriceLimitX96: 4295128740});

        swapRouter.swap(pool, params_0, testSettings, hookData);

        //Swap 3100 into token1 params
        IPoolManager.SwapParams memory params_1 = IPoolManager.SwapParams({
            zeroForOne: false,
            amountSpecified: -3600e18,
            sqrtPriceLimitX96: 5819260982861451012142998631604
        });

        swapRouter.swap(pool, params_1, testSettings, hookData);

        //________________________________ Faucet Deployment ___________________________________________//
        // Faucet faucet = new Faucet(SETH_ADDRESS, SUSDC_ADDRESS);
        // IERC20(SETH_ADDRESS).transfer(address(faucet), IERC20(SETH_ADDRESS).balanceOf(deployer));
        // IERC20(SUSDC_ADDRESS).transfer(address(faucet), IERC20(SUSDC_ADDRESS).balanceOf(deployer));
        
    }
}
