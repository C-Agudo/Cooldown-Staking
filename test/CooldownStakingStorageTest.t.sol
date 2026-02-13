// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import "forge-std/Test.sol";
import "./MockERC20.t.sol";
import "./MockCooldownStakingStorage.t.sol";

contract CooldownStakingStorageTest is Test {
    MockERC20 stakingToken;
    MockERC20 rewardToken;
    MockCooldownStakingStorage storageContract;

    function setUp() public {
        stakingToken = new MockERC20("Stake Token", "STK");
        rewardToken = new MockERC20("Reward Token", "RWD");

        storageContract = new MockCooldownStakingStorage(address(stakingToken), address(rewardToken), 1 days, 1e18);
    }

    function testGetters() public {
        assertEq(storageContract.getStakingToken(), address(stakingToken));
        assertEq(storageContract.getRewardToken(), address(rewardToken));
        assertEq(storageContract.getCooldownPeriod(), 1 days);
        assertEq(storageContract.getRewardRate(), 1e18);
    }

    function testSetAndReadPosition() public {
        address user = address(0x123);

        storageContract.setPosition(user, 100 ether, 10, 0);

        CooldownStakingStorage.StakePosition memory pos = storageContract.getPosition(user);

        assertEq(pos.amount, 100 ether);
        assertEq(pos.stakeTimestamp, 10);
        assertEq(pos.exitRequestTimestamp, 0);
    }

    function testMultipleUsers() public {
        address user1 = address(1);
        address user2 = address(2);

        storageContract.setPosition(user1, 50 ether, 1, 0);
        storageContract.setPosition(user2, 75 ether, 2, 5);

        CooldownStakingStorage.StakePosition memory pos1 = storageContract.getPosition(user1);
        CooldownStakingStorage.StakePosition memory pos2 = storageContract.getPosition(user2);

        assertEq(pos1.amount, 50 ether);
        assertEq(pos2.amount, 75 ether);
        assertEq(pos2.exitRequestTimestamp, 5);
    }
}
