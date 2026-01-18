// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract VaultEvents {
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
}
