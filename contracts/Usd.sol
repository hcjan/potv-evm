// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@initia/evm-precompiles/contracts/erc20/ERC20.sol";


contract Usd is ERC20 {
    constructor() ERC20("USD", "USD", 18) {
    }
}
