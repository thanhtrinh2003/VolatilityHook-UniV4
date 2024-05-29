// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFeeOracle {
    function setFee(uint24 fee) external;

    function getFee() external view returns (uint24);
}
