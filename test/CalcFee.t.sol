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

library Math {
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

contract QuoterTest is Script {
    using CurrencyLibrary for Currency;
    using Math for uint256;

    address poolManager = 0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14;
    Quoter quoter = Quoter(0x52f09Df7814BF3274812785b9fb249020e7412d0);

    address hook = 0x01acEbd7a1117b3D52C6089D9df296F323D12080;
    address SETH_ADDRESS = 0xCAf4d4a10Ff8D5A1f6B45f6956F037F1A4E99356;
    address SUSDC_ADDRESS = 0xDbAbbF55373421fb029c9E7394F4a4FE5d47D698;
    address deployer;

    PoolKey public pool = PoolKey({
        currency0: Currency.wrap(token0),
        currency1: Currency.wrap(token1),
        fee: 0x800000,
        tickSpacing: 60,
        hooks: IHooks(hook)
    });

    function setUp() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        QuoterWrapper quoterWrapper = new QuoterWrapper(address(quoter), SETH_ADDRESS, SUSDC_ADDRESS, hook);

        address token0 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SUSDC_ADDRESS : SETH_ADDRESS;
        address token1 = uint160(SUSDC_ADDRESS) < uint160(SETH_ADDRESS) ? SETH_ADDRESS : SUSDC_ADDRESS;
    }

    function getSqrtPriceX96(uint256 normalPrice) private pure returns (uint256) {
        // Take the square root of the normal price
        uint256 sqrtPrice = normalPrice.sqrt();
        // Multiply by 2^96
        uint256 sqrtPriceX96 = sqrtPrice * (2 ** 96);

        return sqrtPriceX96;
    }

    function testFeeFromZeroForOne() public {
        uint256 _swapAmount = 1e18;
        uint256 _slippage = 20;
        uint160 _sqrtPriceX96 = getSqrtPriceX96(_swapAmount);
        uint160 _sqrtPriceX96Limit = _sqrtPriceX96 * (100 + _slippage) / 100; //Slippage 20%
        bool _zeroForOne = true;

        // ______________________________________________
        IPoolManager.SwapParams memory swapParam = IPoolManager.SwapParams({
            zeroForOne: _zeroForOne,
            amountSpecified: -_swapAmount,
            sqrtPriceLimitX96: _sqrtPriceX96Limit
        });

        IQuoter.QuoteExactSingleParams memory feeParam = IQuoter.QuoteExactSingleParams({
            poolKey: pool,
            zeroForOne: _zeroForOne,
            recipient: address(this),
            exactAmount: _swapAmount,
            sqrtPriceLimitX96: _sqrtPriceX96Limit,
            hookData: ""
        });

        uint256 sqrtPriceX96;
        (, sqrtPriceX96) = quoter.getOutputAmount(swapData.zeroForOne, swapData.amountSpecified);

        bytes memory feeData = abi.encode(abs(swapData.amountSpecified), sqrtPriceX96);
        uint24 fee = calcLib.getFee(feeData);
        console.log(fee);
    }
}
