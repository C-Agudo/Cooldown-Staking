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
        assertEq(coordinator.globalCooldown(), initialCooldown);
    }

    function testSetGlobalCooldown() public {
        uint256 newCooldown = 2 days;

        vm.expectEmit(true, false, false, true);
        emit CooldownUpdated(newCooldown);

        coordinator.setGlobalCooldown(newCooldown);

        assertEq(coordinator.globalCooldown(), newCooldown);
    }

    function testEarliestExit() public {
        uint256 requestTs = block.timestamp;
        assertEq(coordinator.earliestExit(requestTs), requestTs + initialCooldown);
    }

    function testIsCooldownOver() public {
        uint256 requestTs = block.timestamp;

        assertFalse(coordinator.isCooldownOver(requestTs));

        vm.warp(block.timestamp + initialCooldown + 1);

        assertTrue(coordinator.isCooldownOver(requestTs));
    }
}
