// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IConfig.sol";
import "./interfaces/IChain.sol";
import "./interfaces/IReward.sol";
contract Reward is Ownable, IReward {
    using SafeERC20 for IERC20;

    mapping(address => mapping(address => uint256)) private rewardPerTokenStored;
    mapping(address => mapping(address => mapping(address => uint256))) private userRewardPerTokenPaid;
    mapping(address => uint256) private rewards;
    IERC20 public rewardToken;
    IConfig public config;
    IChain public chain;
    address public lendAddress;

    modifier onlyLend() {
        require(msg.sender == lendAddress, "Only lend contract can call this function");
        _;
    }

    constructor(address _configAddress, address _rewardToken, address _chainAddress) Ownable(msg.sender) {
        config = IConfig(_configAddress);
        rewardToken = IERC20(_rewardToken);
        chain = IChain(_chainAddress);
    }
    
    function setLendAddress(address _lendAddress) external onlyOwner {
        lendAddress = _lendAddress;
    }
    
    function setRewardToken(address _rewardToken) external onlyOwner {
        rewardToken = IERC20(_rewardToken);
    }

    function updateReward(address user) public onlyLend {
        uint256 earnedAmount = earned(user);
        rewards[user] += earnedAmount;

        address[] memory validators = chain.getValidators();
        for (uint256 i = 0; i < validators.length; i++) {
            address validator = validators[i];
            address[] memory lpTokens = config.getAllWhitelistTokens();
            for (uint256 j = 0; j < lpTokens.length; j++) {
                address lpToken = lpTokens[j];
                updateUserRewardPerTokenPaid(user, lpToken, validator);
            }
        }
    }

    function earned(address user) public view returns (uint256) {
        uint256 totalEarned = 0;
        address[] memory validators = chain.getValidators();
        for (uint256 i = 0; i < validators.length; i++) {
            address validator = validators[i];
            address[] memory lpTokens = config.getAllWhitelistTokens();
            for (uint256 j = 0; j < lpTokens.length; j++) {
                address lpToken = lpTokens[j];
                uint256 userValidatorTokenStake = chain.getUserValidatorTokenStake(user, validator, lpToken);
                uint256 rewardPerToken = getRewardPerTokenStored(lpToken, validator);
                uint256 userRewardPaid = getUserRewardPaid(user, lpToken, validator);
                totalEarned += (userValidatorTokenStake * (rewardPerToken - userRewardPaid)) / (10**config.getPrecision());
            }
        }
        return totalEarned;
    }

    function claimReward() external {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardClaimed(msg.sender, reward);
        }
    }

    function claimableReward(address user) external view returns (uint256) {
        return rewards[user] + earned(user);
    }

    function distributeReward(
        address[] memory validators,
        address[] memory lpTokens,
        uint256[][] memory rewardAmounts
    ) external onlyOwner {
        require(rewardAmounts.length == validators.length, "Length mismatch: validators");
        uint256 totalRewardAmount = 0;

        for (uint256 i = 0; i < validators.length; i++) {
            require(rewardAmounts[i].length == lpTokens.length, "Length mismatch: lpTokens");
            for (uint256 j = 0; j < lpTokens.length; j++) {
                uint256 rewardAmount = rewardAmounts[i][j];
                address validator = validators[i];
                address lpToken = lpTokens[j];
                uint256 validatorTokenStake = chain.getValidatorTokenStake(validator, lpToken);
                if (validatorTokenStake == 0) continue;

                uint256 perTokenRewardIncrease = (rewardAmount * (10**config.getPrecision())) / validatorTokenStake;
                totalRewardAmount += rewardAmount;
                updateRewardPerTokenStored(lpToken, validator, perTokenRewardIncrease);

                emit RewardDistributed(validator, lpToken, perTokenRewardIncrease);
            }
        }

        if (totalRewardAmount > 0) {
            rewardToken.safeTransferFrom(msg.sender, address(this), totalRewardAmount);
        }
    }

    function updateUserRewardPerTokenPaid(address user, address lpToken, address validator) internal {
        uint256 rewardPerTokenStored = getRewardPerTokenStored(lpToken, validator);
        userRewardPerTokenPaid[user][validator][lpToken] = rewardPerTokenStored;
    }

    function getRewardPerTokenStored(address lpToken, address validator) public view returns (uint256) {
        return rewardPerTokenStored[validator][lpToken];
    }

    function updateRewardPerTokenStored(address lpToken, address validator, uint256 rewardPerToken) internal {
        rewardPerTokenStored[validator][lpToken] += rewardPerToken;
    }

    function getUserRewardPaid(address user, address lpToken, address validator) public view returns (uint256) {
        return userRewardPerTokenPaid[user][validator][lpToken];
    }
}
