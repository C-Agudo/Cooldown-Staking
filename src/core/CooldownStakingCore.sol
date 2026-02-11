// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import "../storage/CooldownStakingStorage.sol";
import "../interfaces/ICooldownStaking.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title CooldownStakingCore
/// @notice Core logic for the CooldownStaking protocol
/// @dev Enforces rules defined in CooldownStakingStorage
contract CooldownStakingCore is CooldownStakingStorage, ICooldownStaking {
    using SafeERC20 for IERC20;

    constructor(
        address stakingToken_,
        address rewardToken_,
        uint256 cooldownPeriod_,
        uint256 rewardRate_
    ) {
        STAKING_TOKEN = stakingToken_;
        REWARD_TOKEN = rewardToken_;
        COOLDOWN_PERIOD = cooldownPeriod_;
        REWARD_RATE = rewardRate_;
    }

    /// @notice Stake a fixed amount into the protocol
    /// @param amount_ Amount of tokens to stake
    function stake(uint256 amount_) external {
        StakePosition storage position = _positions[msg.sender];

        // invariant: only one active position per participant
        require(position.amount == 0, "Already staking");

        position.amount = amount_;
        position.stakeTimestamp = block.timestamp;
        position.exitRequestTimestamp = 0;

        IERC20(STAKING_TOKEN).safeTransferFrom(
            msg.sender,
            address(this),
            amount_
        );
    }

    /// @notice Request to exit the protocol (starts cooldown)
    function requestExit() external {
        StakePosition storage position = _positions[msg.sender];

        // invariant: must have active stake
        require(position.amount > 0, "No active stake");
        // invariant: cannot request exit twice
        require(position.exitRequestTimestamp == 0, "Exit already requested");

        position.exitRequestTimestamp = block.timestamp;
    }

    /// @notice Finalize exit after cooldown period
    function finalizeExit() external {
        StakePosition storage position = _positions[msg.sender];

        require(position.amount > 0, "No active stake");
        require(position.exitRequestTimestamp > 0, "Exit not requested");
        require(
            block.timestamp >= position.exitRequestTimestamp + COOLDOWN_PERIOD,
            "Cooldown not over"
        );

        uint256 amountToReturn = position.amount;

        // reset position
        position.amount = 0;
        position.stakeTimestamp = 0;
        position.exitRequestTimestamp = 0;
        IERC20(STAKING_TOKEN).safeTransfer(msg.sender, amountToReturn);
    }

    /// @notice Returns the global cooldown period
    function cooldownPeriod() external view returns (uint256) {
        return COOLDOWN_PERIOD;
    }

    /// @notice Returns the current staking position of a participant
    function positionOf(
        address user_
    ) external view returns (StakePosition memory) {
        return _positions[user_];
    }

    /// @notice Claim accrued rewards
    function claimRewards() external override {
        StakePosition storage pos = _positions[msg.sender];
        require(pos.amount > 0, "No active stake");

        uint256 elapsed = block.timestamp - pos.stakeTimestamp;
        require(elapsed > 0, "Nothing to claim");

        // reward = amount * elapsed * REWARD_RATE / 1e18
        uint256 reward = (pos.amount * elapsed * REWARD_RATE) / 1e18;

        // update stake timestamp to avoid double counting
        pos.stakeTimestamp = block.timestamp;

        // transfer rewards
        IERC20(REWARD_TOKEN).safeTransfer(msg.sender, reward);
    }

    /// @notice Returns the staked amount of a participant
    /// @param user Participant address
    function stakedAmount(
        address user
    ) external view override returns (uint256) {
        return _positions[user].amount;
    }

    /// @notice Returns the exit request timestamp of a participant
    /// @param user Participant address
    function exitRequestTimestamp(
        address user
    ) external view override returns (uint256) {
        return _positions[user].exitRequestTimestamp;
    }
}
