// CalculationV1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlinkOracle {
    function latestAnswer() external returns (int256);
}
