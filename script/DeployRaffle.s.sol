// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Createsubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // local -> deploy mocks, get local congig
        // sepolia -> get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            //create subscription
            Createsubscription createSubscription = new Createsubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSubscription
                .createSubscription(config.vrfCoordinator, config.account);
        }

        //FundSubscription
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(
            config.vrfCoordinator,
            config.subscriptionId,
            config.link,
            config.account
        );

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        // don"t broadcast coz we've already broadcast in AddConsumer in Interactions
        addConsumer.addConsumer(
            address(raffle),
            config.vrfCoordinator,
            config.subscriptionId,
            config.account
        );
        return (raffle, helperConfig);
    }
}
