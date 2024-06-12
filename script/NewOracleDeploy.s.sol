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

import {Deployer} from "contracts/Deployer.sol";

import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

import {HookMiner} from "contracts/utils/HookMiner.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


struct SP1ProofFixtureJson {
    int32 s2;
    uint32 n;
    uint32 nInvSqrt;
    uint32 n1Inv;
    bytes32 digest;
    bytes publicValues;
    bytes proof;
    bytes32 vkey;
}


contract hookDeployment is Script {
    using stdJson for string;
    address deployer;
    address hook;
    address poolManager;

    function loadFixture() public view returns (SP1ProofFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/src/fixtures/fixture.json");
        string memory json = vm.readFile(path);

        // Decode individual fields
        SP1ProofFixtureJson memory fixture;
        fixture.s2 = abi.decode(json.parseRaw(".s2"), (int32));
        fixture.n = abi.decode(json.parseRaw(".n"), (uint32));
        fixture.nInvSqrt = abi.decode(json.parseRaw(".nInvSqrt"), (uint32));
        fixture.n1Inv = abi.decode(json.parseRaw(".n1Inv"), (uint32));
        fixture.digest = abi.decode(json.parseRaw(".digest"), (bytes32));
        fixture.publicValues = abi.decode(json.parseRaw(".publicValues"), (bytes));
        fixture.proof = abi.decode(json.parseRaw(".proof"), (bytes));
        fixture.vkey = abi.decode(json.parseRaw(".vkey"), (bytes32));

        return fixture;
    }



    function run() public {

        SP1ProofFixtureJson memory fixture = loadFixture();


        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        // Load hook and poolManager addresses from environment variables
        hook = vm.envAddress("HOOK_ADDRESS");
        poolManager = vm.envAddress("POOLMANAGER");


        vm.startBroadcast(deployer);

        //Deploy verifier, fee oracle
        bytes32 programKey  = fixture.vkey;
        console.log("proggram key:");
        // console.log(programKey);
        
        SnarkBasedFeeOracle feeOracle = new SnarkBasedFeeOracle(programKey);

        OracleBasedFeeHook(hook).setFeeOracle(address(feeOracle));
        feeOracle.setFee(5000);

        vm.stopBroadcast();

        console.log("Fee Oracle: ", address(feeOracle));
        console.log("Hook: ", address(hook));
    }
}
