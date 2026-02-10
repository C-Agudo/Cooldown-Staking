// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

/// @title ICooldownStaking
/// @notice Canonical interface for a cooldown-based staking protocol
/// @dev This interface defines the external contract of the protocol,
/// independent of implementation or storage layout.

interface ICooldownStaking {
    // EVENTS
    /// @notice Emitted when a user stakes tokens
    event Staked(address indexed user, uint256 amount);

    /// @notice Emitted when a user requests an exit (cooldown starts)
    event ExitRequested(address indexed user, uint256 timestamp);

    /// @notice Emitted when a user finalizes an exit and withdraws
    event ExitFinalized(address indexed user, uint256 amount);

    /// @notice Emitted when rewards are claimed
    event RewardsClaimed(address indexed user, uint256 amount);

    // ERRORS

    error ZeroAmount();
    error AlreadyStaking();
    error NotStaking();
    error CooldownNotElapsed();
    error ExitNotRequested();

    // EXTERNAL API

    /// @notice Stake a fixed or variable amount of tokens
    function stake(uint256 amount) external;

    /// @notice Request to exit staking (starts cooldown)
    function requestExit() external;

    /// @notice Finalize exit after cooldown and withdraw stake
    function finalizeExit() external;

    /// @notice Claim staking rewards
    function claimRewards() external;

    // VIEW FUNCTIONS

    /// @notice Returns the amount currently staked by a user
    function stakedAmount(address user) external view returns (uint256);

    /// @notice Returns the timestamp at which cooldown started
    function exitRequestTimestamp(address user) external view returns (uint256);

    /// @notice Returns the global cooldown duration
    function cooldownPeriod() external view returns (uint256);
}
