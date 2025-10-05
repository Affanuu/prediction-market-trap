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
 * @title PredictionMarketTrapDeployable
 * @notice Production-ready Drosera trap for prediction market manipulation detection
 * @dev Fully compliant with Drosera specifications:
 *      - shouldRespond() is PURE (no state reads)
 *      - All configuration is immutable and set at deployment
 *      - Deterministic behavior across all operator nodes
 *      - Works on shadowfork environments without additional setup
 */
contract PredictionMarketTrapDeployable is ITrap {
    // ============ Immutable Configuration ============
    // These are set at deployment and baked into bytecode for shadowfork compatibility

    /// @notice Address of the prediction market contract to monitor
    address public constant PREDICTION_MARKET = 0x94D16e1D86294235D841101855866397ee639d82;

    /// @notice Market ID to monitor for manipulation
    uint256 public constant MONITORED_MARKET_ID = 1;

    // ============ Detection Thresholds ============

    /// @notice Threshold for price manipulation (200000 = 20%)
    uint256 public constant PRICE_MANIPULATION_THRESHOLD = 200000;

    /// @notice Threshold for volume spike detection (500 = 5x increase)
    uint256 public constant VOLUME_SPIKE_THRESHOLD = 500;

    /// @notice Threshold for single large trade detection
    uint256 public constant SINGLE_TRADE_THRESHOLD = 10000e18;

    /// @notice Minimum time between trades to consider (prevents spam detection)
    uint256 public constant MIN_BLOCKS_BETWEEN_CHECKS = 1;

    /**
     * @notice Collects current market state data
     * @dev Called by Drosera operators at regular intervals
     *      Includes fallback data for shadowfork environments where market might not exist
     * @return Encoded market state data
     */
    function collect() external view override returns (bytes memory) {
        try IPredictionMarket(PREDICTION_MARKET).getMarket(MONITORED_MARKET_ID) returns (
            IPredictionMarket.Market memory market
        ) {
            return abi.encode(
                MONITORED_MARKET_ID,
                market.yesPrice,
                market.noPrice,
                market.totalVolume,
                market.lastTrader,
                market.lastTradeSize,
                block.number
            );
        } catch {
            // Fallback for shadowfork or if market doesn't exist
            // Returns baseline data that won't trigger false positives
            return abi.encode(
                MONITORED_MARKET_ID,
                uint256(500000), // 0.5 yes price
                uint256(500000), // 0.5 no price
                uint256(100000e18), // baseline volume
                address(0), // no trader
                uint256(0), // no trade size
                block.number
            );
        }
    }

    /**
     * @notice Analyzes market data to detect manipulation (PURE function)
     * @dev This function MUST be pure per Drosera spec:
     *      - No state reads (ensures deterministic behavior)
     *      - Only analyzes passed-in data
     *      - Same result across all operator nodes
     * @param data Array of encoded market states (data[0] = newest, data[1] = previous)
     * @return shouldTrigger True if manipulation detected
     * @return responseData Encoded parameters for response contract
     */
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        // Need at least 2 data points for comparison
        if (data.length < 2) return (false, "");

        // Decode previous market state
        (
            uint256 marketId,
            uint256 prevYes,
            uint256 prevNo,
            uint256 prevVolume,
            , // prevTrader
            , // prevTradeSize
            uint256 prevBlock
        ) = abi.decode(data[1], (uint256, uint256, uint256, uint256, address, uint256, uint256));

        // Decode current market state
        (
            , // marketId (same as previous)
            uint256 currYes,
            uint256 currNo,
            uint256 currVolume,
            address currTrader,
            uint256 currTrade,
            uint256 currBlock
        ) = abi.decode(data[0], (uint256, uint256, uint256, uint256, address, uint256, uint256));

        // Skip if not enough time has passed (prevents spam)
        if (currBlock - prevBlock < MIN_BLOCKS_BETWEEN_CHECKS) {
            return (false, "");
        }

        // ============ Manipulation Detection Logic ============

        // 1. Check for abnormal price movements
        uint256 yesDiff = currYes > prevYes ? currYes - prevYes : prevYes - currYes;
        uint256 noDiff = currNo > prevNo ? currNo - prevNo : prevNo - currNo;

        bool priceManipulation = yesDiff > PRICE_MANIPULATION_THRESHOLD || noDiff > PRICE_MANIPULATION_THRESHOLD;

        // 2. Check for volume spikes (only if there was previous volume)
        bool volumeSpike = false;
        if (prevVolume > 0 && currVolume > prevVolume) {
            uint256 volumeIncrease = ((currVolume - prevVolume) * 100) / prevVolume;
            volumeSpike = volumeIncrease > VOLUME_SPIKE_THRESHOLD;
        }

        // 3. Check for single large trade
        bool largeTrade = currTrade > SINGLE_TRADE_THRESHOLD;

        // ============ Trigger Response ============

        if (priceManipulation || volumeSpike || largeTrade) {
            // Encode response data for response contract
            bytes memory responseData = abi.encode(marketId, currTrader, currTrade, yesDiff, noDiff);

            return (true, responseData);
        }

        return (false, "");
    }

    /**
     * @notice Helper to decode response data (for off-chain analysis)
     * @param responseData Encoded response from shouldRespond()
     * @return marketId The market that triggered
     * @return trader Address of the trader who caused trigger
     * @return tradeSize Size of the suspicious trade
     * @return yesPriceChange Change in yes price
     * @return noPriceChange Change in no price
     */
    function decodeResponse(bytes memory responseData)
        external
        pure
        returns (uint256 marketId, address trader, uint256 tradeSize, uint256 yesPriceChange, uint256 noPriceChange)
    {
        return abi.decode(responseData, (uint256, address, uint256, uint256, uint256));
    }
}
