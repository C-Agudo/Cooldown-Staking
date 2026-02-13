// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import "forge-std/Test.sol";

import {CooldownStaking} from "../src/CooldownStaking.sol";
import {CooldownStakingCore} from "../src/core/CooldownStakingCore.sol";
import {MockCooldownStakingStorage} from "./MockCooldownStakingStorage.t.sol";
import {CooldownCoordinator} from "../src/time/CooldownStakingCoordinator.sol";
import {MockERC20} from "./MockERC20.t.sol";

contract CooldownStakingTest is Test {
    CooldownStaking staking;
    CooldownStakingCore core;
    MockCooldownStakingStorage storageContract;
    CooldownCoordinator coordinator;

    MockERC20 stakingToken;
    MockERC20 rewardToken;

    address user = address(1);

    uint256 constant COOLDOWN = 7 days;
    uint256 constant REWARD_RATE = 1e18;

    function setUp() public {
        stakingToken = new MockERC20("Stake", "STK");
        rewardToken = new MockERC20("Reward", "RWD");

        storageContract = new MockCooldownStakingStorage(
            address(stakingToken),
            address(rewardToken),
            100,
            10
        );

        coordinator = new CooldownCoordinator(COOLDOWN);

        core = new CooldownStakingCore(
            address(stakingToken),
            address(rewardToken),
            COOLDOWN,
            REWARD_RATE
        );

        staking = new CooldownStaking(core, storageContract, coordinator);

        stakingToken.mint(user, 1000 ether);
        rewardToken.mint(address(core), 1000 ether);

        vm.prank(user);
        stakingToken.approve(address(core), type(uint256).max);
    }

    function testFullStakeFlow() public {
        vm.startPrank(user);

        staking.stake(100 ether);
        staking.requestExit();

        vm.warp(block.timestamp + COOLDOWN + 1);

        staking.finalizeExit();

        vm.stopPrank();
    }

    function testClaimRewardsThroughFacade() public {
        vm.startPrank(user);

        staking.stake(200 ether);
        vm.warp(block.timestamp + 1);
        staking.claimRewards();

        vm.stopPrank();
    }

    function testCooldownNotOverReverts() public {
        vm.startPrank(user);

        staking.stake(50 ether);
        staking.requestExit();

        vm.expectRevert();
        staking.finalizeExit();

        vm.stopPrank();
    }

    function testStakeZeroReverts() public {
        vm.prank(user);
        vm.expectRevert();
        staking.stake(0);
    }

    function testFinalizeWithoutStakeReverts() public {
        vm.prank(user);
        vm.expectRevert();
        staking.finalizeExit();
    }

    function testGlobalCooldownView() public view {
        staking.globalCooldown();
    }

    function testStakedAmountView() public view {
        staking.stakedAmount(user);
    }

    function testExitRequestTimestampView() public {
        vm.startPrank(user);
        staking.stake(50 ether);
        staking.requestExit();
        staking.exitRequestTimestamp(user);
        vm.stopPrank();
    }

    function testCooldownPeriodView() public view {
        staking.cooldownPeriod();
    }

    function testDirectStakeOnCore() public {
        vm.prank(user);
        core.stake(50 ether);
    }

    function testDirectRequestExitOnCore() public {
        vm.startPrank(user);
        core.stake(50 ether);
        core.requestExit();
        vm.stopPrank();
    }

    function testDirectFinalizeExitOnCore() public {
        vm.startPrank(user);
        core.stake(50 ether);
        core.requestExit();
        vm.warp(block.timestamp + COOLDOWN + 1);
        core.finalizeExit();
        vm.stopPrank();
    }

    function testDirectClaimRewardsOnCore() public {
        vm.startPrank(user);
        core.stake(50 ether);
        vm.warp(block.timestamp + 1);
        core.claimRewards();
        vm.stopPrank();
    }

    function testCooldownPeriodOnCore() public view {
        core.cooldownPeriod();
    }

    function testPositionOfOnCore() public view {
        core.positionOf(user);
    }

    function testDoubleRequestExitReverts() public {
        vm.startPrank(user);
        core.stake(50 ether);
        core.requestExit();
        vm.expectRevert("Exit already requested");
        core.requestExit();
        vm.stopPrank();
    }

    function testFinalizeWithoutRequestReverts() public {
        vm.startPrank(user);
        core.stake(50 ether);
        vm.expectRevert("Exit not requested");
        core.finalizeExit();
        vm.stopPrank();
    }

    function testClaimRewardsImmediatelyReverts() public {
        vm.startPrank(user);
        core.stake(50 ether);
        vm.expectRevert("Nothing to claim");
        core.claimRewards();
        vm.stopPrank();
    }

    function testClaimRewardsWithoutStakeReverts() public {
        vm.prank(user);
        vm.expectRevert("No active stake");
        core.claimRewards();
    }
}
