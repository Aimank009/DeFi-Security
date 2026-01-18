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

    function _calculateHealthFactor(
        address _user,
        uint256 _debtAmount
    ) internal view returns (uint256) {
        if (_debtAmount == 0) return type(uint256).max;

        uint256 collateralValue = (collateral[_user] *
            oracle.getPrice(address(0))) / 1e18;
        return
            (collateralValue * LIQUIDATION_THRESHOLD * HEALTH_PRECISION) /
            (_debtAmount * PRECISION);
    }

    function getHealthFactor(
        address _user
    ) public view override returns (uint256) {
        return _calculateHealthFactor(_user, debt[_user]);
    }

    function borrow(uint256 _amount) external override nonReentrant {
        if (msg.sender == address(0)) revert InvalidAddress();
        if (_amount == 0) revert ZeroAmount();

        uint256 newDebt = debt[msg.sender] + _amount;
        if (_calculateHealthFactor(msg.sender, newDebt) < HEALTH_PRECISION)
            revert HealthFactorBelowOne();

        debt[msg.sender] = newDebt;
        bool success = stableCoin.transfer(msg.sender, _amount);
        if (!success) revert TransferFailed();

        emit Borrowed(msg.sender, _amount);
    }
}
