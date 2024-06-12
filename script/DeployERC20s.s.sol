    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SUSD is ERC20 {
    constructor() ERC20("SUSD", "SUSD") {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // Mint 1,000,000 SUSD to the deployer
    }
}

contract SETH is ERC20 {
    constructor() ERC20("SETH", "SETH") {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // Mint 1,000,000 SETH to the deployer
    }
}



import "forge-std/Script.sol";
contract DeployTokens is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy SUSD token
        SUSD susd = new SUSD();
        console.log("SUSD deployed to:", address(susd));

        // Deploy SETH token
        SETH seth = new SETH();
        console.log("SETH deployed to:", address(seth));

        vm.stopBroadcast();
    }
}

