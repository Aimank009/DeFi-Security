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

    function flashLoan(
        uint256 _amount,
        address _receiver,
        bytes calldata _data
    ) external override nonReentrant {
        if (_amount == 0) revert ZeroAmount();
        if (_amount > address(this).balance) revert InsufficientBalance();
        uint256 balanceBefore = address(this).balance;
        uint256 fee = (_amount * FLASH_LOAN_FEE) / FEE_PRECISION;

        (bool sent, ) = payable(_receiver).call{value: _amount}("");
        if (!sent) revert FlashLoanFailed();
        bool success = IFlashLoanReceiver(_receiver).executeOperation(
            _amount,
            fee,
            msg.sender,
            _data
        );
        if (!success) revert FlashLoanFailed();
        if (address(this).balance < balanceBefore + fee)
            revert FlashLoanFailed();
        emit FlashLoan(_receiver, address(0), _amount, fee);
    }
    function getBalance(
        address _user
    ) external view override returns (uint256) {
        return balances[_user];
    }
}
