// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PredictionMarketResponse {
    event MarketManipulationDetected(
        uint256 indexed marketId,
        address indexed manipulator,
        uint256 tradeSize,
        uint256 yesPriceChange,
        uint256 noPriceChange,
        uint256 timestamp
    );
    
    function executeManipulationResponse(
        uint256 marketId,
        address manipulator,
        uint256 tradeSize,
        uint256 yesPriceChange,
        uint256 noPriceChange
    ) external {
        emit MarketManipulationDetected(
            marketId,
            manipulator,
            tradeSize,
            yesPriceChange,
            noPriceChange,
            block.timestamp
        );
    }
}
