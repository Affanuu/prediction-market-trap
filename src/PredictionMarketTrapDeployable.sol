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

contract PredictionMarketTrapDeployable is ITrap {
    // Updated with actual deployed address
    address public constant PREDICTION_MARKET = 0x61c7c5462eF0E8d1a2F01E22Aa0dCefb1Cf1F776;
    uint256 public constant MONITORED_MARKET_ID = 1;

    uint256 public constant PRICE_MANIPULATION_THRESHOLD = 200000; // 20%
    uint256 public constant VOLUME_SPIKE_THRESHOLD = 500; // 5x
    uint256 public constant SINGLE_TRADE_THRESHOLD = 10000e18;

    function collect() external view override returns (bytes memory) {
        try IPredictionMarket(PREDICTION_MARKET).getMarket(MONITORED_MARKET_ID) returns (
            IPredictionMarket.Market memory market
        ) {
            return abi.encode(
                market.yesPrice,
                market.noPrice,
                market.totalVolume,
                market.lastTrader,
                market.lastTradeSize,
                block.number
            );
        } catch {
            return abi.encode(
                uint256(600000), uint256(400000), uint256(100000e18), address(0x123), uint256(1000e18), block.number
            );
        }
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) return (false, "");

        (uint256 prevYes, uint256 prevNo,,,,) =
            abi.decode(data[1], (uint256, uint256, uint256, address, uint256, uint256));

        (uint256 currYes, uint256 currNo,, address currTrader, uint256 currTrade,) =
            abi.decode(data[0], (uint256, uint256, uint256, address, uint256, uint256));

        uint256 yesDiff = currYes > prevYes ? currYes - prevYes : prevYes - currYes;
        uint256 noDiff = currNo > prevNo ? currNo - prevNo : prevNo - currNo;

        bool priceManipulation = yesDiff > PRICE_MANIPULATION_THRESHOLD || noDiff > PRICE_MANIPULATION_THRESHOLD;
        bool largeTrade = currTrade > SINGLE_TRADE_THRESHOLD;

        if (priceManipulation || largeTrade) {
            return (true, abi.encode(MONITORED_MARKET_ID, currTrader, currTrade, yesDiff, noDiff));
        }

        return (false, "");
    }
}
