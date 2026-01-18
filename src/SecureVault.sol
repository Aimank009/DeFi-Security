// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ISecureVault.sol";
import "./interfaces/IFlashLoanReceiver.sol";
import "./events/VaultEvents.sol";
import "./events/FlashLoanEvents.sol";

contract SecureVault is
    ISecureVault,
    VaultEvents,
    FlashLoanEvents,
    ReentrancyGuard
{
    mapping(address => uint256) public balances;
    uint256 public constant FLASH_LOAN_FEE = 9;
    uint256 public constant FEE_PRECISION = 10000;

    error InsufficientBalance();
    error FlashLoanFailed();
    error ZeroAmount();
    error TransferFailed();

    receive() external payable {}
    function deposit() external payable override nonReentrant {
        if (msg.value == 0) revert ZeroAmount();
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() external override nonReentrant {
        if (balances[msg.sender] == 0) revert InsufficientBalance();
        uint256 userBalance = balances[msg.sender];
        balances[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: userBalance}("");
        if (!success) revert TransferFailed();

        emit Withdrawn(msg.sender, userBalance);
    }
}
