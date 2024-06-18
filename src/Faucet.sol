// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Faucet  {
    address constant public Semiotics_ETH = 0x5c2143dA3071627568aB1FA146E688B4B000Bb05;
    address constant public Semiotics_USDC = 0xC056fd4dD61d1647996Fa8eE076E34113B43E952;

    constructor() {
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
