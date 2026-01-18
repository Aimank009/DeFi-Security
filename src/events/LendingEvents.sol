// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract LendingEvents {
    event CollateralDeposited(address indexed _user, uint256 _amount);
    event CollateralWithdrawn(address indexed _user, uint256 _amount);
    event Borrowed(address indexed _user, uint256 _amount);
    event Repaid(address indexed _user, uint256 _amount);
    event Liquidated(
        address indexed _liquidator,
        address indexed _user,
        uint256 _debtRepaid,
        uint256 _collateralTaken
    );
}
