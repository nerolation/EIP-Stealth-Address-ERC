// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

import "./IStakeManager.sol";

/* solhint-disable avoid-low-level-calls */
/* solhint-disable not-rely-on-time */
/**
 * manage deposits and stakes.
 * deposit is just a balance used to pay for UserOperations (either by a paymaster or an account)
 * stake is value locked for at least "unstakeDelay" by a paymaster.
 */
abstract contract StakeManager is IStakeManager {

    /// maps paymaster to their deposits and stakes
    mapping(address => StakeInfo) public stakes;


    // internal method to return just the stake info
    function _getStakeInfo(address addr) internal view returns (StakeInfo memory info) {
        StakeInfo storage stakeInfo = stakes[addr];
        return stakeInfo;
    }

    /// return the deposit (for gas payment) of the account
    function balanceOf(address account) public view returns (uint256) {
        return stakes[account].stake;
    }

    receive() external payable {
        addStake(86400);
    }



    /**
     * add to the account's stake - amount and delay
     * any pending unstake is first cancelled.
     * @param unstakeDelaySec the new lock duration before the deposit can be withdrawn.
     */
    function addStake(uint32 unstakeDelaySec) public payable {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(unstakeDelaySec > 0, "must specify unstake delay");
        require(unstakeDelaySec >= stakeInfo.unstakeDelaySec, "cannot decrease unstake time");
        uint256 stake = stakeInfo.stake + msg.value;
        require(stake > 0, "no stake specified");
        require(stake <= type(uint112).max, "stake overflow");
        stakes[msg.sender] = StakeInfo(
            uint112(stake),
            true,
            unstakeDelaySec,
            0
        );
        emit StakeLocked(msg.sender, stake, unstakeDelaySec);
    }

    /**
     * attempt to unlock the stake.
     * the value can be withdrawn (using withdrawStake) after the unstake delay.
     */
    function unlockStake() external {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.unstakeDelaySec != 0, "not staked");
        require(stakeInfo.staked, "already unstaking");
        uint48 withdrawTime = uint48(block.timestamp) + stakeInfo.unstakeDelaySec;
        stakeInfo.withdrawTime = withdrawTime;
        stakeInfo.staked = false;
        emit StakeUnlocked(msg.sender, withdrawTime);
    }


    /**
     * withdraw from the (unlocked) stake.
     * must first call unlockStake and wait for the unstakeDelay to pass
     * @param withdrawAddress the address to send withdrawn value.
     */
    function withdrawStake(address payable withdrawAddress) external {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        uint256 stake = stakeInfo.stake;
        require(stake > 0, "No stake to withdraw");
        require(stakeInfo.withdrawTime > 0, "must call unlockStake() first");
        require(stakeInfo.withdrawTime <= block.timestamp, "Stake withdrawal is not due");
        stakeInfo.unstakeDelaySec = 0;
        stakeInfo.withdrawTime = 0;
        stakeInfo.stake = 0;
        emit StakeWithdrawn(msg.sender, withdrawAddress, stake);
        (bool success,) = withdrawAddress.call{value : stake}("");
        require(success, "failed to withdraw stake");
    }

}
