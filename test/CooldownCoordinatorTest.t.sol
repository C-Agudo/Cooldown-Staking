// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import "forge-std/Test.sol";
import {CooldownCoordinator} from "../src/time/CooldownStakingCoordinator.sol";

contract CooldownCoordinatorTest is Test {
    CooldownCoordinator coordinator;

    uint256 initialCooldown = 1 days;

    event CooldownUpdated(uint256 newCooldown);

    function setUp() public {
        coordinator = new CooldownCoordinator(initialCooldown);
    }

    function testInitialCooldown() public {
        uint256 cooldown = coordinator.globalCooldown();
        assertEq(cooldown, initialCooldown);
    }

    function testSetGlobalCooldownUpdatesValue() public {
        uint256 newCooldown = 2 days;

        vm.expectEmit(true, false, false, true);
        emit CooldownUpdated(newCooldown);

        coordinator.setGlobalCooldown(newCooldown);

        assertEq(coordinator.globalCooldown(), newCooldown);
    }

    function testEarliestExitReturnsCorrectTimestamp() public {
        uint256 requestTs = block.timestamp;
        uint256 expected = requestTs + initialCooldown;

        uint256 result = coordinator.earliestExit(requestTs);
        assertEq(result, expected);
    }

    function testIsCooldownOverFalseBeforeTime() public {
        uint256 requestTs = block.timestamp;

        bool ready = coordinator.isCooldownOver(requestTs);
        assertFalse(ready);
    }

    function testIsCooldownOverTrueAfterTime() public {
        uint256 requestTs = block.timestamp;

        // Warp past cooldown
        vm.warp(block.timestamp + initialCooldown + 1);

        bool ready = coordinator.isCooldownOver(requestTs);
        assertTrue(ready);
    }
}
