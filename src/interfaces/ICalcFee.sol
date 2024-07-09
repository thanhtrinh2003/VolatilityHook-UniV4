// CalculationV1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICalcFee {
    function getFee(bytes calldata data) external returns (uint24);
}