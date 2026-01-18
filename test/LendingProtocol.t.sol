// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/lending-protocol/LendingProtocol.sol";
import "../src/lending-protocol/PriceOracle.sol";
import "../src/mocks/MockUsdt.sol";

contract LendingProtocolTest is Test {
    LendingProtocol public lendingProtocol;
    PriceOracle public oracle;
    MockUSDT public usdt;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public liquidator = makeAddr("liquidator");

    uint256 public constant ETH_PRICE = 2000e18;
    uint256 public constant INITIAL_USDT = 1000000e18;

    function setUp() public {
        oracle = new PriceOracle();
        usdt = new MockUSDT();
        lendingProtocol = new LendingProtocol(address(oracle), address(usdt));

        oracle.setPrice(address(0), ETH_PRICE);

        usdt.mint(address(lendingProtocol), INITIAL_USDT);
        usdt.mint(liquidator, INITIAL_USDT);

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    function test_DepositCollateral() public {
        vm.startPrank(alice);
        lendingProtocol.depositCollateral{value: 10 ether}();
        assertEq(lendingProtocol.getCollateral(alice), 10 ether);
        vm.stopPrank();
    }

    function test_DepositCollateral_RevertOnZero() public {
        vm.startPrank(alice);
        vm.expectRevert(LendingProtocol.InsufficientCollateral.selector);
        lendingProtocol.depositCollateral{value: 0}();
        vm.stopPrank();
    }

    function test_Borrow() public {
        vm.startPrank(alice);
        lendingProtocol.depositCollateral{value: 10 ether}();
        lendingProtocol.borrow(10000e18);
        assertEq(lendingProtocol.getDebt(alice), 10000e18);
        assertEq(usdt.balanceOf(alice), 10000e18);
        vm.stopPrank();
    }

    function test_Borrow_RevertOnLowHealth() public {
        vm.startPrank(alice);
        lendingProtocol.depositCollateral{value: 1 ether}();
        vm.expectRevert(LendingProtocol.HealthFactorBelowOne.selector);
        lendingProtocol.borrow(2000e18);
        vm.stopPrank();
    }

    function test_Repay() public {
        vm.startPrank(alice);
        lendingProtocol.depositCollateral{value: 10 ether}();
        lendingProtocol.borrow(5000e18);

        usdt.approve(address(lendingProtocol), 5000e18);
        lendingProtocol.repay(5000e18);

        assertEq(lendingProtocol.getDebt(alice), 0);
        vm.stopPrank();
    }

    function test_WithdrawCollateral() public {
        vm.startPrank(alice);
        lendingProtocol.depositCollateral{value: 10 ether}();
        lendingProtocol.withdrawCollateral(5 ether);
        assertEq(lendingProtocol.getCollateral(alice), 5 ether);
        vm.stopPrank();
    }

    function test_WithdrawCollateral_RevertOnLowHealth() public {
        vm.startPrank(alice);
        lendingProtocol.depositCollateral{value: 10 ether}();
        lendingProtocol.borrow(10000e18);
        vm.expectRevert(LendingProtocol.HealthFactorBelowOne.selector);
        lendingProtocol.withdrawCollateral(9 ether);
        vm.stopPrank();
    }

    function test_GetHealthFactor() public {
        vm.startPrank(alice);
        lendingProtocol.depositCollateral{value: 10 ether}();
        lendingProtocol.borrow(10000e18);
        uint256 health = lendingProtocol.getHealthFactor(alice);
        assertGt(health, 1e18);
        vm.stopPrank();
    }

    function test_Liquidate() public {
        vm.startPrank(alice);
        lendingProtocol.depositCollateral{value: 10 ether}();
        lendingProtocol.borrow(12000e18);
        vm.stopPrank();

        oracle.setPrice(address(0), 1400e18);

        uint256 health = lendingProtocol.getHealthFactor(alice);
        assertLt(health, 1e18);

        vm.startPrank(liquidator);
        usdt.approve(address(lendingProtocol), 12000e18);
        lendingProtocol.liquidate(alice);
        vm.stopPrank();

        assertEq(lendingProtocol.getDebt(alice), 0);
    }

    function test_Liquidate_RevertOnHealthy() public {
        vm.startPrank(alice);
        lendingProtocol.depositCollateral{value: 10 ether}();
        lendingProtocol.borrow(5000e18);
        vm.stopPrank();

        vm.startPrank(liquidator);
        usdt.approve(address(lendingProtocol), 5000e18);
        vm.expectRevert(LendingProtocol.HealthFactorAboveOne.selector);
        lendingProtocol.liquidate(alice);
        vm.stopPrank();
    }
}
