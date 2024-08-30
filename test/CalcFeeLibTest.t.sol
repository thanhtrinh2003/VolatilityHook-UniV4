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

    function arrayToJson(uint24[] memory fees) internal pure returns (string memory) {
        string memory json = "[";
        for (uint i = 0; i < fees.length; i++) {
            json = string(abi.encodePacked(json, uint2str(fees[i])));
            if (i < fees.length - 1) {
                json = string(abi.encodePacked(json, ","));
            }
        }
        json = string(abi.encodePacked(json, "]"));
        return json;
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
            if (_i == 0) {
                return "0";
            }
            uint256 j = _i;
            uint256 length;
            while (j != 0) {
                length++;
                j /= 10;
            }
            bytes memory bstr = new bytes(length);
            uint256 k = length;
            while (_i != 0) {
                bstr[--k] = bytes1(uint8(48 + _i % 10));
                _i /= 10;
            }
            return string(bstr);
        }

    function test_CalculateFee() public {
        uint256 volume = 1 ether;
        // 1 ether unit of sETH is 3700 USDC in this scenario, same as the notebooks in the volatility_substream
        uint160 sqrtPriceLimit = 4819260982861451157002617094144;
        uint24[] memory fees = new uint24[](newRvValues.length);


        for (uint i = 0; i < newRvValues.length; i+=1) {    
        oracle.setVolatility(newRvValues[i]);

        bytes memory data = abi.encode(volume, sqrtPriceLimit);

        uint24 fee = calcFeeLib.getFee(data);
        fees[i] = fee;

        }


        string memory jsonArray = arrayToJson(fees);
        string[] memory cmds = new string[](3);
        cmds[0] = "bash";
        cmds[1] = "-c";
        cmds[2] = string(abi.encodePacked("echo '", jsonArray, "' > ./notes/fees.json"));
        
        vm.ffi(cmds);
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
