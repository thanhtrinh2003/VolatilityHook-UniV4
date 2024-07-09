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

contract OracleBasedFeeHookV2 is BaseHook, Ownable {
    using LPFeeLibrary for uint24;

    uint256 public constant MIN_FEE = 1000;
    
    error MustUseDynamicFee();

    uint32 deployTimestamp;

    address public feeOracle;

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
        
        //TODO: setup a correct cdf, (also through a proof?)
        //other option is to use the z_score to calcualte cdf on chain...
        uint256 cdf = 22750062887256395;
        uint24 fee = calculateFee(volatility, cdf);
        poolManager.updateDynamicLPFee(key, fee);

        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function setFeeOracle(address _feeOracle) external onlyOwner {
        feeOracle = _feeOracle;
    } 





    function calculateFee(uint256 volatility, uint256 cdf) internal pure returns (uint24) {
        // 0.5 shift
        uint256 fee_scalar = cdf + 500000000000000000;
        // uint256 scaled_volume = volume / 150;
        // uint256 longterm_eth_volatility = 60;
        // uint256 scaled_vol = volatility / longterm_eth_volatility;
        // uint256 constant_factor = 2;

        uint256 fee_per_lot = MIN_FEE * fee_scalar;

        return uint24((fee_per_lot /   1e10));

    }

}
