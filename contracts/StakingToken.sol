// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakingToken is ERC20 {
    constructor() ERC20("StakeTest", "STK") {
         _mint(msg.sender, 5000000000 * 10 ** decimals());
    }
}