pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

import {ICREATE3Factory} from "@create3-factory/ICREATE3Factory.sol";

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";

import {SnarkBasedFeeOracle} from "contracts/SnarkBasedFeeOracle.sol";
import {OracleBasedFeeHook} from "contracts/OracleBasedFeeHook.sol";
import {MarketDataProvider} from "contracts/MarketDataProvider.sol";
import {RvVerifier} from "contracts/RvVerifier.sol";
import {IFeeOracle} from "contracts/interfaces/IFeeOracle.sol";

import {Deployer} from "contracts/Deployer.sol";

import {HookMiner} from "contracts/utils/HookMiner.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract hookDeployment is Script {
    address deployer;
    address oracle;


    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        oracle = vm.envAddress("FEE_ORACLE");

        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        //Deploy verifier, fee oracle

        IFeeOracle feeOracle = IFeeOracle(oracle);
        feeOracle.setFee(5000);

        vm.stopBroadcast();

        console.log("Fee Oracle: ", address(feeOracle));
    }
}
