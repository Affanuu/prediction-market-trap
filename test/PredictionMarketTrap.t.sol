// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PredictionMarketTrap.sol";
import "../src/MockPredictionMarket.sol";

contract PredictionMarketTrapTest is Test {
    PredictionMarketTrap trap;
    MockPredictionMarket market;

    address constant TRADER = address(0x123);
    uint256 constant MARKET_ID = 1;

    function setUp() public {
        market = new MockPredictionMarket();
        trap = new PredictionMarketTrap(address(market), MARKET_ID);
    }

    function test_Collect() public view {
        bytes memory data = trap.collect();
        (uint256 yesPrice, uint256 noPrice, uint256 volume,,,) =
            abi.decode(data, (uint256, uint256, uint256, address, uint256, uint256));

        assertEq(yesPrice, 600000); // 0.6
        assertEq(noPrice, 400000); // 0.4
        assertGt(volume, 0);
    }

    function test_NoTrigger_NormalActivity() public {
        bytes memory prev = trap.collect();

        // Small trade - shouldn't trigger
        market.simulateTrade(MARKET_ID, TRADER, 100e18, true);

        bytes memory curr = trap.collect();

        bytes[] memory data = new bytes[](2);
        data[0] = curr;
        data[1] = prev;

        (bool should,) = trap.shouldRespond(data);
        assertFalse(should);
    }

    function test_Trigger_PriceManipulation() public {
        bytes memory prev = trap.collect();

        // Large trade causing significant price movement
        market.simulateManipulation(MARKET_ID);

        bytes memory curr = trap.collect();

        bytes[] memory data = new bytes[](2);
        data[0] = curr;
        data[1] = prev;

        (bool should, bytes memory response) = trap.shouldRespond(data);
        assertTrue(should);

        (uint256 marketId,, uint256 tradeSize,,) = abi.decode(response, (uint256, address, uint256, uint256, uint256));

        assertEq(marketId, MARKET_ID);
        assertGt(tradeSize, 0);
    }

    function test_Trigger_LargeSingleTrade() public {
        bytes memory prev = trap.collect();

        // Simulate large single trade
        market.simulateTrade(MARKET_ID, TRADER, 15000e18, true); // Above threshold

        bytes memory curr = trap.collect();

        bytes[] memory data = new bytes[](2);
        data[0] = curr;
        data[1] = prev;

        (bool should,) = trap.shouldRespond(data);
        assertTrue(should);
    }
}
