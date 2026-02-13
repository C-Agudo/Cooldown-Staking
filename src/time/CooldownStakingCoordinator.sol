// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

/// @title CooldownCoordinator
/// @notice Handles cooldowns and time coordination for the CooldownStaking protocol
/// @dev Separates temporal logic from Core to simplify auditing and upgrades
contract CooldownCoordinator {
    /// @notice Global cooldown in seconds applied to all staking positions
    uint256 public globalCooldown;

    /// @notice Emitted when the global cooldown is updated
    event CooldownUpdated(uint256 newCooldown);

    /// @param initialCooldown Initial cooldown value in seconds
    constructor(uint256 initialCooldown) {
        globalCooldown = initialCooldown;
    }

    /// @notice Updates the global cooldown
    /// @param newCooldown New cooldown period in seconds
    function setGlobalCooldown(uint256 newCooldown) external {
        // In a real protocol this should be restricted to owner/governance
        globalCooldown = newCooldown;
        emit CooldownUpdated(newCooldown);
    }

    /// @notice Returns the earliest timestamp a user can finalize exit
    /// @param requestTimestamp Timestamp when exit was requested
    /// @return earliestExitTimestamp Minimum timestamp allowed for exit
    function earliestExit(uint256 requestTimestamp) external view returns (uint256) {
        return requestTimestamp + globalCooldown;
    }

    /// @notice Checks if the cooldown period is over for a given request
    /// @param requestTimestamp Timestamp when exit was requested
    /// @return true if cooldown has finished, false otherwise
    function isCooldownOver(uint256 requestTimestamp) external view returns (bool) {
        return block.timestamp >= requestTimestamp + globalCooldown;
    }
}
