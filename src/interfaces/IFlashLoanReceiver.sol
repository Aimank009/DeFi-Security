// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFlashLoanReceiver {
    function executeOperation(
        uint256 _amount,
        uint256 _fee,
        address _initiator,
        bytes calldata data
    ) external returns (bool);
}
