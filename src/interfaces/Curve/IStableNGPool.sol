pragma solidity ^0.8.23;

interface IStableNGPool {
    function add_liquidity(
        uint256[] memory _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external returns (uint256);
}