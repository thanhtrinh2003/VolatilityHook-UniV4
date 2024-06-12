// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console, console2} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {RvVerifier} from "../src/RvVerifier.sol";
import {SP1Verifier} from "@sp1-contracts/SP1Verifier.sol";


struct SP1ProofFixtureJson {
    int32 s2;
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

    RvVerifier public rvVerifier;

    function loadFixture() public view returns (SP1ProofFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/src/fixtures/fixture.json");
        string memory json = vm.readFile(path);

        // Decode individual fields
        SP1ProofFixtureJson memory fixture;
        fixture.s2 = abi.decode(json.parseRaw(".s2"), (int32));
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