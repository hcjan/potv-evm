// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IConfig.sol";
contract Config is Ownable, IConfig {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant PRECISION_DECIMALS = 6;


    EnumerableSet.AddressSet private _collateralTokens;
    uint256 public mcr;
    uint256 public liquidationRate;


    constructor(uint256 _mcr, uint256 _liquidationRate) Ownable(msg.sender) {
        mcr = _mcr;
        liquidationRate = _liquidationRate;
    }

    function addCollateral(address tokenType) external onlyOwner {
        require(!_collateralTokens.contains(tokenType), "ECollateralAlreadyExist");
        _collateralTokens.add(tokenType);
        emit CollateralAdded(tokenType);
    }

    function disableCollateral(address tokenType) external onlyOwner {
        require(_collateralTokens.contains(tokenType), "ENotCollateral");
        _collateralTokens.remove(tokenType);
        emit CollateralDisabled(tokenType);
    }

    function setMCR(uint256 _mcr) external onlyOwner {
        mcr = _mcr;
        emit MCRUpdated(_mcr);
    }

    function setLiquidationRate(uint256 _liquidationRate) external onlyOwner {
        liquidationRate = _liquidationRate;
        emit LiquidationRateUpdated(_liquidationRate);
    }

    function getTokenDecimals(address tokenAddress) external view returns (uint256) {
        return IERC20Metadata(tokenAddress).decimals();
    }

    function isWhitelistToken(address tokenType) external view returns (bool) {
        return _collateralTokens.contains(tokenType);
    }

    function getAllWhitelistTokens() external view returns (address[] memory) {
        return _collateralTokens.values();
    }

  
    function getMCR() external view returns (uint256) {
        return mcr;
    }

    function getPrecision() external pure returns (uint256) {
        return PRECISION_DECIMALS;
    }
}
