// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

/**
 * manage deposits and stakes.
 * stake is value deposited that can be withdrawn at any time.
 */
interface IStakeManager {

    /// Emitted when stake is deposited
    event StakeDeposit(
        address indexed account,
        uint256 totalStaked
    );

    event StakeWithdrawal(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /// return the stake of the account
    function balanceOf(address account) external view returns (uint256);

    /**
     * add to the account's stake - amount 
     * @param staker the address of the staker.
     */
    function addStake(address staker) external payable;

    /**
     * withdraw the stake.
     * @param withdrawAddress the address to send withdrawn value.
     */
    function withdrawStake(address payable withdrawAddress) external;
}
