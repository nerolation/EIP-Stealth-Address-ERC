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

    /// maps paymaster to their deposits and stakes
    mapping(address => uint256) public stakes;

    /// return the deposit of the account
    function balanceOf(address account) public view returns (uint256) {
        return stakes[account];
    }

    receive() external payable {
        addStake();
    }

    /**
     * add to the account's stake - amount and delay
     * any pending unstake is first cancelled.
     */
    function addStake() public payable {
        require(msg.value > 0, "no value specified");
        stakes[msg.sender] += msg.value;
        emit StakeDeposit(msg.sender, msg.value);
    }

    /**
     * withdraw from the (unlocked) stake.
     * must first call unlockStake and wait for the unstakeDelay to pass
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
