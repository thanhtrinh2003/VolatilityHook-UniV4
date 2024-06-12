// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {SP1Verifier} from "@sp1-contracts/SP1Verifier.sol";

/// @title RvVerifier.
/// @notice This contract implements a simple example of verifying the proof of a computing a
/// the realized volatility from an UniswapV3Pool.
contract RvVerifier is SP1Verifier {
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
    ) public view returns (bytes[] memory,  bytes memory, bytes memory, bytes memory, bytes memory) {
        this.verifyProof(programKey, publicValues, proof);
        (bytes[] memory ticks, bytes memory n_inv_sqrt, bytes memory n1_inv, bytes memory s2, bytes memory n_bytes) = abi.decode(
            publicValues,
            (bytes[], bytes, bytes, bytes, bytes)
        );
        return (ticks, n_inv_sqrt, n1_inv, s2, n_bytes);
    }
    
    /// @notice The entrypoint for verifying the proof of a realized volatility calculation.
    /// @param proof The encoded proof.
    /// @param publicValues The encoded public values.
    /// @dev the public values are better explained in the SP1 `program`
    function verifyUpdatedRvProof( 
        bytes memory proof,
        bytes memory publicValues,
        bytes32 vkey
    //) public view returns (bytes4,  bytes4, bytes4, bytes4, bytes32 ) {
    ) public view returns (bool) {
        this.verifyProof(vkey, publicValues, proof);
        /* (bytes4 n_inv_sqrt, bytes4 n1_inv, bytes4 s2, bytes4 n_bytes, bytes32 digest) = abi.decode(
            publicValues,
            (bytes4, bytes4, bytes4, bytes4, bytes32)
        ); 
        return (n_inv_sqrt, n1_inv, s2, n_bytes, digest); */
        return(true);
    }
}
