// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Calc/CalcFeeLib.sol";
import "../src/interfaces/IVolatilityOracle.sol";

contract CalcFeeLibTest is Test {
    CalcFeeLib public calcFeeLib;
    MockVolatilityOracle public oracle;
    uint256[] public newRvValues;

    function setUp() public {
        // Deploy the mock oracle
        oracle = new MockVolatilityOracle();

        // Deploy the CalcFeeLib contract with the mock oracle's address
        calcFeeLib = new CalcFeeLib(address(oracle));
        string[] memory cmds = new string[](3);
        cmds[0] = "python3";  // Use python3 to run the script
        cmds[1] = "./test/encode_rv_values.py";  // Updated to point to the new Python script
        cmds[2] = "./test/volatility_updates.json";
    

        bytes memory result = vm.ffi(cmds);
        // console.log(result);
        newRvValues = abi.decode(result, (uint256[]));
        console.log(newRvValues[0]);
    }

    function test_CalculateFee() public {
        // Set up test parameters
        uint256 volume = 1000;
        uint160 sqrtPriceLimit = 123456789;

        // Set the oracle's volatility to a known value
        uint256 testVolatility = 1000000000;
        oracle.setVolatility(testVolatility);

        // Encode the data as expected by the getFee function
        bytes memory data = abi.encode(volume, sqrtPriceLimit);

        // Call the getFee function and assert the returned fee is as expected
        uint24 fee = calcFeeLib.getFee(data);

        // Calculate the expected fee manually based on the contract's logic
        uint24 expectedFee = calcFeeLib.calculateFee(volume, testVolatility, sqrtPriceLimit);

        assertEq(fee, expectedFee);
    }

    function testCalculateFeeWithEdgeVolatility() public {
        // Test with minimum and maximum volatility
        uint256 minVolatility = 360177162;
        uint256 maxVolatility = 4667025474;
        uint160 sqrtPriceLimit = 123456789;
        uint256 volume = 1000;

        oracle.setVolatility(minVolatility);
        uint24 minFee = calcFeeLib.calculateFee(volume, minVolatility, sqrtPriceLimit);
        assertEq(minFee, 500); // Minimum fee expected

        oracle.setVolatility(maxVolatility);
        uint24 maxFee = calcFeeLib.calculateFee(volume, maxVolatility, sqrtPriceLimit);
        assertEq(maxFee, 10000); // Maximum fee expected
    }
}



contract MockVolatilityOracle {
    uint256 private volatility;

    function setVolatility(uint256 _volatility) external {
        volatility = _volatility;
    }

    function getVolatility() external view  returns (uint256) {
        return volatility;
    }
}
