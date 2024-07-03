// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CalcFeeUtils {
    // Error function approximation constants
    int256 constant A1 = 254829592;
    int256 constant A2 = -284496736;
    int256 constant A3 = 142141374;
    int256 constant A4 = -29129941;
    int256 constant A5 =  1058088;
    int256 constant P  = 3275911;

    // function erf(int256 x) internal pure returns (int256) {
    //     // Save the sign of x
    //     int256 sign = x >= 0 ? int256(1) : int256(-1);
    //     x = abs(x);

    //     // Calculate the approximation
    //     int256 t = int256(1) * 10**18 / (int256(1) * 10**18 + P * x / 10**18);
    //     int256 y = (((((A5 * t / 10**18 + A4) * t / 10**18 + A3) * t / 10**18 + A2) * t / 10**18 + A1) * t / 10**18) * exp(-x * x / 10**18) / 10**18;

    //     return sign * (int256(1) * 10**18 - y);
    // }

    // function exp(int256 x) internal pure returns (int256) {
    //     // Approximate e^x using the series expansion
    //     int256 sum = int256(1) * 10**18;
    //     int256 term = int256(1) * 10**18;
    //     for (uint256 i = 1; i < 50; i++) {
    //         term = (term * x / int256(i)) / 10**18;
    //         sum += term;
    //     }
    //     return sum;
    // }

    // function abs(int256 x) internal pure returns (int256) {
    //     return x >= 0 ? x : -x;
    // }

    // function cdf(int256 z) internal pure returns (int256) {
    //     // Standard normal cumulative distribution function
    //     // Scaled for fixed-point arithmetic with 18 decimals
    //     int256 scaleFactor = 10**18;
    //     return scaleFactor * (int256(1) * 10**18 + erf(z * scaleFactor / sqrt(2 * scaleFactor))) / (2 * scaleFactor);
    // }

    function sqrt(int256 x) internal pure returns (int256) {
        int256 z = (x + 1) / 2;
        int256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
