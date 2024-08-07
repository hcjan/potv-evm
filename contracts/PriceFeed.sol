// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import "@openzeppelin/contracts/access/Ownable.sol";



contract PriceFeed is Ownable {

    mapping (address => int256) public answers;
    mapping(address => uint256) public lastUpdated;


    constructor() Ownable(msg.sender) {

    }
    
    function setTokenPrices(address[] memory tokens, int256[] memory prices) public onlyOwner {
        require(tokens.length == prices.length, "Input arrays must have the same length");
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i] != address(0), "Invalid token address");
            require(prices[i] > 0, "Price must be positive");
            answers[tokens[i]] = prices[i];
            lastUpdated[tokens[i]] = block.timestamp;
        }
    }

    function latestAnswer(address token) public view returns (int256) {
        require(lastUpdated[token] > 0, "Price not set for this token");
        return answers[token];
    }

    function latestUpdateTime(address token) public view returns (uint256) {
        return lastUpdated[token];
    }

}
