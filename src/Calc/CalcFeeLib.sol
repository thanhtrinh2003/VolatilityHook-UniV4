// CalculationV1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICalcFee} from "../interfaces/ICalcFee.sol";
import {IVolatilityOracle} from "../interfaces/IVolatilityOracle.sol";

contract CalcFeeLib is ICalcFee {
    IVolatilityOracle public oracle;
    uint256 constant NUM_FRAC_BITS = 40;

    // taken from the source
    //TODO: is it necessary to represent this value as ether units too?
    uint256 ETH_VOL_SCALE_FIXED = 150 << NUM_FRAC_BITS;


    /// The MIN_FEE as in fixed point arithmetic, but it is represented as an unit of ether
    //TODO: Figure what a representation with ether units changes in the 
    // calcFee function
    uint LONG_ETH_VOL_FIXED = 0.6 ether << NUM_FRAC_BITS;
    uint256 constant MIN_FEE = 3.5 * 10**18;  // 3.5 Ether as 3.5 USD equivalent
    constructor(address _oracle) {
        oracle = IVolatilityOracle(_oracle);
    }


  function fixedPointMul(uint256 left, uint256 right) public pure returns (uint256) {
        uint256 result = (left * right) >> NUM_FRAC_BITS;
        return result;
    }
    
    function fixedPointDivide(uint256 num, uint256 den) public pure returns (uint256) {
        require(den != 0, "Division by zero");
        uint256 result = (num << NUM_FRAC_BITS) / den;
        return result;
    }


    function getFee(bytes calldata data) external view returns (uint24) {
        (uint256 volume, uint160 sqrtPriceLimit) = abi.decode(data, (uint256, uint160));
        return calculateFee(volume, oracle.getVolatility(), sqrtPriceLimit);
    }

    // # Fee calculation taken from reference
    // def calculateFee(volume, volatility):
    //     scaled_volume = fixed_point_divide(volume, ETH_VOL_SCALE)
    //     scaled_vol = fixed_point_divide(volatility, LONG_ETH_VOL_FIXED)
    //     scaled_vol2 = fixed_point_mul(scaled_vol, scaled_vol)
    //     constant_factor = FUDGE_FACTOR
        
    //     fee_per_lot = MIN_FEE_FIXED + constant_factor * fixed_point_mul(scaled_volume, scaled_vol2)

    //     return fee_per_lot 
    //     # return int(fee_per_lot / price / 1e10)



    function calculateFee(uint256 volume, uint256 rv, uint256 price) public view returns (uint24) {
        uint scaled_volume = fixedPointDivide(volume, ETH_VOL_SCALE_FIXED);
        uint scaled_vol = fixedPointDivide(rv, LONG_ETH_VOL_FIXED);
        uint  scaled_volSq = fixedPointMul(scaled_vol, scaled_vol);
        uint constant_factor = 2;

        uint fee_per_lot = MIN_FEE + constant_factor * fixedPointMul(scaled_volume, scaled_volSq);
        return fee_per_lot;
    }
}
