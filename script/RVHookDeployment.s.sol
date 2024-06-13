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

import {Deployer} from "contracts/Deployer.sol";

import {HookMiner} from "contracts/utils/HookMiner.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract hookDeployment is Script {
    address deployer;
    address create2 = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    address poolManager;

    //ICREATE3Factory create3Factory = ICREATE3Factory(0x9fBB3DF7C40Da2e5A0dE984fFE2CCB7C47cd0ABf);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        poolManager = vm.envAddress("POOLMANAGER");


        vm.startBroadcast(deployer);

        //Deploy verifier, fee oracle
        bytes32 programKey  = 0x000c413c257554c0d44f840ea4e6e3cf6acf1ec722af839547814ce9632fd6bf;
        SnarkBasedFeeOracle feeOracle = new SnarkBasedFeeOracle(programKey);

        vm.stopBroadcast();

        //Deploy hook
        uint160 flags = uint160(
            Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG
        );

        (, bytes32 salt) = HookMiner.find(
            create2,
            flags,
            type(OracleBasedFeeHook).creationCode,
            abi.encode(IPoolManager(poolManager), address(feeOracle))
        );

        console.logBytes32(salt);

        vm.startBroadcast(deployer);

        OracleBasedFeeHook hook = new OracleBasedFeeHook{salt: salt}(
            IPoolManager(poolManager),
            address(feeOracle)
        );

        vm.stopBroadcast();

        console.log("Fee Oracle: ", address(feeOracle));
        console.log("Hook: ", address(hook));
    }
}
