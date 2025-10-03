// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PredictionMarketTrap.sol";
import "../src/MockPredictionMarket.sol";
import "../src/PredictionMarketResponse.sol";

contract DeployPredictionMarketTrap is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy mock prediction market
        MockPredictionMarket market = new MockPredictionMarket();
        console.log("MockPredictionMarket deployed at:", address(market));

        // Deploy trap
        PredictionMarketTrap trap = new PredictionMarketTrap(address(market), 1);
        console.log("PredictionMarketTrap deployed at:", address(trap));

        // Deploy response contract
        PredictionMarketResponse response = new PredictionMarketResponse();
        console.log("PredictionMarketResponse deployed at:", address(response));

        vm.stopBroadcast();
    }
}
