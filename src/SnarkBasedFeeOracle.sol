// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {RvVerifier} from "./RvVerifier.sol";

import {IFeeOracle} from "./interfaces/IFeeOracle.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SnarkBasedFeeOracle is RvVerifier, IFeeOracle, Ownable {
    uint256 public constant MIN_FEE = 1000;
    bytes public n1_inv;
    uint256 public s;
    uint256 rv;
    uint24 public fee;
    uint256 public constant fractional_bits = 17;
    uint public constant ln_1_0001 = 10;

    constructor(bytes32 _programKey) RvVerifier(_programKey) Ownable(msg.sender) {}

    /// @notice The entrypoint for verifying the proof and updating state variables.
    /// @param proof The encoded proof.
    /// @param publicValues The encoded public values.
    function verifyAndUpdate(
        uint256 claimed_s,
        bytes memory proof,
        bytes memory publicValues
    ) public {
        // Verify the proof using the base contract's function
        (, , bytes4 new_n1_inv, bytes4 new_s2, ) = this.verifyRvProof(proof, publicValues);

        // Update the state variables
        // Check that the claimed s is within error bounds of the proven s2 value
        // We can expect one digit of error when computing fixed point square roots
        // s_true = s +/- 1 => s_true^2 = s^2 +/- 2*s +/- 1, i.e. error = +/- (2*s + 1); 
        uint s2 = uint256(uint32(new_s2));
        uint s2_test = claimed_s * claimed_s >> fractional_bits;
        uint error = 2*s + 1;
        require(s2_test < s2 + error && s2_test > s2 - error, "provided volality, s, is not within error bounds relative to s2");
        s = claimed_s; 

        // TODO: used fixed point floats for rv and substitue 10 by ln(1.0001)
        // TODO: Also, there are two values that are input to the proof, n_inv_sqrt and n_inv 
        // and one additional value output from the proof n_bytes. 
        // We need to decode n_bytes to get n and then check that n_inv * n == 1 and n_inv_sqrt * n.sqrt() == 1.

        rv = s * ln_1_0001;
        fee = calculateFee(rv);
    }

    function setFee(uint24 _fee) external override onlyOwner {
        fee = _fee;
    }

    function getFee() external view override returns (uint24) {
        return fee;
    }

    function getVolatility() public view returns (uint256) {
        return rv;
    }

    function calculateFee(uint256 rv) internal returns (uint24) {
        return uint24(MIN_FEE + rv * 1000);
    }
}
