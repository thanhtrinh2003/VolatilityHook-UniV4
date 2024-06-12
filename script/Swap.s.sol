// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {PoolSwapTest} from "@v4-core/test/PoolSwapTest.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "@v4-core/PoolManager.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@v4-core/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@v4-core/types/PoolId.sol";
import {TickMath} from "@v4-core/libraries/TickMath.sol";


contract SwapScript is Script {
    // PoolSwapTest Contract address on Goerli
    PoolSwapTest swapRouter;


    // slippage tolerance to allow for unlimited price impact
    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_PRICE + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_PRICE - 1;

    address deployer;

    function run() external {
        address SETH_ADDRESS = vm.envAddress("SETH_ADDRESS");
        address SUSDC_ADDRESS = vm.envAddress("SUSDC_ADDRESS");
        address HOOK_ADDRESS = vm.envAddress("HOOK_ADDRESS");
       swapRouter = PoolSwapTest(vm.envAddress("POOL_SWAP_TEST"));

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);




        address token0 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SUSDC_ADDRESS : SETH_ADDRESS;
        address token1 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SETH_ADDRESS : SUSDC_ADDRESS;
        uint24 swapFee = 0x800000;
        int24 tickSpacing = 600;


        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: swapFee,
            tickSpacing: tickSpacing,
            hooks: IHooks(HOOK_ADDRESS)
        });

        // logs the pool id
        PoolId id = PoolIdLibrary.toId(key);
        bytes32 idBytes = PoolId.unwrap(id);
        console.log("Pool ID Below");
        console.logBytes32(bytes32(idBytes));


        // approve tokens to the swap router
        IERC20(token0).approve(address(swapRouter), type(uint256).max);
        IERC20(token1).approve(address(swapRouter), type(uint256).max);

        // ---------------------------- //
        // Swap 100e18 token0 into token1 //
        // ---------------------------- //
        bool zeroForOne = true;
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: 1e18,
            sqrtPriceLimitX96: zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT // unlimited impact
        });

        // in v4, users have the option to receieve native ERC20s or wrapped ERC1155 tokens
        // here, we'll take the ERC20s
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        bytes memory hookData = new bytes(0);
        swapRouter.swap(key, params, testSettings, hookData);
    }
}