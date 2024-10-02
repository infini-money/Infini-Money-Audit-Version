pragma solidity ^0.8.20;

interface IRouter {
    error MinReturnNotReach();
    error InvalidPool();
    error InvalidPoolFactory();
    error InitialBuyLimit();

    error NotEnoughBaseToken();


    event Trade(uint256 pool, address fromToken, address toToken, uint256 amountIn, uint256 amountOut, uint256 minReturn);
    event CreateLaunchPadAndInitialBuy(address baseToken, address quoteToken, address pool, uint256 amountXIn, uint256 amountYOut);
}