// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

/// @title CooldownStakingStorage
/// @notice Cononical storage layout for the Cooldown Staking protocol
/// @dev This contract defines the protocol state and invariants.

abstract contract CooldownStakinStorage {
    // STRUCTS
    /// @notice Represent a staking position in the protocol
    /// @dev A position is considered:
    ///     - inactive if amount == 0
    ///     - exiting if extitRequestTimestamp != 0
    struct StakePosition {
        uint256 amount;
        uint256 stakeTimestamp;
        uint256 exitRequestTimestamp;
    }

    // STORAGE
    /// @notice ERC20 token used for staking
    address internal immutable STAKIN_TOKEN;

    /// @notice Global cooldown duration required before exit
    uint256 internal immutable COOLDOWN_PERIOD;

    /// @notice Mapping of participant address to staking position
    mapping(address => StakePosition) internal _positions;

    // INVARIANTS
    /// @dev INVARIANT:
    ///     If position.amount == 0 then:
    ///         - position.stakeTimestamp == 0
    ///         - position.exitRequestTimestamp == 0
    /// @dev INVARIANT:
    ///     position.exitRequestTimestamp != 0 implies position.amount > 0
    /// @dev INVARIANT:
    ///     A participant can have at most one active position
    /// @dev INVARIANT:
    ///     Cooldown period is immutable and globally consistent
}