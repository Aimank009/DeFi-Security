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

    receive() external payable {}

    function depositCollateral() external payable override nonReentrant {
        if (msg.value == 0) revert InsufficientCollateral();
        collateral[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    function _calculateHealthFactor(
        address _user,
        uint256 _collateralValue,
        uint256 _debtAmount
    ) internal view returns (uint256) {
        if (_debtAmount == 0) return type(uint256).max;
        return
            (_collateralValue * LIQUIDATION_THRESHOLD * HEALTH_PRECISION) /
            (_debtAmount * PRECISION);
    }

    function getHealthFactor(
        address _user
    ) public view override returns (uint256) {
        return
            _calculateHealthFactor(
                _user,
                (collateral[_user] * oracle.getPrice(address(0))) / 1e18,
                debt[_user]
            );
    }

    function borrow(uint256 _amount) external override nonReentrant {
        if (_amount == 0) revert ZeroAmount();

        uint256 newDebt = debt[msg.sender] + _amount;
        if (
            _calculateHealthFactor(
                msg.sender,
                (collateral[msg.sender] * oracle.getPrice(address(0))) / 1e18,
                newDebt
            ) < HEALTH_PRECISION
        ) revert HealthFactorBelowOne();

        debt[msg.sender] = newDebt;
        bool success = stableCoin.transfer(msg.sender, _amount);
        if (!success) revert TransferFailed();

        emit Borrowed(msg.sender, _amount);
    }

    function repay(uint256 _amount) external override nonReentrant {
        if (_amount == 0) revert ZeroAmount();

        uint256 repayAmount = _amount > debt[msg.sender]
            ? debt[msg.sender]
            : _amount;
        bool success = stableCoin.transferFrom(
            msg.sender,
            address(this),
            repayAmount
        );
        if (!success) revert TransferFailed();

        debt[msg.sender] -= repayAmount;

        emit Repaid(msg.sender, repayAmount);
    }

    function withdrawCollateral(
        uint256 _amount
    ) external override nonReentrant {
        if (_amount == 0) revert ZeroAmount();
        if (collateral[msg.sender] < _amount) revert InsufficientCollateral();

        uint256 newCollateral = collateral[msg.sender] - _amount;
        if (debt[msg.sender] > 0) {
            uint256 projectedHealth = _calculateHealthFactor(
                msg.sender,
                (newCollateral * oracle.getPrice(address(0))) / 1e18,
                debt[msg.sender]
            );
            if (projectedHealth < HEALTH_PRECISION)
                revert HealthFactorBelowOne();
        }

        collateral[msg.sender] = newCollateral;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) revert TransferFailed();

        emit CollateralWithdrawn(msg.sender, _amount);
    }

    function liquidate(address _user) external override nonReentrant {
        if (getHealthFactor(_user) >= HEALTH_PRECISION)
            revert HealthFactorAboveOne();

        uint256 userDebt = debt[_user];
        uint256 userCollateral = collateral[_user];

        uint256 ethPrice = oracle.getPrice(address(0));
        uint256 collateralToSeize = (userDebt *
            1e18 *
            (PRECISION + LIQUIDATION_BONUS)) / (ethPrice * PRECISION);

        if (collateralToSeize > userCollateral) {
            collateralToSeize = userCollateral;
        }

        bool success = stableCoin.transferFrom(
            msg.sender,
            address(this),
            userDebt
        );
        if (!success) revert TransferFailed();

        debt[_user] = 0;
        collateral[_user] -= collateralToSeize;

        (bool ethSuccess, ) = payable(msg.sender).call{
            value: collateralToSeize
        }("");
        if (!ethSuccess) revert TransferFailed();

        emit Liquidated(msg.sender, _user, userDebt, collateralToSeize);
    }
}
