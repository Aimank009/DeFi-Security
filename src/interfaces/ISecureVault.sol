// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISecureVault {
    function deposit() external payable;
    function withdraw() external;
    function getBalance(address _user) external view returns (uint256);
    function flashLoan(
        uint256 _amount,
        address _receiver,
        bytes calldata _data
    ) external;
}
