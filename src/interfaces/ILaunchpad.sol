pragma solidity ^0.8.20;

interface ILaunchpad {
    error OnlyRouter();
    error LaunchPoolhHasBeenInited();
    error supplyNotEnough();
    error InsufficientPayment();
    error InsufficientAmountOut();
    error TransferAmountOutFailed();
    error QuoteTokenNotEnough();
    error BaseTokenNotEnough();
    error MinBuyInNotReach();
    error InsufficientOutputAmount();
    error K();
    error K2();
    error InvalidTo();
    error InsufficientLiquidity();
    error IsPaused();
    error PoolIsEnd();
    error InsufficientInputAmount();
    error PoolIsNotEnd();
     
    event PoolStateChange(uint256 oldBaseTokenReceive, uint256 newBaseTokenReceive, uint256 oldQuoteTokenSupply, uint256 newQuoteTokenSupply);
    event PoolInit(address baseToken, address quoteToken, address factory, uint256 quoteTokenTotalAmount);
    event Sync(uint256 reserve0, uint256 reserve1);
    event Fees(address sender, uint256 amount);

    function getTargetReceiveAmount() external view returns(uint256);
    function getPoolFeeRate() external view returns (uint256);
    function getPoolFee() external view returns (address);
    function IsPoolEnd() external view returns (bool);
    function swap(uint256 amountXIn,uint256 amountYIn, uint256 amountXOut, uint256 amountYOut, address to) external;
    function getPoolState() external view returns (address, address, uint256, uint256);
    function getBuyPrice(uint256 amount) external view returns (uint256);
    function getSellPrice(uint256 amount) external view returns (uint256);
}


