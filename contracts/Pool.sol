// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IConfig.sol";
import "./interfaces/IUSD.sol";

contract Pool is Ownable {
    using SafeERC20 for IERC20;

    IConfig public config;
    IUSD public usdToken;
    
    mapping(address => uint256) public userBorrow;
    uint256 public totalBorrow;

    mapping(address => mapping(address => uint256)) public userSupply;
    mapping(address => uint256) public totalSupply;

    event Borrow(address indexed account, uint256 amount);
    event Repay(address indexed account, uint256 amount);
    event IncreaseToken(address indexed account, address indexed tokenType, uint256 amount);
    event DecreaseToken(address indexed account, address indexed tokenType, uint256 amount);
    event LiquidateToken(address indexed liquidator, address indexed liquidatedUser, address indexed tokenType, uint256 amount);

    error NotWhiteListToken();
    error ExceedBorrowAmount();
    error ExceedSupplyAmount();
    error InsufficientSupply();

    constructor(address _configAddress, address _usdAddress) Ownable(msg.sender) {
        config = IConfig(_configAddress);
        usdToken = IUSD(_usdAddress);
    }

    function increasePoolToken(address tokenAddress, uint256 amount) external {
        require(config.isWhitelistToken(tokenAddress), "Not a whitelisted token");
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        
        userSupply[tokenAddress][msg.sender] += amount;
        totalSupply[tokenAddress] += amount;

        emit IncreaseToken(msg.sender, tokenAddress, amount);
    }

    function decreasePoolToken(address tokenAddress, uint256 amount) external {
        require(userSupply[tokenAddress][msg.sender] >= amount, "Insufficient balance");

        userSupply[tokenAddress][msg.sender] -= amount;
        totalSupply[tokenAddress] -= amount;

        IERC20(tokenAddress).safeTransfer(msg.sender, amount);

        emit DecreaseToken(msg.sender, tokenAddress, amount);
    }

    function liquidateTokens(address src, address dest) external onlyOwner {
        address[] memory whitelistTokens = config.getAllWhitelistTokens();
        for (uint i = 0; i < whitelistTokens.length; i++) {
            address tokenAddress = whitelistTokens[i];
            uint256 srcBalance = userSupply[tokenAddress][src];
            if (srcBalance > 0) {
                userSupply[tokenAddress][src] = 0;
                userSupply[tokenAddress][dest] += srcBalance;
                emit LiquidateToken(dest, src, tokenAddress, srcBalance);
            }
        }
    }

    function borrowUSD(uint256 amount) external {
        userBorrow[msg.sender] += amount;
        totalBorrow += amount;
        usdToken.mint(msg.sender, amount);

        emit Borrow(msg.sender, amount);
    }

    function repayUSD(address repaidUser, uint256 amount) external {
        require(userBorrow[repaidUser] >= amount, "Exceed borrow amount");
        userBorrow[repaidUser] -= amount;
        totalBorrow -= amount;
        usdToken.burn(msg.sender, amount);
        emit Repay(repaidUser, amount);
    }

    function getUserTokenSupply(address user, address tokenType) external view returns (uint256) {
        return userSupply[tokenType][user];
    }

    function getUserTotalBorrow(address user) external view returns (uint256) {
        return userBorrow[user];
    }

    function getSystemTokenTotalSupply(address tokenType) external view returns (uint256) {
        return totalSupply[tokenType];
    }

    function getSystemTotalBorrowed() external view returns (uint256) {
        return totalBorrow;
    }
}
