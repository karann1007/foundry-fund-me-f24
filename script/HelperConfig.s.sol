//SPDX-License-Identifier: MIT

// Deploy a mock contract for local testing - we cannot make an alchemy call for testing again and again
// We need to keep track of address across different chains like SEPOLIA ETH/USD or mainnet ETH/USD

pragma solidity ^0.8.18;

import {Script} from '../lib/forge-std/src/Script.sol';
import { MockV3Aggregator } from '../test/mocks/MockV3Aggregator.t.sol';

contract HelperConfig is Script {
    // If we are on anvil , we deploy mocks
    // Otherwie , grab the existing address from the live network

    uint8 constant DECIMALS = 8;
    int256 constant INITIAL_PRICE = 2000e8;


    struct NetworkConfig {
        address priceFeed;
    }
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if(block.chainid == 11155111){
            activeNetworkConfig = getSepoliaEthConfig();
        } else if(block.chainid == 1){
            activeNetworkConfig = getmainnetEthConfig();
        } else {
            activeNetworkConfig = getorCreateAnvilEthConfig();
        }
    }

    function getmainnetEthConfig() public pure returns (NetworkConfig memory){
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed : 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return mainnetConfig;
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory){
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed : 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return sepoliaConfig;
    }

    function getorCreateAnvilEthConfig() public returns (NetworkConfig memory){
        // 1. Deploy a mock contract
        // 2. Return a mock address

        if(activeNetworkConfig.priceFeed != address(0)) {         // if already mock contract is up
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed : address(mockPriceFeed)
        });
        return anvilConfig;
    }
}