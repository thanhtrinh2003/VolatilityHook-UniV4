// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFeeOracle} from "./interfaces/IFeeOracle.sol";
import {MarketDataProvider} from "./MarketDataProvider.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FeeOracle is IFeeOracle, Ownable {
    uint256 public constant MIN_FEE = 1000;
    uint256 public rv;
    uint24 public fee;

    constructor(address _owner) Ownable(_owner) {}

    function updateRV(uint256 _realizedVotalitiy) external onlyOwner {
        rv = _realizedVotalitiy;
        fee = calculateFee(rv);
    }

    function setFee(uint24 _fee) external override onlyOwner {
        fee = _fee;
    }

    function getFee() external view override returns (uint24) {
        return fee;
    }

    function calculateFee(uint256 _rv) internal returns (uint24) {
        return uint24(MIN_FEE + _rv * 1000);
    }

}
