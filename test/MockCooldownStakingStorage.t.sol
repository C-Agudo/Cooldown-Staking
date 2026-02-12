// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

/// @title Mock storage for CooldownStaking
/// @notice Implements minimal storage required to test Core logic
contract MockCooldownStakingStorage {
    struct StakePosition {
        uint256 amount;
        uint256 stakeTimestamp;
        uint256 exitRequestTimestamp;
    }

    mapping(address => StakePosition) internal _positions;

    function stakedAmount(address user) external view returns (uint256) {
        return _positions[user].amount;
    }

    function exitRequestTimestamp(
        address user
    ) external view returns (uint256) {
        return _positions[user].exitRequestTimestamp;
    }

    function setPosition(
        address user,
        uint256 amount,
        uint256 stakeTime,
        uint256 exitTime
    ) external {
        _positions[user] = StakePosition(amount, stakeTime, exitTime);
    }
}
