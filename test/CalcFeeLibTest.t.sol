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
        uint256 volume = 1 ether;
        // 1 ether unit of sETH is 3500 USDC in this scenario, same as the notebooks in the volatility_substream
        uint160 sqrtPriceLimit = 4687201305027700855787468357632;
    
        for (uint i = 0; i < newRvValues.length; i+=1) {    
        oracle.setVolatility(newRvValues[i]);
        bytes memory data = abi.encode(volume, sqrtPriceLimit);

        uint24 fee = calcFeeLib.getFee(data);
        console.log("fee in bips", fee);
        }
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
