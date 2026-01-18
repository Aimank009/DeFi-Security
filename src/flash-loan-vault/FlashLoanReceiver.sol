// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IFlashLoanReceiver.sol";
import "../interfaces/ISecureVault.sol";

contract FlashLoanReceiver is IFlashLoanReceiver {
    address public vault;
    address public owner;

    constructor(address _vault) {
        vault = _vault;
        owner = msg.sender;
    }
    receive() external payable {}
    function requestFlashLoan(uint256 _amount) public {
        ISecureVault(vault).flashLoan(_amount, address(this), "");
    }

    function executeOperation(
        uint256 _amount,
        uint256 _fee,
        address _initiator,
        bytes calldata _data
    ) external override returns (bool) {
        // Do something with the borrowed ETH here

        (bool success, ) = vault.call{value: _amount + _fee}("");
        require(success, "Repay failed");

        return true;
    }
}
