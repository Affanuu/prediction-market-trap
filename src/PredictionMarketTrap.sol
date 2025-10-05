// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ITrap.sol";

interface IPredictionMarket {
    struct Market {
        uint256 yesPrice;
        uint256 noPrice;
        uint256 totalVolume;
        uint256 lastTradeBlock;
        address lastTrader;
        uint256 lastTradeSize;
        bool resolved;
    }

    function getMarket(uint256 marketId) external view returns (Market memory);
}

/**
 * @title PredictionMarketTrap
 * @notice Drosera-compliant trap for detecting prediction market manipulation
 * @dev This version uses immutable state set at deployment for shadowfork compatibility
 */
contract PredictionMarketTrap is ITrap {
    IPredictionMarket public immutable predictionMarket;
    uint256 public immutable monitoredMarketId;

    // Thresholds for detecting manipulation (immutable for deterministic behavior)
    uint256 public constant PRICE_MANIPULATION_THRESHOLD = 200000; // 20% price change
    uint256 public constant VOLUME_SPIKE_THRESHOLD = 500; // 5x volume increase
    uint256 public constant SINGLE_TRADE_THRESHOLD = 10000e18; // Large single trade

    constructor(address _predictionMarket, uint256 _marketId) {
        predictionMarket = IPredictionMarket(_predictionMarket);
        monitoredMarketId = _marketId;
    }

    /**
     * @notice Collects current market state
     * @dev Called by Drosera operators to gather data for analysis
     * @return Encoded market data including prices, volume, and trade info
     */
    function collect() external view override returns (bytes memory) {
        IPredictionMarket.Market memory market = predictionMarket.getMarket(monitoredMarketId);

        return abi.encode(
            monitoredMarketId, // Include marketId in collected data
            market.yesPrice,
            market.noPrice,
            market.totalVolume,
            market.lastTrader,
            market.lastTradeSize,
            block.number
        );
    }

    /**
     * @notice Determines if manipulation has occurred (PURE - Drosera compliant)
     * @dev Analyzes passed data without reading contract state for deterministic behavior
     * @param data Array of encoded market states (newest first)
     * @return shouldRespond True if manipulation detected
     * @return responseData Encoded data for response contract
     */
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) return (false, "");

        // Decode previous state
        (
            uint256 marketId,
            uint256 prevYesPrice,
            uint256 prevNoPrice,
            uint256 prevVolume,
            , // prevTrader - unused
            , // prevTradeSize - unused
                // prevBlock - unused
        ) = abi.decode(data[1], (uint256, uint256, uint256, uint256, address, uint256, uint256));

        // Decode current state
        (
            , // marketId already decoded from prev
            uint256 currYesPrice,
            uint256 currNoPrice,
            uint256 currVolume,
            address currTrader,
            uint256 currTradeSize,
            // currBlock - unused
        ) = abi.decode(data[0], (uint256, uint256, uint256, uint256, address, uint256, uint256));

        // Check for price manipulation
        uint256 yesPriceDiff = currYesPrice > prevYesPrice ? currYesPrice - prevYesPrice : prevYesPrice - currYesPrice;
        uint256 noPriceDiff = currNoPrice > prevNoPrice ? currNoPrice - prevNoPrice : prevNoPrice - currNoPrice;

        bool priceManipulation =
            yesPriceDiff > PRICE_MANIPULATION_THRESHOLD || noPriceDiff > PRICE_MANIPULATION_THRESHOLD;

        // Check for volume manipulation
        bool volumeSpike = false;
        if (prevVolume > 0) {
            uint256 volumeIncrease = ((currVolume - prevVolume) * 100) / prevVolume;
            volumeSpike = volumeIncrease > VOLUME_SPIKE_THRESHOLD;
        }

        // Check for single large trade
        bool largeTrade = currTradeSize > SINGLE_TRADE_THRESHOLD;

        if (priceManipulation || volumeSpike || largeTrade) {
            return (
                true,
                abi.encode(marketId, currTrader, currTradeSize, yesPriceDiff, noPriceDiff, currVolume - prevVolume)
            );
        }

        return (false, "");
    }
}
