// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import './libraries/UniswapV2Library.sol';
import {IPool} from "./interfaces/Uniswap/IPool.sol";
import {VirtualToken} from "./VirtualToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console2} from "forge-std/console2.sol";

contract LamboV2Router {
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public immutable vETH;
    address public immutable lamboFactory;
    address public immutable uniswapV2Factory;

    event Swap(address indexed sender, uint256 amountXIn, uint256 amountYOut, address indexed vETH, address indexed quoteToken);

    constructor(address _vETH, address _uniswapV2Factory, address _lamboFactory) public {
        vETH = _vETH;
        lamboFactory = _lamboFactory;
        uniswapV2Factory = _uniswapV2Factory;
    }

    function buyQuote(
        address quoteToken,
        uint256 amountXIn,
        uint256 minReturn
    ) public payable returns(uint256 amountYOut) {
        require(msg.value >= amountXIn, "Insufficient msg.value");
        
        address pair = UniswapV2Library.pairFor(uniswapV2Factory, vETH, quoteToken);
        
        (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(uniswapV2Factory, vETH, quoteToken);

        console2.log("reserveIn: ", reserveIn );
        console2.log("reserveOut: ", reserveOut);

        // Calculate the amount of quoteToken to be received
        amountYOut = UniswapV2Library.getAmountOut(amountXIn, reserveIn, reserveOut);
        require(amountYOut >= minReturn, "Insufficient output amount");

        // Transfer vETH to the pair
        VirtualToken(vETH).cashIn{value: amountXIn}();
        assert(VirtualToken(vETH).transfer(pair, amountXIn));

        // Perform the swap
        (uint amount0Out, uint amount1Out) = vETH < quoteToken ? (uint(0), amountYOut) : (amountYOut, uint(0));
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, msg.sender, new bytes(0));

        // Check if the received amount meets the minimum return requirement
        require(IERC20(quoteToken).balanceOf(msg.sender) >= minReturn, "MinReturn Error");

        // Refund excess ETH if any, left 1 wei to save gas
        if (msg.value > amountXIn + 1) {
            payable(msg.sender).transfer(msg.value - amountXIn - 1);
        }

        // Emit the swap event
        emit Swap(msg.sender, amountXIn, amountYOut, vETH, quoteToken);
    }

    function sellQuote(
        address quoteToken,
        uint256 amountYIn,
        uint256 minReturn
    ) public returns(uint256 amountXOut) {
        require(IERC20(quoteToken).transferFrom(msg.sender, address(this), amountYIn), "Transfer failed");

        address pair = UniswapV2Library.pairFor(uniswapV2Factory, quoteToken, vETH);

        (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(uniswapV2Factory, quoteToken, vETH);

        // Calculate the amount of vETH to be received
        amountXOut = UniswapV2Library.getAmountOut(amountYIn, reserveIn, reserveOut);
        require(amountXOut >= minReturn, "Insufficient output amount");

        // Transfer quoteToken to the pair
        assert(IERC20(quoteToken).transfer(pair, amountYIn));

        // Perform the swap
        (uint amount0Out, uint amount1Out) = quoteToken < vETH ? (uint(0), amountXOut) : (amountXOut, uint(0));
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), new bytes(0));

        // Convert vETH to ETH and send to the user
        VirtualToken(vETH).cashOut(amountXOut);
        payable(msg.sender).transfer(amountXOut);

        // Check if the received amount meets the minimum return requirement
        require(amountXOut >= minReturn, "MinReturn Error");

        // Emit the swap event
        emit Swap(msg.sender, amountYIn, amountXOut, vETH, quoteToken);
    }

    receive() external payable {}
}
