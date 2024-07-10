// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Faucet  {
    address public Semiotics_ETH;
    address public Semiotics_USDC;

    constructor(address _eth, address _usdc) {
        Semiotics_ETH = _eth;
        Semiotics_USDC = _usdc;
    }

    function claimSemioticsETH() public {
        require(ERC20(Semiotics_ETH).balanceOf(address(msg.sender)) <= 0.1e18, "You have enough sETH for testing!");
        ERC20(Semiotics_ETH).transfer(msg.sender, 0.1e18);
    }

    function claimSemioticsUSDC() public {
        require(ERC20(Semiotics_USDC).balanceOf(address(msg.sender)) <= 0.1e18, "You have enough sUSDC for testing!");
        ERC20(Semiotics_USDC).transfer(msg.sender, 0.1e18);
    }
}