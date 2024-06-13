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
    uint256 public constant fraction_bits = 17;
    uint public constant ln_1_0001 = 13;

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
        (bytes4 n_inv_sqrt, bytes4 n1_inv, bytes4 new_s2, bytes4 n_bytes, bytes32 digest) = this.verifyRvProof(proof, publicValues);

        // Check that the claimed s is within error bounds of the proven s2 value
        // We can expect one digit of error when computing fixed point square roots
        // s_true = s +/- 1 => s_true^2 = s^2 +/- 2*s +/- 1, i.e. error = +/- (2*s + 1); 
        require(s2_check(claimed_s, new_s2), "provided volality, s, is not within error bounds relative to s2");

        
        // Check that the values for 1/sqrt(n) and 1/(n-1) are within error bounds 
        // Check that n1_inv * (n - 1) is within error bounds of 1
        require(n1_check(n_bytes, n1_inv), "n1_inv * (n - 1) is not within error bounds of 1");
        // Check that n_inv_sqrt * n_inv_sqrt * n is within error bounds of 1
        require(n_sqrt_test(n_inv_sqrt, n_bytes), "n_inv_sqrt * n_inv_sqrt * n is not within error bounds of 1");

        // If all checks pass, update s.
        s = claimed_s; 

        // Convert from tick log base to ln base for textbook realized volatility
        rv = s * ln_1_0001;
        fee = calculateFee(rv);
    }

    function n_sqrt_test(bytes4 n_inv_sqrt, bytes4 n_bytes) public view returns (bool) {
        uint n_inv_sqrt_256 = uint256(uint32(n_inv_sqrt));
        uint n = uint(uint32(n_bytes));
        uint n_inv_sqrt_test = n_inv_sqrt_256 * n_inv_sqrt_256 * n >> 2 * fraction_bits;
        uint one_256 = 1 << fraction_bits;
        uint error = 2 * n_inv_sqrt_256 + 1;
        return one_256 - error <= n_inv_sqrt_test && n_inv_sqrt_test <= one_256 + error;
    }

    function n1_check(bytes4 n, bytes4 n1_inv) public view returns (bool) {
        uint n = uint(uint32(n));
        uint n1 = n - 1;
        uint n1_inv_256 = uint256(uint32(n1_inv));
        uint error = 2 * n1_inv_256 + 1;
        uint n1_inv_test = n1_inv_256 * n1 >> fraction_bits;
        uint one_256 = 1 << fraction_bits;
        return one_256 - error <= n1_inv_test && n1_inv_test <= one_256 + error;
    }

    function s2_check(uint256 claimed_s, bytes4 new_s2) public view returns (bool) {
        uint s = uint256(uint32(claimed_s));
        uint s2 = uint256(uint32(new_s2));
        uint s2_test = s * s >> fraction_bits;
        uint error = 2 * s + 1;
        return s2_test < s2 + error && s2_test > s2 - error;
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
