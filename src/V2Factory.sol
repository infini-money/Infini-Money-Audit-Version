// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DexFees} from "./DexFees.sol";
import {LamboTokenV2} from "./LamboTokenV2.sol";
import {VirtualToken} from "./VirtualToken.sol";
import {LaunchPadUtils} from "./Utils/LaunchPadUtils.sol";
import {IPool} from "./interfaces/Uniswap/IPool.sol";
import {IPoolFactory} from "./interfaces/Uniswap/IPoolFactory.sol";
import {UniswapV2Library} from "./libraries/UniswapV2Library.sol";
import {LamboV2Router} from "./LamboV2Router.sol";

contract V2Factory {
    uint256 public tokenNonce;
    address public multiSig;
    address payable public dexFees;
    address public immutable lamboTokenImplementation;
    address public lamboRouter;
    mapping(address => bool) public whiteList;

    event TokenDeployed(address quoteToken);
    event PoolCreated(address virtualLiquidityToken, address quoteToken, address pool, uint256 virtualLiquidityAmount);

    constructor(address _multiSig, address payable _dexFees, address _lamboTokenImplementation) {
        tokenNonce = 1;
        multiSig = _multiSig;
        dexFees = _dexFees;
        lamboTokenImplementation = _lamboTokenImplementation;
    }

    modifier onlyWhiteListed(address virtualLiquidityToken) {
        require(whiteList[virtualLiquidityToken], "virtualLiquidityToken is not in the whitelist");
        _;
    }

    function setDexFees(address payable _dexFees) public {
        require(msg.sender == multiSig, "Only multiSig can set dexFees");
        dexFees = _dexFees;
    }

    function setLamboRouter(address _lamboRouter) public {
        require(msg.sender == multiSig, "Only multiSig can set lamboRouter");
        lamboRouter = _lamboRouter;
    }

    function addVTokenWhiteList(address virtualLiquidityToken) public {
        require(msg.sender == multiSig, "Only multiSig can add to whitelist");
        whiteList[virtualLiquidityToken] = true;
    }

    function removeVTokenWhiteList(address virtualLiquidityToken) public {
        require(msg.sender == multiSig, "Only multiSig can remove from whitelist");
        whiteList[virtualLiquidityToken] = false;
    }

    function _deployLamboToken(string memory name, string memory tickname) internal returns (address quoteToken) {
        // Create a deterministic clone of the LamboToken implementation
        bytes32 salt = keccak256(abi.encodePacked(name, tickname, tokenNonce));
        quoteToken = Clones.cloneDeterministic(lamboTokenImplementation, salt);

        // Initialize the cloned LamboToken
        LamboTokenV2(quoteToken).initialize(name, tickname);
        tokenNonce = tokenNonce + 1;

        emit TokenDeployed(quoteToken);
    }

    function createLaunchPad(
        string memory name,
        string memory tickname,
        uint256 virtualLiquidityAmount,
        address virtualLiquidityToken
    ) public onlyWhiteListed(virtualLiquidityToken) returns (address quoteToken, address pool) {
        quoteToken = _deployLamboToken(name, tickname);
        pool = IPoolFactory(LaunchPadUtils.UNISWAP_POOL_FACTORY_).createPair(virtualLiquidityToken, quoteToken);

        VirtualToken(virtualLiquidityToken).takeLoan(pool, virtualLiquidityAmount);
        IERC20(quoteToken).transfer(pool, LaunchPadUtils.TOTAL_AMOUNT_OF_QUOTE_TOKEN);

        IPool(pool).mint(dexFees);
        DexFees(payable(dexFees)).BurnOrLockedFees(address(pool));

        emit PoolCreated(virtualLiquidityToken, quoteToken, pool, virtualLiquidityAmount);
    }

    function addVirtualLiquidity(
        address virtualLiquidityToken,
        address quoteToken,
        uint256 amountVirtualDesired,
        uint256 amountQuoteMin
    ) public onlyWhiteListed(virtualLiquidityToken) returns (uint256 amountQuoteOptimal) {
        address pool = UniswapV2Library.pairFor(LaunchPadUtils.UNISWAP_POOL_FACTORY_, virtualLiquidityToken, quoteToken);
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(LaunchPadUtils.UNISWAP_POOL_FACTORY_, virtualLiquidityToken, quoteToken);

        amountQuoteOptimal = UniswapV2Library.quote(amountVirtualDesired, reserveA, reserveB);
        require(amountQuoteOptimal >= amountQuoteMin, "LamboFactory addVirtualLiquidity: INSUFFICIENT_Quote_AMOUNT");

        VirtualToken(virtualLiquidityToken).takeLoan(pool, amountVirtualDesired);
        IERC20(quoteToken).transferFrom(msg.sender, pool, amountQuoteOptimal);

        IPool(pool).mint(dexFees);
        DexFees(payable(dexFees)).BurnOrLockedFees(address(pool));
    }
}
