// CalculationV1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICalcFee} from "../interfaces/ICalcFee.sol";
import {IVolatilityOracle} from "../interfaces/IVolatilityOracle.sol";
import "forge-std/console.sol";

contract CalcFeeLib is ICalcFee {
    IVolatilityOracle public oracle;
    uint256 constant NUM_FRAC_BITS = 40;
    uint256 constant X96_BITS = 96;

    // taken from the source
    //TODO: is it necessary to represent this value as ether units too?
    uint256 ETH_LONG_VOL = 0.000777943209666519 ether;
    uint256 ETH_VOL_SCALE_FIXED = ETH_LONG_VOL << NUM_FRAC_BITS;


    /// The MIN_FEE as in fixed point arithmetic, but it is represented as an unit of ether
    //TODO: Figure what a representation with ether units changes in the 
    // calcFee function
    uint LONG_ETH_VOL_FIXED = 0.6 ether  << NUM_FRAC_BITS;
    uint256 constant MIN_FEE = 3.5 ether << NUM_FRAC_BITS;
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
        return calcFeeBips(volume, oracle.getVolatility(), sqrtPriceLimit);
    }



    function calculateFee(uint256 volume, uint256 rv) public view returns (uint256) {
        uint scaled_volume = fixedPointDivide(volume, 150);
        
        // multiply rv by 1 ether o account for representation of 0.6 as 0.6 ether
        uint scaled_vol = fixedPointDivide(rv * 1 ether, LONG_ETH_VOL_FIXED);
        uint  scaled_volSq = fixedPointMul(scaled_vol, scaled_vol);
        uint constant_factor = 2;

        uint fee_per_lot = MIN_FEE + constant_factor * fixedPointMul(scaled_volume, scaled_volSq);
        // compensate for the 1 ether multiplication of the rv, giving the exact same value as the notebook (or sometimes off by 1)
        return fee_per_lot / 1 ether;
    }

    function calcFeeBips(uint volume, uint rv, uint sqrtX96Price) public view returns (uint24) {

        uint fee_per_lot = calculateFee(volume, rv);
        uint256 price = ((sqrtX96Price * sqrtX96Price) >> (2 * X96_BITS)) << X96_BITS;


        uint num_shift_bits = 2*X96_BITS - NUM_FRAC_BITS;
        
        
        uint fee_percent_fixed = (fee_per_lot << num_shift_bits) / (price);
        
        // to go from fixed-point to bips we need to multiply our fixed-point number by 10_000 and shift right by the scale factor
        uint fee_percent_bips = (10000 * fee_percent_fixed) >> X96_BITS;
        // 1 bip = 0.01%
        return uint24(fee_percent_bips);
    }

}
