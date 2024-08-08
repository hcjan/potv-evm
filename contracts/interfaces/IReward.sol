// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReward {
    event RewardDistributed(address indexed validator, address indexed lpToken, uint256 perTokenRewardIncrease);
    event RewardClaimed(address indexed user, uint256 amount);

    function setRewardToken(address _rewardToken) external;
    function updateReward(address user) external;
    function earned(address user) external view returns (uint256);
    function claimReward() external;
    function claimableReward(address user) external view returns (uint256);
    function distributeReward(
        address[] memory validators,
        address[] memory lpTokens,
        uint256[][] memory rewardAmounts
    ) external;
    function getRewardPerTokenStored(address lpToken, address validator) external view returns (uint256);
    function getUserRewardPaid(address user, address lpToken, address validator) external view returns (uint256);
}
