// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IChain {
    function setValidators(address[] memory newValidators) external;
    function stakeToken(address user, address validator, address tokenType, uint256 amount) external;
    function unstakeToken(address user, address validator, address tokenType, uint256 amount) external;
    function liquidatePosition(address liquidator, address liquidatedParty) external;
    function migrateStakes(address deletedValidator, address newValidator, uint256 deleteAmount) external;
    function getValidators() external view returns (address[] memory);
    function getValidatorStakedUsers(address validator) external view returns (address[] memory);
    function getStakedUsers(address validator) external view returns (uint256);
    function getUserValidatorTokenStake(address user, address validator, address tokenType) external view returns (uint256);
    function getValidatorTokenStake(address validator, address tokenType) external view returns (uint256);
    function getMigrateStakeLimit() external pure returns (uint256);

    event ChainLiquidateEvent(
        address indexed liquidatedUser,
        address indexed liquidator,
        address indexed validator,
        address tokenType,
        uint256 amount
    );
}
