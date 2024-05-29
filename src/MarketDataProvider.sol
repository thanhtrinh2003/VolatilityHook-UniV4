pragma solidity ^0.8.0;

import {IAggregatorV3} from "./interfaces/IAggregatorV3.sol";

contract MarketDataProvider {
    function getVersion() public view returns (uint256) {
        IAggregatorV3 priceFeed = IAggregatorV3(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
    }

    function getEthUsdPrice() public view returns (uint256) {
        IAggregatorV3 priceFeed = IAggregatorV3(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getEthUsdVol() public view returns (uint256) {
        IAggregatorV3 priceFeed = IAggregatorV3(0x31D04174D0e1643963b38d87f26b0675Bb7dC96e);
        (, int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getVolDecimals() public view returns (uint8) {
        IAggregatorV3 priceFeed = IAggregatorV3(0x31D04174D0e1643963b38d87f26b0675Bb7dC96e);
        return uint8(priceFeed.decimals());
    }
}