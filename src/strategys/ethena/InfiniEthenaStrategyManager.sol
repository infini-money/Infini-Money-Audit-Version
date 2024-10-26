// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseStrategyManager} from "@InfiniCard/strategys/BaseStrategyManager.sol";
import {IStrategyVault} from "@InfiniCard/interfaces/IStrategyVault.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; 

contract InfiniEthenaStrategyManager is BaseStrategyManager {
    using SafeERC20 for IERC20;

    constructor(
        address _strategy, 
        address _treasure, 
        address _adminRole
    ) BaseStrategyManager(_strategy, _treasure, _adminRole) {}

    function getStrategyStatus() external view override returns (StrategyStatus memory status) {
        status = StrategyStatus({
            position: IStrategyVault(strategyVault).getPosition(),
            profit: _getProfit(),
            underlyingToken: IStrategyVault(strategyVault).underlyingToken(),
            strategyAddress: address(strategyVault)
        });
    }

    function settle(uint256 unSettleProfit) external override onlyRole(ADMIN_ROLE) {
        uint256 profit = _getProfit();
        if (profit < unSettleProfit) revert ProfitIsNotEnough();

        uint256 protocolProfit = unSettleProfit * carryRate / 10000;
        uint256 settleProfit = unSettleProfit - protocolProfit;

        IERC20(profitToken).safeTransfer(infiniTreasure, protocolProfit); // 修改为 safeTransfer
        IERC20(profitToken).safeTransfer(strategyVault, settleProfit); // 修改为 safeTransfer

        emit Settlement(profitToken, protocolProfit, settleProfit);
    }

    function _getProfit() internal view returns(uint256) {
        return IERC20(profitToken).balanceOf(address(this));
    }

}
