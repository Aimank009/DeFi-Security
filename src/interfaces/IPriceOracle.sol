// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPriceOracle {
    function getPrice(address _token) external view returns (uint256);
    function setPrice(address _token, uint256 _price) external;
    function isSupported(address _token) external view returns (bool);
}
