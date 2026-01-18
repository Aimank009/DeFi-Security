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
    error InvalidAddress();
    error HealthFactorBelowOne();
    error HealthFactorAboveOne();
    error TransferFailed();
    error ZeroAmount();

    constructor(address _oracleAddress, address _stableCoin) {
        oracle = IPriceOracle(_oracleAddress);
        stableCoin = IERC20(_stableCoin);
    }

    function depositCollateral() external payable override nonReentrant {
        if (msg.value == 0) revert InsufficientCollateral();
        collateral[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    function getHealthFactor(
        address _user
    ) public view override returns (uint256) {
        if (_user == address(0)) revert InvalidAddress();

        uint256 collateralValue = (collateral[_user] *
            oracle.getPrice(address(0))) / 1e18;
        uint256 debtValue = debt[_user];
        if (debtValue == 0) return type(uint256).max;

        uint256 healthFactor = (collateralValue *
            LIQUIDATION_THRESHOLD *
            HEALTH_PRECISION) / (debtValue * 100);

        return healthFactor;
    }
}
