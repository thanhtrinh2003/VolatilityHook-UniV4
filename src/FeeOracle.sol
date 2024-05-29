// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFeeOracle} from "./interfaces/IFeeOracle.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FeeOracle is IFeeOracle, Ownable {
    uint24 public fee;

    constructor(address _owner) Ownable(_owner) {}

    function setFee(uint24 _fee) external onlyOwner {
        fee = _fee;
    }

    function getFee() external view returns (uint24) {
        return fee;
    }
}
