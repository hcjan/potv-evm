// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPool.sol";


contract Usd is ERC20, Ownable {
    IPool public pool;

    constructor(address _poolAddress) ERC20("USD", "USD") Ownable(msg.sender) {
        pool = IPool(_poolAddress);
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == address(pool), "Only pool can mint");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == address(pool), "Only pool can burn");
        _burn(from, amount);
    }

    function setPool(address _poolAddress) external onlyOwner {
        pool = IPool(_poolAddress);
    }
}
