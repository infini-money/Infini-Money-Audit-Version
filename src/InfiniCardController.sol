// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/AccessControl.sol";
import {StrategyUtils} from "./library/StrategyUtils.sol";
import {IStrategyVault} from "./interfaces/IStrategyVault.sol";

contract InfiniCardController is AccessControl, StrategyUtils {

    address[] strategyList;
    address[] tokenList;

    error StrategyInvalid();
    error CustodianInvalid(); 
    error TokenInvalid();
    error TokenMismatch();

    mapping(address => bool) strategyWhiteList;
    mapping(address => bool) custodianWhiteList;
    mapping(address => bool) tokenWhiteList;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant INFINI_BACKEND_ROLE = keccak256("INFINI_BACKEND_ROLE");
    bytes32 public constant STRATEGY_OPERATOR_ROLE = keccak256("STRATEGY_OPERATOR_ROLE");

    constructor(address _admin_role, address _strategy_operator_role, address _infinity_backend_role) {
        _grantRole(ADMIN_ROLE, _admin_role);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin_role);
        _grantRole(STRATEGY_OPERATOR_ROLE, _strategy_operator_role);
        _grantRole(INFINI_BACKEND_ROLE, _infinity_backend_role);
    }
    
    function removeUnusedToken(address token) onlyRole(ADMIN_ROLE) external {
        _isTokenValid(token); // Ensure the token is in the whitelist
        tokenWhiteList[token] = false; // Remove from the whitelist
        // Remove from tokenList
        for (uint256 i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == token) {
                tokenList[i] = tokenList[tokenList.length - 1]; // Replace with the last element
                tokenList.pop(); // Remove the last element
                break;
            }
        }
    }

    function addStrategy(address strategy) onlyRole(ADMIN_ROLE) external {
        strategyWhiteList[strategy] = true;
        _addToken(IStrategyVault(strategy).underlyingToken());
    }

    function removeStrategy(address strategy) onlyRole(ADMIN_ROLE) external { 
        strategyWhiteList[strategy] = false;
    }

    function addCustodianToWhiteList(address cusdian) onlyRole(ADMIN_ROLE) external {
        custodianWhiteList[cusdian] = true;
    }

    function removeCustodianToWhiteList(address cusdian) onlyRole(ADMIN_ROLE) external {
        custodianWhiteList[cusdian] = false;
    }

    function _addToken(address token) internal {
        tokenWhiteList[token] = true;
        tokenList.push(token);
    }   

    function _withdraw_from_strategy(
        address strategy,
        uint256 amount,
        bytes calldata redeemInfo
    ) internal returns (uint256 actualGetAmount) {
        _isStrategyValid(strategy);

        address underlyingToken = IStrategyVault(strategy).underlyingToken();
        if (_isBalanceEnough(strategy, underlyingToken, amount)) {
            actualGetAmount = IStrategyVault(strategy).withdraw(underlyingToken, amount);
        } else {
            uint256 actualRedeemedAmount = IStrategyVault(strategy).redeem(amount, redeemInfo);

            actualGetAmount = IStrategyVault(strategy).withdraw(underlyingToken, actualRedeemedAmount);            
        }
    }

    function _isTokenValid(address token) internal view {
        if (!tokenWhiteList[token]) {
            revert TokenInvalid();
        }
    }

    function _isStrategyValid(address strategy) internal view {
        if (!strategyWhiteList[strategy]) {
            revert StrategyInvalid(); 
        }
    }

    function _isCustodianValid(address cusdian) internal view  {
        if (!custodianWhiteList[cusdian]) {
            revert CustodianInvalid();
        }
    }
}
