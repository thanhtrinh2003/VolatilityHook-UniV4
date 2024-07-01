pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {Currency, CurrencyLibrary} from "@v4-core/types/Currency.sol";
import {LPFeeLibrary} from "@v4-core/libraries/LPFeeLibrary.sol";
import {Hooks} from "@v4-core/libraries/Hooks.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@v4-core/types/PoolId.sol";
import {PoolSwapTest} from "@v4-core/test/PoolSwapTest.sol";
import {TickMath} from "@v4-core/libraries/TickMath.sol";
import {OracleBasedFeeHook} from "../src/OracleBasedFeeHook.sol";
import {OracleBasedFeeHookImp} from "./implementation/OracleBasedFeeHookImp.sol";
import {FeeOracle} from "../src/FeeOracle.sol";
import {SnarkBasedFeeOracle} from "../src/SnarkBasedFeeOracle.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {HookMiner} from "contracts/utils/HookMiner.sol";
import {BalanceDelta} from "@v4-core/types/BalanceDelta.sol";

import {console} from "forge-std/console.sol";


struct SP1ProofFixtureJson {
    int64 s2;
    int64 s;
    uint64 n;
    uint64 nInvSqrt;
    uint64 n1Inv;
    bytes32 digest;
    bytes publicValues;
    bytes proof;
    bytes32 vkey;
}
contract TestOracleBasedFeeHook is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using stdJson for string;
    OracleBasedFeeHook hook;
    SnarkBasedFeeOracle oracle;
    PoolId poolId;

    address oracleOwner = address(1);

    function loadFixture(string memory fixture_path) public view returns (SP1ProofFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, fixture_path);
        string memory json = vm.readFile(path);

        // Decode individual fields
        SP1ProofFixtureJson memory fixture;
        fixture.s2 = abi.decode(json.parseRaw(".s2"), (int64));
        fixture.s = abi.decode(json.parseRaw(".s"), (int64));
        fixture.n = abi.decode(json.parseRaw(".n"), (uint64));
        fixture.nInvSqrt = abi.decode(json.parseRaw(".nInvSqrt"), (uint64));
        fixture.n1Inv = abi.decode(json.parseRaw(".n1Inv"), (uint64));
        fixture.digest = abi.decode(json.parseRaw(".digest"), (bytes32));
        fixture.publicValues = abi.decode(json.parseRaw(".publicValues"), (bytes));
        fixture.proof = abi.decode(json.parseRaw(".proof"), (bytes));
        fixture.vkey = abi.decode(json.parseRaw(".vkey"), (bytes32));

        return fixture;
    }
    function setUp() public {
        // creates the pool manager, utility routers, and test tokens
        Deployers.deployFreshManagerAndRouters();
        Deployers.deployMintAndApprove2Currencies();

        // Deploy the hook to an address with the correct flags
        address flags = address(uint160(Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG));
        bytes32 programKey = 0x0006adb3831affa6e27ba51eea3a95b6339057ff9938311a68739bb8d5f5aef4;
        oracle = new SnarkBasedFeeOracle(programKey);


        deployCodeTo("OracleBasedFeeHook.sol:OracleBasedFeeHook", abi.encode(manager, oracle), flags);
    
        hook = OracleBasedFeeHook(flags);


        // Create the pool
             // Initialize a pool
        (key, ) = initPool(
            currency0, 
            currency1, 
            hook,
            LPFeeLibrary.DYNAMIC_FEE_FLAG, 
            SQRT_PRICE_1_1,
            ZERO_BYTES
        );
        poolId = key.toId();

        // Provide full-range liquidity to the pool
        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams(TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10_000 ether, 0),
            ZERO_BYTES
        );
    }



    function test_feeUpdate() public {
        // positions were created in setup()
        SP1ProofFixtureJson memory fixture = loadFixture("/src/fixtures/fixture.json");
        oracle.verifyAndUpdate(uint256(uint64(fixture.s)), fixture.proof, fixture.publicValues);
        // TODO: assert fees before setFee()

        // Perform a test swap //
        bool zeroForOne = true;
        int256 amountSpecified = -1e18; // negative number indicates exact input swap!
        BalanceDelta swapDelta = swap(key, zeroForOne, amountSpecified, ZERO_BYTES);
        // ------------------- //

        // //TODO: assert correct fee was applied to swap, with another swap

        assertEq(int256(swapDelta.amount0()), amountSpecified);

    }

    // function test_feeUpdated() public {
    //     SP1ProofFixtureJson memory fixture = loadFixture();

    //     // Set up swap parameters
    //     PoolSwapTest.TestSettings memory testSettings = PoolSwapTest.TestSettings({
    //         takeClaims : false, 
    //         settleUsingBurn : false
    //     });

    //     IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
    //         zeroForOne: true,
    //         amountSpecified: -0.00001 ether,
    //         sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
    //     });

    //     // 0: Conduct a swap before volatility has been updated 
    //     console.log("Case 1: Conduct a swap when oracle set fee at 0% `(0`)");

    //     hoax(oracleOwner, oracleOwner);
    //     oracle.setPrice(0);

    //     hoax(oracleOwner, oracleOwner);
    //     oracle.setVolatility(0);

    //     uint256 balanceOfToken1Before = currency1.balanceOfSelf();
    //     swapRouter.swap(key, params, testSettings, ZERO_BYTES);
    //     uint256 balanceOfToken1After = currency1.balanceOfSelf();
    //     uint256 outputFromFeeSwap = balanceOfToken1After - balanceOfToken1Before;

    //     console.log("Balance of token1 before swap: ", balanceOfToken1Before);
    //     console.log("Balance of token1 after swap: ", balanceOfToken1After);

    //     assertGt(balanceOfToken1After, balanceOfToken1Before);
    //     console.log("Output from fee swap: ", outputFromFeeSwap);

    //     // 1: Conduct a swap after volatility has been updated 
    //     console.log("Case 1: Conduct a swap when oracle set fee at 0.5% `(5000`)");

    //     hoax(oracleOwner, oracleOwner);
        
    //     oracle.verifyAndUpdate(uint256(uint64(fixture.s)), fixture.proof, fixture.publicValues;
    //     balanceOfToken1Before = currency1.balanceOfSelf();
    //     swapRouter.swap(key, params, testSettings, ZERO_BYTES);
    //     balanceOfToken1After = currency1.balanceOfSelf();
    //     outputFromFeeSwap = balanceOfToken1After - balanceOfToken1Before;

    //     console.log("Balance of token1 before swap: ", balanceOfToken1Before);
    //     console.log("Balance of token1 after swap: ", balanceOfToken1After);

    //     assertGt(balanceOfToken1After, balanceOfToken1Before);
    //     console.log("Output from fee swap: ", outputFromFeeSwap);

    // }

    // function testFindSalt () public {
    //     address poolManager = 0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14;
    //     address feeOracle = 0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14;

    //     //Deploy hook
    //      uint160 flags = uint160(
    //         Hooks.BEFORE_INITIALIZE_FLAG |  
    //         Hooks.BEFORE_SWAP_FLAG
    //     );

    //     (, bytes32 salt) = HookMiner.find(
    //         address(this),
    //         flags,
    //         type(OracleBasedFeeHook).creationCode,
    //         abi.encodePacked(IPoolManager(poolManager), address(feeOracle))
    //     );

    //     string memory saltStr = string(abi.encodePacked(salt));
    //     console.log("Salt: ", saltStr);
    // }

}
