// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OracleBasedFeeHook} from "./OracleBasedFeeHook.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";

contract Deployer  {
    address hookAddress;
    address poolManager = 0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14;
    constructor(){}

    function deploy(bytes32 salt, address oracle) external  {
        OracleBasedFeeHook hook = new OracleBasedFeeHook{salt: salt}(IPoolManager(poolManager), oracle);

        hookAddress = address(hook);
    }
}
