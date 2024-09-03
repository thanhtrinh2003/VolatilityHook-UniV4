// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseHook} from "@v4-periphery/BaseHook.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "@v4-core/libraries/Hooks.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {BalanceDelta} from "@v4-core/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@v4-core/types/BeforeSwapDelta.sol";
import {LPFeeLibrary} from "@v4-core/libraries/LPFeeLibrary.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IFeeOracle} from "./interfaces/IFeeOracle.sol";
import {SnarkBasedVolatilityOracle} from "./SnarkBasedVolatilityOracle.sol";
import {ICalcFee} from "./interfaces/ICalcFee.sol";
import {QuoterWrapper} from "./QuoterWrapper.sol";

contract OracleBasedFeeHook is BaseHook, Ownable {
    using LPFeeLibrary for uint24;

    uint256 public constant MIN_FEE = 1000;
    address DEV_WALLET = 0x32ac74279777aB4E4885f1deF2ED09D78048081C;

    error MustUseDynamicFee();

    uint32 deployTimestamp;

    ICalcFee public calcLib;
    QuoterWrapper public quoter;

    event FeeUpdate(uint256 indexed newFee, uint256 timestamp);

    constructor(IPoolManager _poolManager, address _calcLib, address _quoter) BaseHook(_poolManager) Ownable(DEV_WALLET) {
        calcLib = ICalcFee(_calcLib);
        quoter = QuoterWrapper(_quoter);
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true,
            afterInitialize: false,
            beforeAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterAddLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function beforeInitialize(address, PoolKey calldata key, uint160, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        if (!key.fee.isDynamicFee()) revert MustUseDynamicFee();
        return this.beforeInitialize.selector;
    }

    function abs(int256 x) private pure returns (uint256) {
        if (x >= 0) {
            return uint256(x);
        }
        return uint256(-x);
    }

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata swapData, bytes calldata)
        external
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        uint sqrtPriceX96
        (, sqrtPriceX96)  = quoter.getOutputAmount(swapData.zeroForOne, swapData.amountSpecified);

        bytes memory feeData = abi.encode(abs(swapData.amountSpecified), sqrtPriceX96);
        uint24 fee = calcLib.getFee(feeData);
        poolManager.updateDynamicLPFee(key, fee);
        emit FeeUpdate(fee, block.timestamp);
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function setCalcLib(address _calcLib) external onlyOwner {
        calcLib = ICalcFee(_calcLib);
    }
}
