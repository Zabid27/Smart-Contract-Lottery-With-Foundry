// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test, CodeConstants {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    address public player = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 18 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(player, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        // arrange
        vm.prank(player);
        // act /Assert
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        // Arrange
        vm.prank(player);
        // ACt
        raffle.enterRaffle{value: entranceFee}();
        // Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == player);
    }

    function testEnteringRaffleEmitsEvent() public {
        // Arrange
        vm.prank(player);
        // Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(player);
        // Assert
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // Arrange
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
    }

    /*/////////////////////////////////////////////////////////////////////////
                                    CHECK UPKEEP
    ////////////////////////////////////////////////////////////////////////*/

    /**
     * This Test here is made to check the bool variable in the checkUpkeep function Raffle Contract that ==> bool hasBalance = address(this).balance > 0;
     */
    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        // Move the blockchain's timestamp forward by 'interval + 1' seconds to simulate the passage of time
        // This is done to test the contract's behavior after a certain period has passed
        vm.warp(block.timestamp + interval + 1);

        // Move the blockchain's block number forward by 1 block to simulate a new block being mined
        // This helps in testing the contract's response to changes in the blockchain state
        vm.roll(block.number + 1);

        // Act
        // Call the checkUpkeep function of the raffle contract with an empty data payload
        // The function should return a tuple with a boolean indicating if upkeep is needed and some other value
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        // Check that the upkeepNeeded boolean is false
        // This assertion confirms that when there is no balance, the checkUpkeep function correctly indicates that upkeep is not needed
        assert(upkeepNeeded == false); // assert(!upkeepNeeded)
    }

    function testCheckForEntranceFee() public view {
        console.log("get entrance fee is:", raffle.getEntranceFee());
        console.log("entrance fee:", entranceFee);
        assertEq(raffle.getEntranceFee(), entranceFee);
    }

    function testInitialEntranceFee() public view {
        uint256 fee = raffle.getEntranceFee();
        uint256 initialFee = entranceFee;
        assertEq(
            fee,
            initialFee,
            "Initial entrance fee should be set correctly"
        );
    }

    /**
     * This test should checkUpkeep would return false if raffle isnt open
     */
    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        // Arrange
        // Simulate a transaction from the 'player' address to enter the raffle with the required entrance fee
        // The 'vm.prank' function sets the next call to be from the specified address
        // 'raffle.enterRaffle{value: entranceFee}()' simulates the player entering the raffle with a fee
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();

        // Move the blockchain's timestamp forward by 'interval + 1' seconds to simulate the passage of time
        // This is done to test the behavior of the contract after the interval has passed
        vm.warp(block.timestamp + interval + 1);

        // Move the blockchain's block number forward by 1 block to simulate a new block being mined
        // This ensures the state of the contract is updated in the context of the latest block
        vm.roll(block.number + 1);

        // Manually perform upkeep on the raffle contract
        // 'raffle.performUpkeep("")' is called to execute any necessary state changes or actions
        // This setup is required to advance the raffle contract's state to simulate a real-world scenario
        raffle.performUpkeep("");

        // Act
        // Call the checkUpkeep function of the raffle contract with an empty data payload
        // The function should return a tuple with a boolean indicating if upkeep is needed and some other value
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        // Check that the upkeepNeeded boolean is false
        // This assertion confirms that the checkUpkeep function correctly indicates that upkeep is not needed if the raffle is not open
        assert(upkeepNeeded == false);
    }

    function testFulfillRandomWords() public view {
        // // Assume that the contract is in a state where players are already set
        // raffle.getPlayers(s_players); // Assuming you have a function to set players
        // raffle.setState(RaffleState.CLOSED); // Set the raffle state to CLOSED
        // address initialWinner = player2; // Based on the random number and modulo logic

        // // Simulate the call to fulfillRandomWords
        // uint256;
        // randomWords[0] = randomNumber;

        // // Perform the internal call
        // raffle.fulfillRandomWords(0, randomWords);

        // Assertions
        //assertEq(raffle.getRecentWinner(), initialWinner, "The recent winner should be correct");
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        // assertEq(raffle.getPlayersLength(), 0, "Players array should be empty after draw");
        assert(raffle.s_lastTimeStamp() == block.timestamp);
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act / Assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
        currentBalance = currentBalance + entranceFee;
        numPlayers = 1;

        //Arrange
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                rState
            )
        );
        raffle.performUpkeep("");
    }

    modifier raffleEntredAndTimePassed() {
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEntredAndTimePassed
    {
        // Arrange
        // vm.prank(player);
        // raffle.enterRaffle{value: entranceFee}();
        // vm.warp(block.timestamp + interval + 1);
        // vm.roll(block.number + 1);

        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        // requestId = raffle.getLastRequestId();
        assert(uint256(requestId) > 0);
        assert(uint(raffleState) == 1); // 0 = open, 1 = calculating
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep()
        public
        raffleEntredAndTimePassed
        skipFork
    {
        // Arrange
        // Act / Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        // vm.mockCall could be used here...
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            0,
            address(raffle)
        );

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            1,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksAWinnerRestesAndSendsMoney()
        public
        raffleEntredAndTimePassed
        skipFork
    {
        // Arrange

        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;
        address expectedWinner = address(1);

        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether); // hoax is like vm.deal (that gives an address some ether) and vm.prank(that sets a new fake address) altogether i.e vm.prank + vm.deal
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;

        // act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrants + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
