// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/flash-loan-vault/SecureVault.sol";
import "../src/flash-loan-vault/FlashLoanReceiver.sol";

contract SecureVaultTest is Test {
    SecureVault public vault;
    FlashLoanReceiver public receiver;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    function setUp() public {
        vault = new SecureVault();
        receiver = new FlashLoanReceiver(address(vault));

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(address(vault), 100 ether);
    }

    function test_Deposit() public {
        vm.startPrank(alice);
        vault.deposit{value: 10 ether}();
        assertEq(vault.getBalance(alice), 10 ether);
        vm.stopPrank();
    }

    function test_Deposit_RevertOnZero() public {
        vm.startPrank(alice);
        vm.expectRevert(SecureVault.ZeroAmount.selector);
        vault.deposit{value: 0}();
        vm.stopPrank();
    }

    function test_Withdraw() public {
        vm.startPrank(alice);
        vault.deposit{value: 10 ether}();
        uint256 balanceBefore = alice.balance;
        vault.withdraw();
        assertEq(alice.balance, balanceBefore + 10 ether);
        assertEq(vault.getBalance(alice), 0);
        vm.stopPrank();
    }

    function test_Withdraw_RevertOnZeroBalance() public {
        vm.startPrank(alice);
        vm.expectRevert(SecureVault.InsufficientBalance.selector);
        vault.withdraw();
        vm.stopPrank();
    }

    function test_FlashLoan() public {
        vm.deal(address(receiver), 1 ether);

        vm.startPrank(alice);
        receiver.requestFlashLoan(10 ether);
        vm.stopPrank();

        assertGe(address(vault).balance, 100 ether);
    }

    function test_FlashLoan_RevertOnZeroAmount() public {
        vm.startPrank(alice);
        vm.expectRevert(SecureVault.ZeroAmount.selector);
        vault.flashLoan(0, address(receiver), "");
        vm.stopPrank();
    }

    function test_FlashLoan_RevertOnInsufficientBalance() public {
        vm.startPrank(alice);
        vm.expectRevert(SecureVault.InsufficientBalance.selector);
        vault.flashLoan(1000 ether, address(receiver), "");
        vm.stopPrank();
    }

    function test_GetBalance() public {
        vm.startPrank(alice);
        vault.deposit{value: 5 ether}();
        assertEq(vault.getBalance(alice), 5 ether);
        vm.stopPrank();
    }

    function test_MultipleDeposits() public {
        vm.startPrank(alice);
        vault.deposit{value: 5 ether}();
        vault.deposit{value: 3 ether}();
        assertEq(vault.getBalance(alice), 8 ether);
        vm.stopPrank();
    }
}
