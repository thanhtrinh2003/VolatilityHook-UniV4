// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {RvVerifier} from "./RvVerifier.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SnarkBasedFeeOracle is RvVerifier, Ownable {
    uint256 public s;
    uint256 public rv;
    uint256 public constant fraction_bits = 40;
    uint public constant ln_1_0001 = 109945666;

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
        (bytes8 n_inv_sqrt, bytes8 n1_inv, bytes8 new_s2, bytes8 n_bytes, bytes32 digest) = this.verifyRvProof(proof, publicValues);

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
        rv = s * ln_1_0001 >> fraction_bits;
    }

    function n_sqrt_test(bytes8 n_inv_sqrt, bytes8 n_bytes) public pure returns (bool) {
        uint n_inv_sqrt_256 = uint256(uint64(n_inv_sqrt));
        uint n = uint(uint64(n_bytes));
        uint n_inv_sqrt_test = n_inv_sqrt_256 * n_inv_sqrt_256 * n >> 2 * fraction_bits;
        uint one_256 = 1 << fraction_bits;
        uint error = 2 * n_inv_sqrt_256 + 1;
        return one_256 - error <= n_inv_sqrt_test && n_inv_sqrt_test <= one_256 + error;
    }

    function n1_check(bytes8 n_bytes, bytes8 n1_inv) public pure returns (bool) {
        uint n = uint(uint64(n_bytes));
        uint n1 = n - 1;
        uint n1_inv_256 = uint256(uint64(n1_inv));
        uint error = 2 * n1_inv_256 + 1;
        uint n1_inv_test = n1_inv_256 * n1 >> fraction_bits;
        uint one_256 = 1 << fraction_bits;
        return one_256 - error <= n1_inv_test && n1_inv_test <= one_256 + error;
    }

    function s2_check(uint256 claimed_s, bytes8 new_s2) public pure returns (bool) {
        uint s_test = uint256(uint64(claimed_s));
        uint s2 = uint256(uint64(new_s2));
        uint s2_test = s_test * s_test >> fraction_bits;
        uint error = 2 * s_test + 1;
        return s2_test < s2 + error && s2_test > s2 - error;
    }

 function calculateFee(uint256 volume, uint256 volatility, uint256 price) public view returns (uint24) {
    // console.log(volume);
    // console.log(volatility);
    // console.log(price);

    // Normalize inputs
    uint256 maxVolume = 1e18; // max value for volume
    uint256 maxVolatility = 1e9; // max value for volatility
    uint256 maxPrice = 1e10; //  max value for price

    uint256 normalizedVolume = volume * 1e18 / maxVolume;
    uint256 normalizedVolatility = volatility * 1e18 / maxVolatility;
    uint256 normalizedPrice = price * 1e18 / maxPrice;

    uint256 value = (normalizedVolume + normalizedVolatility + normalizedPrice) / 3;

    // Scale combined value to fee range
    uint256 minFee = 1000;
    //TODO: should the max fee exceed some limit?
    uint256 maxFee = 100000;

    uint256 fee = minFee + (value * (maxFee - minFee) / 1e18);

    return uint24(fee);
    }

    function getFee(bytes calldata data) external view returns (uint24){
        (uint256 volume, uint160 sqrtPriceLimit) = abi.decode(data, (uint256, uint160));
        calculateFee(volume, rv, sqrtPriceLimit);
    }


    function getVolatility() external view returns (uint256) {
        return rv;
    }
    

    function setVolatility(uint256 _rv) public onlyOwner {
        rv = _rv;
    }
}
