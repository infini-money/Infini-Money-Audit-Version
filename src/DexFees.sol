// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPool} from "../src/interfaces/Uniswap/IPool.sol";

/// @title DexFees
/// @notice Contract used as 1:1 pool relationship to split out fees.
/// @notice Ensures curve does not need to be modified for LP shares.
contract DexFees {
    address public constant DEAD_ADDRESS = address(0x0);

    function BurnOrLockedFees(address lptoken) external {
        _BurnLP(lptoken);
    }

    function _BurnLP(address lptoken) internal {
        IERC20(lptoken).transfer(DEAD_ADDRESS, IERC20(lptoken).balanceOf(address(this)));
    }

    receive() external payable {}
}