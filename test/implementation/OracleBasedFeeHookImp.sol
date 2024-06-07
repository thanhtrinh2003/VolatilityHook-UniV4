// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {BaseHook} from "@v4-periphery/BaseHook.sol";
import {OracleBasedFeeHook} from "../../src/OracleBasedFeeHook.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "@v4-core/libraries/Hooks.sol";

contract OracleBasedFeeHookImp is OracleBasedFeeHook {
    constructor(IPoolManager poolManager, OracleBasedFeeHook addressToEtch, address feeOracle) OracleBasedFeeHook(poolManager, feeOracle) {
        Hooks.validateHookPermissions(addressToEtch, getHookPermissions());
    }

    // make this a no-op in testing
    function validateHookAddress(BaseHook _this) internal pure override {}
}
