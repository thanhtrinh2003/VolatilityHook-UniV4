// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {RvVerifier} from "../src/RvVerifier.sol";
import {SP1Verifier} from "@sp1-contracts/SP1Verifier.sol";


struct SP1ProofFixtureJson {
    int32 s2;
    uint32 n_inv_sqrt;
    uint32 n1_inv;
    bytes32 digest;
    bytes proof;
    bytes publicValues;
    bytes32 vkey;
}

contract RvVerifiverTest is Test {
    using stdJson for string;

    RvVerifier public rvVerifier;

    function loadFixture() public view returns (SP1ProofFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/src/fixtures/updated_fixture.json");
        string memory json = vm.readFile(path);
//        console.log("json: ", json);
        bytes memory jsonBytes = json.parseRaw(".");
//        console.log("jsonBytes: ", jsonBytes);
        return abi.decode(jsonBytes, (SP1ProofFixtureJson));
    }

    function setUp() public {
        SP1ProofFixtureJson memory fixture = loadFixture();
    //    rvVerifier = new RvVerifier(fixture.vkey);
    }

    function test_ValidFRvProof() public view {
        SP1ProofFixtureJson memory fixture = loadFixture();
//         (bytes4 n_inv_sqrt, bytes4 n1_inv, bytes4 s2, bytes4 n_bytes, bytes32 digest) = rvVerifier.verifyUpdatedRvProof(
         (bool success) = rvVerifier.verifyUpdatedRvProof(
            fixture.proof,
            fixture.publicValues,
            fixture.vkey
        );
        // assert(keccak256(abi.encodePacked(ticks)) ==  keccak256(abi.encodePacked(fixture.ticks)));
        // assert(n_inv_sqrt == fixture.n_inv_sqrt);
        // assert(n1_inv == fixture.n1_inv);
    }

    function testFail_InvalidRvProof() public view {
        SP1ProofFixtureJson memory fixture = loadFixture();

        // Create a fake proof.
        bytes memory fakeProof = new bytes(fixture.proof.length);

        rvVerifier.verifyRvProof(fakeProof, fixture.publicValues);
    }
}
