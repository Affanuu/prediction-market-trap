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
 *      Gas optimized with all fixes applied
 */
contract PredictionMarketTrap is ITrap {
    IPredictionMarket public immutable predictionMarket;
    uint256 public immutable monitoredMarketId;

    // Thresholds for detecting manipulation (immutable for deterministic behavior)
    uint256 public constant PRICE_MANIPULATION_THRESHOLD = 200000; // 20% price change
    uint256 public constant VOLUME_SPIKE_THRESHOLD = 400; // 5x volume increase (i.e., +400%)
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
     * @notice Determines if manipulation has occurred (PURE - Drosera compliant, GAS OPTIMIZED)
     * @dev Analyzes passed data without reading contract state for deterministic behavior
     *      
     *      Gas optimizations:
     *      - Early exit checks ordered by cost (cheapest first)
     *      - Unchecked arithmetic where overflow is impossible
     *      - Planner-safe guards for empty data blobs
     *      - Short-circuit evaluation to avoid expensive calculations
     * 
     * @param data Array of encoded market states (newest first)
     * @return shouldRespond True if manipulation detected
     * @return responseData Encoded data for response contract
     */
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        // Early exit: Need at least 2 data points
        if (data.length < 2) return (false, "");

        // Planner-safe guard: Check for empty data blobs before decoding
        if (data[0].length == 0 || data[1].length == 0) {
            return (false, "");
        }

        // Decode previous state
        (
            uint256 marketId,
            uint256 prevYes,
            uint256 prevNo,
            uint256 prevVolume,
            , // prevTrader - unused
            , // prevTradeSize - unused
            // prevBlock - unused
        ) = abi.decode(data[1], (uint256, uint256, uint256, uint256, address, uint256, uint256));

        // Decode current state
        (
            , // marketId already decoded from prev
            uint256 currYes,
            uint256 currNo,
            uint256 currVolume,
            address currTrader,
            uint256 currTradeSize,
            // currBlock - unused
        ) = abi.decode(data[0], (uint256, uint256, uint256, uint256, address, uint256, uint256));

        // ============ Detection Logic (Ordered by Gas Cost) ============

        // Check 1: Large single trade (cheapest - single comparison)
        if (currTradeSize > SINGLE_TRADE_THRESHOLD) {
            // Calculate price diffs for response data
            uint256 yesDiff;
            uint256 noDiff;
            unchecked {
                yesDiff = currYes > prevYes ? currYes - prevYes : prevYes - currYes;
                noDiff = currNo > prevNo ? currNo - prevNo : prevNo - currNo;
            }
            return (
                true,
                abi.encode(marketId, currTrader, currTradeSize, yesDiff, noDiff, currVolume - prevVolume)
            );
        }

        // ============ Price Manipulation Detection ============

        // Calculate price differences using unchecked (no overflow possible)
        uint256 yesDiff;
        uint256 noDiff;
        unchecked {
            yesDiff = currYes > prevYes ? currYes - prevYes : prevYes - currYes;
            noDiff = currNo > prevNo ? currNo - prevNo : prevNo - currNo;
        }

        // Check 2: Price manipulation (moderate cost - 2 comparisons)
        if (yesDiff > PRICE_MANIPULATION_THRESHOLD || noDiff > PRICE_MANIPULATION_THRESHOLD) {
            return (
                true,
                abi.encode(marketId, currTrader, currTradeSize, yesDiff, noDiff, currVolume - prevVolume)
            );
        }

        // ============ Volume Spike Detection ============

        // Check 3: Volume spike (most expensive - division operation)
        if (prevVolume > 0 && currVolume > prevVolume) {
            unchecked {
                // VOLUME_SPIKE_THRESHOLD = 400 means +400% (5x increase)
                uint256 volumeIncrease = ((currVolume - prevVolume) * 100) / prevVolume;
                
                if (volumeIncrease > VOLUME_SPIKE_THRESHOLD) {
                    return (
                        true,
                        abi.encode(marketId, currTrader, currTradeSize, yesDiff, noDiff, currVolume - prevVolume)
                    );
                }
            }
        }

        return (false, "");
    }
}
