// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

/**
 * @title A raffle Contract
 * @author Abidogun Abdulazeez
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRF 2.5
 */
contract Raffle {
    // State Variable
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {}

    function pickWinner() public {}

    /** Getter Functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
