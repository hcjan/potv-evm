// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IConfig.sol";

contract Chain is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant PRECISION_DECIMALS = 6;
    uint256 public constant MIGRATE_STAKE_LIMIT = 500;

    IConfig public config;
    address public lendContract;

    EnumerableSet.AddressSet private validators;
    mapping(address => mapping(address => mapping(address => uint256))) private userStakes;
    mapping(address => mapping(address => uint256)) private validatorStakes;
    mapping(address => EnumerableSet.AddressSet) private validatorStakedUsers;

    event ChainLiquidateEvent(
        address indexed liquidatedUser,
        address indexed liquidator,
        address indexed validator,
        address tokenType,
        uint256 amount
    );

    constructor(address _configAddress) Ownable(msg.sender) {
        config = IConfig(_configAddress);
    }

    modifier onlyLend() {
        require(msg.sender == lendContract, "Only Lend contract can call this function");
        _;
    }

    function setLendContract(address _lendContract) external onlyOwner {
        lendContract = _lendContract;
    }

    function setValidators(address[] memory newValidators) external onlyOwner {
        for (uint256 i = 0; i < validators.length(); i++) {
            validators.remove(validators.at(i));
        }
        for (uint256 i = 0; i < newValidators.length; i++) {
            validators.add(newValidators[i]);
        }
    }

    function stakeToken(address user, address validator, address tokenType, uint256 amount) external onlyLend {
        require(validators.contains(validator), "Invalid validator");
        userStakes[user][validator][tokenType] += amount;
        validatorStakes[validator][tokenType] += amount;
        validatorStakedUsers[validator].add(user);
    }

    function unstakeToken(address user, address validator, address tokenType, uint256 amount) external onlyLend {
        require(userStakes[user][validator][tokenType] >= amount, "Insufficient stake");
        userStakes[user][validator][tokenType] -= amount;
        validatorStakes[validator][tokenType] -= amount;
        if (userStakes[user][validator][tokenType] == 0) {
            validatorStakedUsers[validator].remove(user);
        }
    }

    function liquidatePosition(address liquidator, address liquidatedParty) external onlyLend {
        address[] memory whitelistTokens = config.getAllWhitelistTokens();
        for (uint256 i = 0; i < validators.length(); i++) {
            address validator = validators.at(i);
            for (uint256 j = 0; j < whitelistTokens.length; j++) {
                address tokenType = whitelistTokens[j];
                uint256 stakeAmount = userStakes[liquidatedParty][validator][tokenType];
                if (stakeAmount > 0) {
                    userStakes[liquidatedParty][validator][tokenType] = 0;
                    userStakes[liquidator][validator][tokenType] += stakeAmount;
                    emit ChainLiquidateEvent(liquidatedParty, liquidator, validator, tokenType, stakeAmount);
                }
            }
        }
    }

    function migrateStakes(address deletedValidator, address newValidator, uint256 deleteAmount) external onlyOwner {
        require(deleteAmount <= MIGRATE_STAKE_LIMIT, "Exceeds migration limit");
        if (!validators.contains(newValidator)) {
            validators.add(newValidator);
        }
        if (deleteAmount == 0) {
            validators.remove(deletedValidator);
            return;
        }
        address[] memory stakedUsers = new address[](validatorStakedUsers[deletedValidator].length());
        for (uint256 i = 0; i < stakedUsers.length; i++) {
            stakedUsers[i] = validatorStakedUsers[deletedValidator].at(i);
        }
        address[] memory whitelistTokens = config.getAllWhitelistTokens();
        for (uint256 i = 0; i < deleteAmount && i < stakedUsers.length; i++) {
            address user = stakedUsers[i];
            for (uint256 j = 0; j < whitelistTokens.length; j++) {
                address tokenType = whitelistTokens[j];
                uint256 stakeAmount = userStakes[user][deletedValidator][tokenType];
                if (stakeAmount > 0) {
                    userStakes[user][deletedValidator][tokenType] = 0;
                    userStakes[user][newValidator][tokenType] += stakeAmount;
                    validatorStakes[deletedValidator][tokenType] -= stakeAmount;
                    validatorStakes[newValidator][tokenType] += stakeAmount;
                }
            }
            validatorStakedUsers[deletedValidator].remove(user);
            validatorStakedUsers[newValidator].add(user);
        }
        if (validatorStakedUsers[deletedValidator].length() == 0) {
            validators.remove(deletedValidator);
        }
    }

    function getValidators() external view returns (address[] memory) {
        return validators.values();
    }

    function getValidatorStakedUsers(address validator) external view returns (address[] memory) {
        return validatorStakedUsers[validator].values();
    }

    function getStakedUsers(address validator) external view returns (uint256) {
        return validatorStakedUsers[validator].length();
    }

    function getUserValidatorTokenStake(address user, address validator, address tokenType) external view returns (uint256) {
        return userStakes[user][validator][tokenType];
    }

    function getValidatorTokenStake(address validator, address tokenType) external view returns (uint256) {
        return validatorStakes[validator][tokenType];
    }

    function getMigrateStakeLimit() external pure returns (uint256) {
        return MIGRATE_STAKE_LIMIT;
    }
}
