// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPriceOracle.sol";
import "../events/OracleEvents.sol";

contract PriceOracle is IPriceOracle, Ownable, OracleEvents {
    mapping(address => uint256) public price;
    mapping(address => bool) public supportedToken;

    error InvalidToken();
    error UnsupportedToken();

    constructor() Ownable(msg.sender) {}

    function setPrice(
        address _token,
        uint256 _price
    ) external override onlyOwner {
        uint256 oldPrice = price[_token];

        price[_token] = _price;

        if (!supportedToken[_token]) {
            supportedToken[_token] = true;
            emit TokenAdded(_token, _price);
        }
        emit PriceUpdated(_token, oldPrice, _price, block.timestamp);
    }

    function getPrice(address _token) external view override returns (uint256) {
        if (!supportedToken[_token]) revert UnsupportedToken();
        return price[_token];
    }

    function isSupported(address _token) external view override returns (bool) {
        return supportedToken[_token];
    }
}
