// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IChain.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IConfig.sol";
import "./interfaces/IReward.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lend is Ownable {
    IChain public chain;
    IPool public pool;
    IConfig public config;
    IReward public reward;

    event IncreaseSupplyEvent(address indexed account, address indexed tokenType, uint256 amount, address indexed validator);
    event IncreaseBorrowEvent(address indexed account, uint256 amount);
    event DecreaseSupplyEvent(address indexed account, address indexed tokenType, uint256 amount, address indexed validator);
    event RepayEvent(address indexed account, uint256 amount);
    event LiquidateEvent(address indexed liquidator, address indexed liquidatedUser, uint256 repayAmount);

    constructor(address _chainAddress, address _poolAddress, address _configAddress, address _rewardAddress) Ownable(msg.sender) {
        chain = IChain(_chainAddress);
        pool = IPool(_poolAddress);
        config = IConfig(_configAddress);
        reward = IReward(_rewardAddress);
    }

    function supply(address tokenType, uint256 amount, address validator) external {
        reward.updateReward(msg.sender);
        require(config.isWhitelistToken(tokenType), "ENotWhiteListToken");
        pool.increasePoolToken(tokenType, amount);
        chain.stakeToken(msg.sender, validator, tokenType, amount);
        emit IncreaseSupplyEvent(msg.sender, tokenType, amount, validator);
    }

    function withdraw(address tokenType, uint256 amount, address validator) external {
        reward.updateReward(msg.sender);
        uint256 maxWithdrawable = getTokenMaxWithdrawable(msg.sender, tokenType);
        require(amount <= maxWithdrawable, "EExceedWithdrawAmount");
        pool.decreasePoolToken(tokenType, amount);
        chain.unstakeToken(msg.sender, validator, tokenType, amount);
        emit DecreaseSupplyEvent(msg.sender, tokenType, amount, validator);
    }

    function borrow(uint256 amount) external {
        pool.borrowUSD(amount);
        uint256 userCollateralRatio = getUserCollateralRatio(msg.sender);
        uint256 systemMCR = config.getMCR();
        require(userCollateralRatio > systemMCR, "ELowerThanMCR");
        emit IncreaseBorrowEvent(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        pool.repayUSD(msg.sender, amount);
        emit RepayEvent(msg.sender, amount);
    }

    function liquidate(address liquidatedUser) external {
        require(msg.sender != liquidatedUser, "EInvalidLiquidator");
        uint256 userCollateralRatio = getUserCollateralRatio(liquidatedUser);
        uint256 systemLiquidateRate = config.liquidationRate();
        require(systemLiquidateRate >= userCollateralRatio, "ELargerThanLiquidateRate");

        reward.updateReward(liquidatedUser);
        reward.updateReward(msg.sender);

        uint256 repayAmount = pool.getUserTotalBorrow(liquidatedUser);
        pool.repayUSD(liquidatedUser, repayAmount);
        pool.liquidateTokens(liquidatedUser, msg.sender);
        chain.liquidatePosition(msg.sender, liquidatedUser);
        emit LiquidateEvent(msg.sender, liquidatedUser, repayAmount);
    }

    function migrateStakes(address deletedValidator, address newValidator) external onlyOwner {
        uint256 migrateStakeLimit = chain.getMigrateStakeLimit();
        address[] memory validatorStakedUsers = chain.getValidatorStakedUsers(deletedValidator);
        uint256 deleteAmount = validatorStakedUsers.length <= migrateStakeLimit ? validatorStakedUsers.length : migrateStakeLimit;
        
        for (uint256 i = 0; i < deleteAmount; i++) {
            address userAddress = validatorStakedUsers[i];
            reward.updateReward(userAddress);
        }
        
        chain.migrateStakes(deletedValidator, newValidator, deleteAmount);
    }

    function getTokenMaxWithdrawable(address user, address tokenType) public view returns (uint256) {
        // Implement the logic to calculate max withdrawable amount
        // This is a placeholder and should be replaced with actual implementation
        return pool.getUserTokenSupply(user, tokenType);
    }

    function getUserCollateralRatio(address user) public view returns (uint256) {
        // Implement the logic to calculate user's collateral ratio
        // This is a placeholder and should be replaced with actual implementation
        return 0;
    }
}
