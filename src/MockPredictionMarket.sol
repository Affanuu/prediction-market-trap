// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockPredictionMarket {
    struct Market {
        uint256 yesPrice; // Price in wei (0-1000000 represents 0-1.0)
        uint256 noPrice;
        uint256 totalVolume;
        uint256 lastTradeBlock;
        address lastTrader;
        uint256 lastTradeSize;
        bool resolved;
    }

    mapping(uint256 => Market) public markets;
    uint256 public currentMarketId = 1;

    // Mock data for testing
    constructor() {
        // Initialize with realistic market data
        markets[1] = Market({
            yesPrice: 600000, // 0.6 price
            noPrice: 400000, // 0.4 price
            totalVolume: 100000e18,
            lastTradeBlock: block.number,
            lastTrader: address(0x123),
            lastTradeSize: 1000e18,
            resolved: false
        });
    }

    function getMarket(uint256 marketId) external view returns (Market memory) {
        return markets[marketId];
    }

    function simulateTrade(uint256 marketId, address trader, uint256 tradeSize, bool buyYes) public {
        // Changed from external to public
        Market storage market = markets[marketId];

        // Simulate price impact
        uint256 priceImpact = (tradeSize * 1000) / (market.totalVolume + 1);

        if (buyYes) {
            market.yesPrice += priceImpact;
            market.noPrice = 1000000 - market.yesPrice;
        } else {
            market.noPrice += priceImpact;
            market.yesPrice = 1000000 - market.noPrice;
        }

        market.totalVolume += tradeSize;
        market.lastTrader = trader;
        market.lastTradeSize = tradeSize;
        market.lastTradeBlock = block.number;
    }

    // Function to simulate market manipulation for testing
    function simulateManipulation(uint256 marketId) external {
        simulateTrade(marketId, msg.sender, 50000e18, true); // Large trade
    }
}
