// CalculationV1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICalcFee} from "../interfaces/ICalcFee.sol";
import {IVolatilityOracle} from "../interfaces/IVolatilityOracle.sol";

import {MIN_SQRT_PRICE, MAX_SQRT_PRICE} from "../src/libraries/TickMath.sol";

contract CalcFeeLib is ICalcFee {
    IVolatilityOracle public oracle;
    const LONG_ETH_VOL = 0.6;
    const MIN_FEE = 3.5;
    const ETH_VOL_SCALE = 150;

    const FUDGE_FACTOR = 2;

    constructor(address _oracle) {
        oracle = IVolatilityOracle(_oracle);
    }

    function getFee(bytes calldata data) external view returns (uint24) {
        (uint256 volume, uint160 sqrtPriceLimit) = abi.decode(data, (uint256, uint160));
        return calculateFee(volume, oracle.getVolatility(), sqrtPriceLimit);
    }
    function calculateFee(uint256 volume, uint256 volatility, uint256 price) public pure returns (uint24) {
        // Normalized Value
        uint256 normalizedVolume = volume / ETH_VOL_SCALE
        uint256 normalizedVolatility = volatility / ETH_VOL_SCALE
        uint256 vol_squared = normalizedVolatility * normalizedVolatility;

        uint256 fee_per_lot = MIN_FEE + FUDGE_FACTOR * normalizedVolume * vol_squared;

        return uint24(fee_per_lot);
    }
}
