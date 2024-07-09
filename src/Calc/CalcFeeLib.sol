// CalculationV1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICalcFee} from "../interfaces/ICalcFee.sol";
import {ISnarkBasedFeeOracle} from "../interfaces/ISnarkBasedFeeOracle.sol";

contract CalcFeeLib is ICalcFee {

    ISnarkBasedFeeOracle public oracle; 

        constructor(address _oracle) {
            oracle = ISnarkBasedFeeOracle(_oracle);
        }


    function getFee(bytes calldata data) external view returns (uint24){
        (uint256 volume, uint160 sqrtPriceLimit) = abi.decode(data, (uint256, uint160));
        calculateFee(volume, oracle.getVolatility(), sqrtPriceLimit);
    }

 function calculateFee(uint256 volume, uint256 volatility, uint256 price) public pure returns (uint24) {

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