// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console, console2} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {RvVerifier} from "../src/RvVerifier.sol";
import {SP1Verifier} from "@sp1-contracts/SP1Verifier.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

struct SP1ProofFixtureJson {
    int32 s2;
    int32 s;
    uint32 n;
    uint32 nInvSqrt;
    uint32 n1Inv;
    bytes32 digest;
    bytes publicValues;
    bytes proof;
    bytes32 vkey;
}

contract UpdatedRvVerifiverTest is Test {
    using stdJson for string;
    uint64 constant fraction_bits = 17;
    RvVerifier public rvVerifier;
    using SignedMath for int32;

    function loadFixture() public view returns (SP1ProofFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/src/fixtures/fixture.json");
        string memory json = vm.readFile(path);

        // Decode individual fields
        SP1ProofFixtureJson memory fixture;
        fixture.s2 = abi.decode(json.parseRaw(".s2"), (int32));
        fixture.s = abi.decode(json.parseRaw(".s"), (int32));
        fixture.n = abi.decode(json.parseRaw(".n"), (uint32));
        fixture.nInvSqrt = abi.decode(json.parseRaw(".nInvSqrt"), (uint32));
        fixture.n1Inv = abi.decode(json.parseRaw(".n1Inv"), (uint32));
        fixture.digest = abi.decode(json.parseRaw(".digest"), (bytes32));
        fixture.publicValues = abi.decode(json.parseRaw(".publicValues"), (bytes));
        fixture.proof = abi.decode(json.parseRaw(".proof"), (bytes));
        fixture.vkey = abi.decode(json.parseRaw(".vkey"), (bytes32));

        return fixture;
    }

    function setUp() public {
        SP1ProofFixtureJson memory fixture = loadFixture();
        rvVerifier = new RvVerifier(fixture.vkey);
    }

    function test_ValidUpdatedRvProof() public view {
        SP1ProofFixtureJson memory fixture = loadFixture();
        (bytes4 n_inv_sqrt, bytes4 n1_inv, bytes4 s2, bytes4 n_bytes, bytes32 digest) = rvVerifier.verifyRvProof(
            fixture.proof,
            fixture.publicValues
        );
        // Check that s is within error bounds of the proven s2 value
        uint s = uint(fixture.s.abs());
        uint256 error = 2 * s + 1;
        uint256 s2_test = s * s >> fraction_bits;
        uint256 s2_256 = uint256(uint32(s2));

        assert(s2_test - error <= s2_256 && s2_256 <= s2_test + error);
       
        uint n_inv_sqrt_256 = uint256(uint32(n_inv_sqrt));
        uint n1_inv_256 = uint256(uint32(n1_inv));

        // Check that n1_inv * (n - 1) is within error bounds of 1
        uint n1 = uint(uint32(n_bytes))-1;
        console.log("n1: ", n1);
        error =  2 * n_inv_sqrt_256 + 1;
        console.log("error: ", error);
        uint n1_inv_test = uint(uint32(n1_inv)) * n1 >> fraction_bits;
        console.log("n1_inv_test: ", n1_inv_test);
        uint one_256 = 1 << fraction_bits;
        console.log("one_256: ", one_256);
        assert(one_256 - error <= n1_inv_test && n1_inv_test <= one_256 + error);
        
        // Check that n_inv_sqrt * n_inv_sqrt * n is within error bounds of 1
        uint n = uint(uint32(n_bytes));
        console.log("n: ", n);
        uint n_inv_sqrt_test = n_inv_sqrt_256 * n_inv_sqrt_256 * n >> 2 * fraction_bits;
        console.log("n_inv_sqrt_test: ", n_inv_sqrt_test);
        assert(one_256 - error <= n_inv_sqrt_test && n_inv_sqrt_test <= one_256 + error);
    }
    
    function testFail_InvalidRvProof() public view {
        SP1ProofFixtureJson memory fixture = loadFixture();

        // Create a fake proof.
        bytes memory fakeProof = new bytes(fixture.proof.length);

        rvVerifier.verifyRvProof(fakeProof, fixture.publicValues);
    }
}
