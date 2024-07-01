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
import {ISnarkBasedFeeOracle} from "./interfaces/ISnarkBasedFeeOracle.sol";
import {SnarkBasedFeeOracle} from "./SnarkBasedFeeOracle.sol";
import {console} from "forge-std/console.sol";

contract OracleBasedFeeHook is BaseHook, Ownable {
    using LPFeeLibrary for uint24;

    uint256 public constant MIN_FEE = 1000;
    
    error MustUseDynamicFee();



    uint32 deployTimestamp;

    address public feeOracle;


    event FeeUpdate(uint256 indexed newFee, uint256 timestamp);



    constructor(
        IPoolManager _poolManager,
        address _feeOracle
    ) BaseHook(_poolManager) Ownable(msg.sender) {
        console.log("Deploying OracleBasedFeeHook");
        feeOracle = _feeOracle; 
    }

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
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

    function beforeInitialize(
        address,
        PoolKey calldata key,
        uint160,
        bytes calldata
    ) external pure override returns (bytes4) {
        if (!key.fee.isDynamicFee()) revert MustUseDynamicFee();
        return this.beforeInitialize.selector;
    }

    function abs(int256 x) private pure returns (uint256) {
        if (x >= 0) {
            return uint256(x);
        }
        return uint256(-x);
    }

    function beforeSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata swapData,
        bytes calldata
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        uint256 volatility = ISnarkBasedFeeOracle(feeOracle).getVolatility();
        uint24 fee = calculateFee(abs(swapData.amountSpecified), volatility, swapData.sqrtPriceLimitX96);
        poolManager.updateDynamicLPFee(key, fee);

        emit FeeUpdate(fee, block.timestamp);
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function setFeeOracle(address _feeOracle) external onlyOwner {
        feeOracle = _feeOracle;
    } 

 function calculateFee(uint256 volume, uint256 volatility, uint256 price) public view returns (uint24) {
    // console.log(volume);
    // console.log(volatility);
    // console.log(price);

    // Normalize inputs
    uint256 maxVolume = 1e18; // max value for volume
    uint256 maxVolatility = 1e9; // max value for volatility
    uint256 maxPrice = 1e10; //  max value for price

    uint256 normalizedVolume = volume * 1e18 / maxVolume;
    uint256 normalizedVolatility = volatility * 1e18 / maxVolatility;
    uint256 normalizedPrice = price * 1e18 / maxPrice;

    uint256 value = (normalizedVolume + normalizedVolatility + normalizedPrice) / 3;

    // Scale combined value to fee range
    uint256 minFee = 1000;
    //TODO: should the max fee exceed some limit?
    uint256 maxFee = 100000;

    uint256 fee = minFee + (value * (maxFee - minFee) / 1e18);

    return uint24(fee);
    }

}
