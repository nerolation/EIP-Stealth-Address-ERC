// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

import "./IStakeManager.sol";

/* solhint-disable avoid-low-level-calls */
/* solhint-disable not-rely-on-time */
/**
 * manage stakes.
 * stake is value deposited that can be withdrawn at any time.
 */
abstract contract StakeManager is IStakeManager {

    /// maps paymaster to their stakes
    mapping(address => uint256) public stakes;

    /// return the stake of the account
    function balanceOf(address account) public view returns (uint256) {
        return stakes[account];
    }

    receive() external payable {
        addStake(msg.sender);
    }

    /**
     * add to the account's stake - amount 
     * @param staker the address of the staker.
     */
    function addStake(address staker) public payable {
        require(msg.value > 0, "invalid amount");
        stakes[staker] += msg.value;
        emit StakeDeposit(staker, msg.value);
    }

    /**
     * withdraw the stake.
     * @param withdrawAddress the address to send withdrawn value.
     */
    function withdrawStake(address payable withdrawAddress) external {
        uint256 stake = stakes[msg.sender];
        require(stake > 0, "No stake to withdraw");
        stakes[msg.sender] = 0;
        emit StakeWithdrawal(msg.sender, withdrawAddress, stake);
        (bool success,) = withdrawAddress.call{value : stake}("");
        require(success, "failed to withdraw stake");
    }

}
