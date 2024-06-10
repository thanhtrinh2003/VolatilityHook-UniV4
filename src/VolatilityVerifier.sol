// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {SP1Verifier} from "@sp1-contracts/SP1Verifier.sol";

/// @title RvVerifier.
/// @notice This contract implements a simple example of verifying the proof of a computing a
/// the realized volatility from an UniswapV3Pool.
contract RvVerifiver is SP1Verifier {
    /// @notice The verification key for the fibonacci program.
    bytes32 public programKey;

    constructor(bytes32 _programKey) {
        programKey = _programKey;
    }

    /// @notice The entrypoint for verifying the proof of a realized volatility calculation.
    /// @param proof The encoded proof.
    /// @param publicValues The encoded public values.
    /// @dev the public values are better explained in the SP1 `program`
    function verifyRvProof(
        bytes memory proof,
        bytes memory publicValues
    ) public view returns (uint8[] memory, uint8, uint8) {
        this.verifyProof(programKey, publicValues, proof);
        (uint8[] memory ticks, uint8 n_inv_sqrt, uint8 n1_inv) = abi.decode(
            publicValues,
            (uint8[], uint8, uint8)
        );
        return (ticks, n_inv_sqrt, n1_inv);
    }
}