pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";

import {FeeOracle} from "contracts/FeeOracle.sol";
import {OracleBasedFeeHook} from "contracts/OracleBasedFeeHook.sol";
import {MarketDataProvider} from "contracts/MarketDataProvider.sol";
import {RvVerifiver} from "contracts/VolatilityVerifier.sol";

import {HookMiner} from "contracts/utils/HookMiner.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract hookDeployment is Script {
    address deployer;
    address poolManager = 0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        //Deploy verifier, fee oracle
        FeeOracle feeOracle = new FeeOracle(deployer);

        //Deploy hook
         uint160 flags = uint160(
            Hooks.BEFORE_INITIALIZE_FLAG |  
            Hooks.BEFORE_SWAP_FLAG
        );

        (, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            type(OracleBasedFeeHook).creationCode,
            abi.encodePacked(IPoolManager(poolManager), address(feeOracle))
        );
        
        console.log("Found salt: ", string(abi.encodePacked(salt)));
        
        OracleBasedFeeHook hook = new OracleBasedFeeHook{salt: salt}(IPoolManager(poolManager), address(feeOracle));

        vm.stopBroadcast();
       

        console.log("Fee Oracle: ", address(feeOracle));
        console.log("Hook: ", address(hook));
    }
}
