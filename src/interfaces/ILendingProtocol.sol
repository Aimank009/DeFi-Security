// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILendingProtocol {
    function depositCollateral() external payable;
    function withdrawCollateral(uint256 _amount) external;
    function borrow(uint256 _amount) external;
    function repay(uint256 _amount) external;
    function liquidate(address _user) external;
    function getHealthFactor(address _user) external view returns (uint256);
    function getCollateral(address _user) external view returns (uint256);
    function getDebt(address _user) external view returns (uint256);
}
