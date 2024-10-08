// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import './libraries/UniswapV2Library.sol';
import {IPool} from "./interfaces/Uniswap/IPool.sol";
import {VirtualToken} from "./VirtualToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {V2Factory} from "./V2Factory.sol";


contract LamboV2Router {
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public immutable vETH;
    address public immutable lamboFactory;
    address public immutable uniswapV2Factory;

    event BuyQuote(address quoteToken, uint256 amountXIn, uint256 amountXOut);
    event SellQuote(address quoteToken, uint256 amountYIn, uint256 amountXOut);

    constructor(address _vETH, address _uniswapV2Factory, address _lamboFactory) public {
        vETH = _vETH;
        lamboFactory = _lamboFactory;
        uniswapV2Factory = _uniswapV2Factory;
    }

    function createLaunchPadAndInitialBuy(
        string memory name, 
        string memory tickname,
        uint256 virtualLiquidityAmount,
        address virtualLiquidityToken,
        uint256 buyAmount
    ) public payable returns (address quoteToken, address pool, uint256 amountYOut) {
        (quoteToken, pool) = V2Factory(lamboFactory).createLaunchPad(name, tickname, virtualLiquidityAmount, virtualLiquidityToken);

        amountYOut = _buyQuote(quoteToken, buyAmount, 0);
    }

    function getBuyQuote(
        address targetToken,
        uint256 amountIn
    ) public view returns(uint256 amount) {
        // TIPs: ETH -> vETH = 1:1
        (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(uniswapV2Factory, vETH, targetToken);

        // Calculate the amount of Meme to be received
        amount = UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getSellQuote(
        address targetToken,
        uint256 amountIn
    ) public view returns(uint256 amount) {
        // TIPS: vETH -> ETH = 1: 1 - fee
        (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(uniswapV2Factory, targetToken, vETH);

        // get vETH Amount
        uint256 amountXOut = UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);

        // vETH -> wETH
        amount = VirtualToken(vETH).getCashOutQuote(amountXOut);
    }

    function buyQuote(
        address quoteToken,
        uint256 amountXIn,
        uint256 minReturn
    ) public payable returns(uint256 amountYOut) {
        amountYOut = _buyQuote(quoteToken, amountXIn, minReturn);
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
        // amountXOut will get the fee
        amountXOut = VirtualToken(vETH).cashOut(amountXOut);
        payable(msg.sender).transfer(amountXOut);

        // Check if the received amount meets the minimum return requirement
        require(amountXOut >= minReturn, "MinReturn Error");

        // Emit the swap event
        emit SellQuote(quoteToken, amountYIn, amountXOut);

    }

    function _buyQuote(
        address quoteToken,
        uint256 amountXIn,
        uint256 minReturn
    ) internal returns(uint256 amountYOut) {
        require(msg.value >= amountXIn, "Insufficient msg.value");
        
        address pair = UniswapV2Library.pairFor(uniswapV2Factory, vETH, quoteToken);
        
        (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(uniswapV2Factory, vETH, quoteToken);

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
        require(amountYOut >= minReturn, "MinReturn Error");

        // Refund excess ETH if any, left 1 wei to save gas
        if (msg.value > amountXIn + 1) {
            payable(msg.sender).transfer(msg.value - amountXIn - 1);
        }
        
        emit BuyQuote(quoteToken, amountXIn, amountYOut);

    }

    receive() external payable {}
}
