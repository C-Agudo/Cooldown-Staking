// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {ICooldownStaking} from "./interfaces/ICooldownStaking.sol";
import {CooldownStakingCore} from "./core/CooldownStakingCore.sol";
import {CooldownStakingStorage} from "./storage/CooldownStakingStorage.sol";
import {CooldownCoordinator} from "./time/CooldownStakingCoordinator.sol";

/// @title CooldownStaking
/// @notice Facade contract that connects Core, Storage and Coordinator
/// @dev Provides a clean entry point for users while keeping protocol layers separated
contract CooldownStaking is ICooldownStaking {
    /// @notice Core logic contract
    CooldownStakingCore public core;

    /// @notice Storage contract
    CooldownStakingStorage public storageContract;

    /// @notice Coordinator contract
    CooldownCoordinator public coordinator;

    /// @param core_ Core logic contract
    /// @param storage_ Storage contract
    /// @param coordinator_ Coordinator contract
    constructor(
        CooldownStakingCore core_,
        CooldownStakingStorage storage_,
        CooldownCoordinator coordinator_
    ) {
        core = core_;
        storageContract = storage_;
        coordinator = coordinator_;
    }

    /// @notice Stake tokens
    /// @param amount Amount to stake
    function stake(uint256 amount) external override {
        core.stake(amount);
    }

    /// @notice Request exit from staking
    function requestExit() external override {
        core.requestExit();
    }

    /// @notice Finalize exit after cooldown
    function finalizeExit() external override {
        core.finalizeExit();
    }

    /// @notice Claim rewards accumulated
    function claimRewards() external override {
        core.claimRewards();
    }

    /// @notice Expose the global cooldown
    /// @return globalCooldownValue The current global cooldown in seconds
    function globalCooldown() external view returns (uint256) {
        return coordinator.globalCooldown();
    }

    /// @notice Returns the amount staked by a user
    /// @param user User address
    /// @return stakedAmountValue Amount currently staked
    function stakedAmount(address user) external view override returns (uint256) {
        return core.stakedAmount(user);
    }

    /// @notice Returns the timestamp when the user requested exit
    /// @param user User address
    /// @return exitTimestamp Timestamp of exit request
    function exitRequestTimestamp(address user) external view override returns (uint256) {
        return core.exitRequestTimestamp(user);
    }

    /// @notice Returns the global cooldown period in seconds
    /// @return cooldownPeriodValue Current cooldown period
    function cooldownPeriod() external view override returns (uint256) {
        return coordinator.globalCooldown();
    }
}
