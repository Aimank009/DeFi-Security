// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract FlashLoanEvents {
    event FlashLoan(
        address indexed receiver,
        address indexed token,
        uint256 amount,
        uint256 fee
    );
}
