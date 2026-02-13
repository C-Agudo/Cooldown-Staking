// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import "forge-std/Test.sol";
import {CooldownStakingCore} from "../src/core/CooldownStakingCore.sol";
import {MockERC20} from "./MockERC20.t.sol";

contract CooldownStakingCoreTest is Test {
    CooldownStakingCore core;
    MockERC20 stakingToken;
    MockERC20 rewardToken;

    address user = vm.addr(1);

    uint256 cooldownPeriod = 1 days;
    uint256 rewardRate = 1e18;

    function setUp() public {
        stakingToken = new MockERC20("StakeToken", "STK");
        rewardToken = new MockERC20("RewardToken", "RWD");

        core = new CooldownStakingCore(
            address(stakingToken),
            address(rewardToken),
            cooldownPeriod,
            rewardRate
        );

        rewardToken.mint(address(core), 1_000_000 ether);
        stakingToken.mint(user, 1_000 ether);
    }

    function testStake() public {
        vm.startPrank(user);
        stakingToken.approve(address(core), 100 ether);
        core.stake(100 ether);

        assertEq(core.stakedAmount(user), 100 ether);
        vm.stopPrank();
    }

    function testStakeZeroReverts() public {
        vm.startPrank(user);
        vm.expectRevert("Zero amount");
        core.stake(0);
        vm.stopPrank();
    }

    function testDoubleStakeReverts() public {
        vm.startPrank(user);
        stakingToken.approve(address(core), 200 ether);

        core.stake(100 ether);

        vm.expectRevert("Already staking");
        core.stake(50 ether);
        vm.stopPrank();
    }

    function testRequestExitAndFinalize() public {
        vm.startPrank(user);
        stakingToken.approve(address(core), 100 ether);
        core.stake(100 ether);

        core.requestExit();
        assertGt(core.exitRequestTimestamp(user), 0);

        vm.warp(block.timestamp + cooldownPeriod);
        core.finalizeExit();

        assertEq(core.stakedAmount(user), 0);
        vm.stopPrank();
    }

    function testFinalizeBeforeCooldownReverts() public {
        vm.startPrank(user);
        stakingToken.approve(address(core), 100 ether);
        core.stake(100 ether);

        core.requestExit();
        vm.warp(block.timestamp + cooldownPeriod - 1);

        vm.expectRevert("Cooldown not over");
        core.finalizeExit();
        vm.stopPrank();
    }

    function testRequestExitWithoutStakeReverts() public {
        vm.startPrank(user);
        vm.expectRevert("No active stake");
        core.requestExit();
        vm.stopPrank();
    }

    function testClaimRewards() public {
        vm.startPrank(user);
        stakingToken.approve(address(core), 200 ether);
        core.stake(200 ether);

        vm.warp(block.timestamp + 3600);

        uint256 beforeBal = rewardToken.balanceOf(user);
        core.claimRewards();
        uint256 afterBal = rewardToken.balanceOf(user);

        uint256 expected = (200 ether * rewardRate * 3600) / 1e18;

        assertEq(afterBal - beforeBal, expected);
        vm.stopPrank();
    }

    function testClaimImmediatelyReverts() public {
        vm.startPrank(user);
        stakingToken.approve(address(core), 10 ether);
        core.stake(10 ether);

        vm.expectRevert("Nothing to claim");
        core.claimRewards();
        vm.stopPrank();
    }
}
