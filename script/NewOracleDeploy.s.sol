// pragma solidity ^0.8.20;

// import {Script} from "forge-std/Script.sol";
// import {console} from "forge-std/console.sol";
// import {Test} from "forge-std/Test.sol";

// import {ICREATE3Factory} from "@create3-factory/ICREATE3Factory.sol";

// import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
// import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";

// import {SnarkBasedFeeOracle} from "contracts/SnarkBasedFeeOracle.sol";
// import {OracleBasedFeeHook} from "contracts/OracleBasedFeeHook.sol";
// import {MarketDataProvider} from "contracts/MarketDataProvider.sol";
// import {RvVerifiver} from "contracts/VolatilityVerifier.sol";

// import {Deployer} from "contracts/Deployer.sol";

// import {HookMiner} from "contracts/utils/HookMiner.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// contract hookDeployment is Script {
//     address deployer;
//     address hook = 0x344778Db62D10706df880dAC7B0E680a01DF2080;
//     address poolManager = 0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14;


//     function run() public {
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         deployer = vm.rememberKey(deployerPrivateKey);

//         vm.startBroadcast(deployer);

//         //Deploy verifier, fee oracle
//         bytes32 programKey  = 0x000c413c257554c0d44f840ea4e6e3cf6acf1ec722af839547814ce9632fd6bf;
//         SnarkBasedFeeOracle feeOracle = new SnarkBasedFeeOracle(programKey);

//         OracleBasedFeeHook(hook).setFeeOracle(address(feeOracle));
//         feeOracle.setFee(5000);

//         vm.stopBroadcast();

//         console.log("Fee Oracle: ", address(feeOracle));
//         console.log("Hook: ", address(hook));
//     }
// }
