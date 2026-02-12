// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import "forge-std/Test.sol";
import {CooldownStakingCore} from "../src/core/CooldownStakingCore.sol";
import {CooldownStakingStorage} from "../src/storage/CooldownStakingStorage.sol";
import {CooldownCoordinator} from "../src/time/CooldownStakingCoordinator.sol";
import {MockERC20} from "./MockERC20.t.sol";
import {MockCooldownStakingStorage} from "./MockCooldownStakingStorage.t.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract CooldownStakingCoreTest is Test {
    CooldownStakingCore core;
    MockERC20 stakingToken;
    MockERC20 rewardToken;

    address user1 = vm.addr(1);
    address user2 = vm.addr(2);
    address owner = vm.addr(100);

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

        stakingToken.mint(user1, 1_000 ether);
        stakingToken.mint(user2, 1_000 ether);
    }

    function testUserCanStake() public {
        vm.startPrank(user1);
        stakingToken.approve(address(core), 100 ether);
        core.stake(100 ether);

        assertEq(core.stakedAmount(user1), 100 ether);
        vm.stopPrank();
    }

    function testUserCooldownWorks() public {
        vm.startPrank(user1);
        stakingToken.approve(address(core), 50 ether);
        core.stake(50 ether);

        core.requestExit();
        uint256 exitTs = core.exitRequestTimestamp(user1);
        assertGt(exitTs, 0);

        vm.warp(block.timestamp + cooldownPeriod);
        core.finalizeExit();

        assertEq(core.stakedAmount(user1), 0);
        vm.stopPrank();
    }

    function testUserCanClaimRewards() public {
        vm.startPrank(user2);
        stakingToken.approve(address(core), 200 ether);
        core.stake(200 ether);

        vm.warp(block.timestamp + 3600);

        uint256 balanceBefore = rewardToken.balanceOf(user2);
        core.claimRewards();
        uint256 balanceAfter = rewardToken.balanceOf(user2);

        uint256 staked = 200 ether;
        uint256 timeElapsed = 3600;

        uint256 expectedReward = (staked * rewardRate * timeElapsed) / 1e18;
        assertEq(balanceAfter - balanceBefore, expectedReward);

        vm.stopPrank();
    }

    function testInvariants() public {
        vm.startPrank(user1);
        stakingToken.approve(address(core), 10 ether);
        core.stake(10 ether);

        vm.expectRevert("Already staking");
        core.stake(10 ether);

        vm.stopPrank();
    }

    function testStakeZeroReverts() public {
        vm.startPrank(user1);
        vm.expectRevert();
        core.stake(0);
        vm.stopPrank();
    }

    function testFinalizeWithoutRequestReverts() public {
        vm.startPrank(user1);
        stakingToken.approve(address(core), 10 ether);
        core.stake(10 ether);

        vm.expectRevert();
        core.finalizeExit();

        vm.stopPrank();
    }

    function testCooldownNotFinishedReverts() public {
        vm.startPrank(user1);
        stakingToken.approve(address(core), 10 ether);
        core.stake(10 ether);

        core.requestExit();

        vm.warp(block.timestamp + cooldownPeriod - 1);

        vm.expectRevert();
        core.finalizeExit();

        vm.stopPrank();
    }

    function testClaimWithoutStakeReverts() public {
        vm.startPrank(user1);

        vm.expectRevert();
        core.claimRewards();

        vm.stopPrank();
    }

    function testRequestExitWithoutStakeReverts() public {
        vm.startPrank(user1);

        vm.expectRevert();
        core.requestExit();

        vm.stopPrank();
    }

    function testStakeWhileExitingReverts() public {
        vm.startPrank(user1);

        stakingToken.approve(address(core), 10 ether);
        core.stake(10 ether);

        core.requestExit();

        vm.expectRevert();
        core.stake(5 ether);

        vm.stopPrank();
    }

    function testViewFunctionsCoverage() public {
        core.REWARD_TOKEN();
        core.REWARD_RATE();
        core.stakedAmount(user1);
        core.exitRequestTimestamp(user1);
    }

    function testClaimWithZeroTime() public {
        vm.startPrank(user1);

        stakingToken.approve(address(core), 10 ether);
        core.stake(10 ether);

        vm.warp(block.timestamp + 1);

        uint256 beforeBal = rewardToken.balanceOf(user1);
        core.claimRewards();
        uint256 afterBal = rewardToken.balanceOf(user1);

        assertGt(afterBal, beforeBal);

        vm.stopPrank();
    }

    function testFinalizeAtExactCooldownBoundary() public {
        vm.startPrank(user1);

        stakingToken.approve(address(core), 10 ether);
        core.stake(10 ether);
        core.requestExit();

        vm.warp(block.timestamp + cooldownPeriod);
        core.finalizeExit();

        assertEq(core.stakedAmount(user1), 0);

        vm.stopPrank();
    }

    function testStakeAfterExitWorks() public {
        vm.startPrank(user1);

        stakingToken.approve(address(core), 10 ether);
        core.stake(10 ether);
        core.requestExit();

        vm.warp(block.timestamp + cooldownPeriod);
        core.finalizeExit();

        stakingToken.approve(address(core), 5 ether);
        core.stake(5 ether);

        assertEq(core.stakedAmount(user1), 5 ether);

        vm.stopPrank();
    }

    function testClaimZeroElapsedReverts() public {
        vm.startPrank(user1);
        stakingToken.approve(address(core), 10 ether);
        core.stake(10 ether);

        // claim inmediatamente
        vm.expectRevert("Nothing to claim");
        core.claimRewards();

        vm.stopPrank();
    }

    function testDoubleRequestExitReverts() public {
        vm.startPrank(user1);
        stakingToken.approve(address(core), 10 ether);
        core.stake(10 ether);
        core.requestExit();

        vm.expectRevert("Exit already requested");
        core.requestExit();

        vm.stopPrank();
    }

    function testStakeWhileStakingReverts() public {
        vm.startPrank(user1);
        stakingToken.approve(address(core), 10 ether);
        core.stake(10 ether);

        vm.expectRevert("Already staking");
        core.stake(5 ether);

        vm.stopPrank();
    }

    function testClaimImmediatelyReverts() public {
        uint256 amount = 1e18;
        stakingToken.mint(address(this), amount);
        stakingToken.approve(address(core), amount);

        core.stake(amount);

        vm.expectRevert(bytes("Nothing to claim"));
        core.claimRewards();
    }

    function testFinalizeBeforeCooldownReverts() public {
        uint256 amount = 1e18;
        stakingToken.mint(address(this), amount);
        stakingToken.approve(address(core), amount);

        core.stake(amount);
        core.requestExit();

        vm.expectRevert(bytes("Cooldown not over"));
        core.finalizeExit();
    }

    function testDoubleExitRequestReverts() public {
        uint256 amount = 1e18;
        stakingToken.mint(address(this), amount);
        stakingToken.approve(address(core), amount);

        core.stake(amount);
        core.requestExit();

        vm.expectRevert(bytes("Exit already requested"));
        core.requestExit();
    }

    function testDoubleStakeReverts() public {
        uint256 amount = 1e18;
        stakingToken.mint(address(this), amount * 2);
        stakingToken.approve(address(core), amount * 2);

        core.stake(amount);

        vm.expectRevert(bytes("Already staking"));
        core.stake(amount);
    }

    function testClaimZeroElapsedTimeReverts() public {
        vm.startPrank(user1);
        stakingToken.approve(address(core), 10 ether);
        core.stake(10 ether);

        vm.warp(block.timestamp);

        vm.expectRevert(bytes("Nothing to claim"));
        core.claimRewards();
        vm.stopPrank();
    }

    function testFinalizeWithoutStakeReverts() public {
        vm.startPrank(user1);
        vm.expectRevert(bytes("No active stake"));
        core.finalizeExit();
        vm.stopPrank();
    }

    function testRequestExitWithoutStakeRevertsAgain() public {
        vm.startPrank(user1);
        vm.expectRevert(bytes("No active stake"));
        core.requestExit();
        vm.stopPrank();
    }

    function testAllViewFunctionsCoverage() public view {
        core.cooldownPeriod();
        core.stakedAmount(user1);
        core.exitRequestTimestamp(user1);
        core.positionOf(user1);
    }
}
