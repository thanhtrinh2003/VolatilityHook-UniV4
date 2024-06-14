// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISnarkBasedFeeOracle {
    function getVolatility() external view returns (uint256); 
    function getPrice() external view returns (uint256);
}
