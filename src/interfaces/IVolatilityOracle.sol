// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVolatilityOracle {
    function getVolatility() external view returns (uint256);
    function getPrice() external view returns (uint256);
}
