// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.19;

// import {Test} from "forge-std/Test.sol";
// import {DeployRaffle} from "script/DeployRaffle.s.sol";
// import {HelperConfig} from "script/HelperConfig.s.sol";
// import {Createsubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
// import {Raffle} from "src/Raffle.sol";
// import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
// import {LinkToken} from "test/mocks/LinkToken.sol";

// contract IntegrationTest is Test {
//     DeployRaffle deployRaffle;
//     Raffle raffle;
//     HelperConfig helperConfig;
//     Createsubscription createSubscription;
//     FundSubscription fundSubscription;
//     AddConsumer addConsumer;
//     HelperConfig.NetworkConfig config;

//     function setUp() public {
//         // Set up the DeployRaffle script and deploy the contract
//         deployRaffle = new DeployRaffle();
//         (raffle, helperConfig) = deployRaffle.deployContract();

//         // Initialize scripts for further interactions
//         createSubscription = new Createsubscription();
//         fundSubscription = new FundSubscription();
//         addConsumer = new AddConsumer();

//         // Fetch the configuration
//         config = helperConfig.getConfig();
//     }

//     function testDeployment() public {
//         // Check that the Raffle contract was deployed
//         assert(address(raffle) != address(0));

//         // Validate the initial state of the Raffle contract
//         assert(raffle.getEntranceFee() == config.entranceFee);
//         assert(uint256(raffle.getRaffleState()) == uint256(0)); // RaffleState.OPEN is 0
//         assert(raffle.getLastTimeStamp() == block.timestamp);
//     }

//     function testCreateSubscription() public {
//         // Create a new subscription and validate the subscription ID
//         (uint256 subId, address vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator, config.account);
//         assert(subId == config.subscriptionId);
//         assert(vrfCoordinator == config.vrfCoordinator);
//     }

//     // function testFundSubscription() public {
//     //     // Fund the subscription and verify that the LINK balance of the subscription is correct
//     //     fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link, config.account);

//     //     VRFCoordinatorV2_5Mock vrfCoordinatorMock = VRFCoordinatorV2_5Mock(config.vrfCoordinator);
//     //     uint96 balance = vrfCoordinatorMock.getSubscriptionBalance(config.subscriptionId);
//     //     assert(balance == uint96(3 ether)); // Assumes FUND_AMOUNT is 3 LINK
//    // }

//     // function testAddConsumer() public {
//     //     // Add the Raffle contract as a consumer and verify it is added
//     //     addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId, config.account);

//     //     VRFCoordinatorV2_5Mock vrfCoordinatorMock = VRFCoordinatorV2_5Mock(config.vrfCoordinator);
//     //     address[] memory consumers = vrfCoordinatorMock.getSubscriptionConsumers(config.subscriptionId);

//     //     // Verify that the raffle contract is one of the consumers
//     //     bool isConsumer = false;
//     //     for (uint256 i = 0; i < consumers.length; i++) {
//     //         if (consumers[i] == address(raffle)) {
//     //             isConsumer = true;
//     //             break;
//     //         }
//     //     }
//     //     assertTrue(isConsumer);
//     // }

//     function testFullDeploymentFlow() public {
//         // Complete the full deployment and setup flow, then validate the setup
//         DeployRaffle deployScript = new DeployRaffle();
//         (Raffle newRaffle, HelperConfig newHelperConfig) = deployScript.deployContract();

//         // Create, fund, and add the consumer in sequence
//         createSubscription.createSubscription(newHelperConfig.getConfig().vrfCoordinator, newHelperConfig.getConfig().account);
//         fundSubscription.fundSubscription(newHelperConfig.getConfig().vrfCoordinator, newHelperConfig.getConfig().subscriptionId, newHelperConfig.getConfig().link, newHelperConfig.getConfig().account);
//         addConsumer.addConsumer(address(newRaffle), newHelperConfig.getConfig().vrfCoordinator, newHelperConfig.getConfig().subscriptionId, newHelperConfig.getConfig().account);

//         // Validate that the new Raffle contract was correctly initialized
//         assert(newRaffle.getEntranceFee() == newHelperConfig.getConfig().entranceFee);
//         assert(uint256(newRaffle.getRaffleState()) == uint256(0)); // RaffleState.OPEN
//         assert(newRaffle.getLastTimeStamp() == block.timestamp);
//     }
// }