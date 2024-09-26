// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";

import {CalcFeeLib} from "src/Calc/CalcFeeLib.sol";
import {Script} from "forge-std/Script.sol";
import {OracleBasedFeeHook} from "src/OracleBasedFeeHook.sol";

// runs with
// forge script ./script/DeployCalcLib.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

// Deploys and sets the new calclib contract
// and sets the CalcLib into the OracleBasedHook (assuming the current deployer is the owner of the hook)
contract DeployCalcFeeLib is Script {
    function run() external {
        address RvOracleAddress = 0xa120424BdC490002F0B949e2BB461302547e6769;
        OracleBasedFeeHook hook = OracleBasedFeeHook(0x3BE38115fe7423B3c99abDCfFbE9e92366972080);
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerPrivateKey);
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deploying contract with the deployer address:", deployerAddress);

        vm.startBroadcast(deployer);
        CalcFeeLib calcFeeLib = new CalcFeeLib(RvOracleAddress);

        hook.setCalcLib(address(calcFeeLib));

        vm.stopBroadcast();

        console.log("CalcFeeLib deployed to:", address(calcFeeLib));
    }
}
