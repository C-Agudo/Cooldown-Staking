// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import "../src/storage/CooldownStakingStorage.sol";

contract MockCooldownStakingStorage is CooldownStakingStorage {
    constructor(address stakingToken_, address rewardToken_, uint256 cooldown_, uint256 rewardRate_) {
        STAKING_TOKEN = stakingToken_;
        REWARD_TOKEN = rewardToken_;
        COOLDOWN_PERIOD = cooldown_;
        REWARD_RATE = rewardRate_;
    }

    function setPosition(address user, uint256 amount, uint256 stakeTimestamp, uint256 exitRequestTimestamp) external {
        _positions[user] = StakePosition(amount, stakeTimestamp, exitRequestTimestamp);
    }

    function getPosition(address user) external view returns (StakePosition memory) {
        return _positions[user];
    }

    function getStakingToken() external view returns (address) {
        return STAKING_TOKEN;
    }

    function getRewardToken() external view returns (address) {
        return REWARD_TOKEN;
    }

    function getCooldownPeriod() external view returns (uint256) {
        return COOLDOWN_PERIOD;
    }

    function getRewardRate() external view returns (uint256) {
        return REWARD_RATE;
    }
}
