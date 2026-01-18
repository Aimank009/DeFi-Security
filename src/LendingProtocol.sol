// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILendingProtocol.sol";
import "./interfaces/IPriceOracle.sol";
import "./events/LendingEvents.sol";

contract LendingProtocol is ILendingProtocol, LendingEvents, ReentrancyGuard {
    uint256 public constant LTV = 75;
    uint256 public constant LIQUIDATION_THRESHOLD = 80;
    uint256 public constant LIQUIDATION_BONUS = 10;
    uint256 public constant PRECISION = 100;
    uint256 public constant HEALTH_PRECISION = 1e18;

    IPriceOracle public oracle;
    IERC20 public stableCoin;

    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;

    error InsufficientCollateral();
    error HealthFactorBelowOne();
    error HealthFactorAboveOne();
    error TransferFailed();
    error ZeroAmount();

    constructor(address _oracleAddress, address _stableCoin) {
        oracle = _oracleAddress;
        stableCoin = _stableCoin;
    }
}
