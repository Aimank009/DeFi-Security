// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract OracleEvents {
    event PriceUpdated(
        address indexed _token,
        uint256 _oldPrice,
        uint256 _newPrice,
        uint256 _timestamp
    );
    event TokenAdded(address indexed _token, uint256 _initialPrice);
    event TokenRemoved(address indexed _token);
}
