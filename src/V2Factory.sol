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

import {LamboV2Router} from "./LamboV2Router.sol";

contract V2Factory {
    address public multiSig;
    address payable public dexFees;
    address public virtualLiquidityToken;
    address public immutable lamboTokenImplementation;
    address public lamboRouter;
    
    event TokenDeployed(address quoteToken);
    event PoolCreated(address quoteToken, address pool);

    constructor(address _multiSig, address payable _dexFees, address _lamboTokenImplementation, address _virtualLiquidityToken) {
        multiSig = _multiSig;   
        dexFees = _dexFees;
        virtualLiquidityToken = _virtualLiquidityToken;
        lamboTokenImplementation = _lamboTokenImplementation;
    }

    function setDexFees(address payable _dexFees) public {
        require(msg.sender == multiSig, "Only multiSig can set dexFees");
        dexFees = _dexFees;
    }

    function setLamboRouter(address _lamboRouter) public {
        require(msg.sender == multiSig, "Only multiSig can set lamboRouter");
        lamboRouter = _lamboRouter;
    }

    function _deployLamboToken(
        string memory name,
        string memory tickname
    ) internal returns (address quoteToken) {

        // Create a deterministic clone of the LamboToken implementation
        bytes32 salt = keccak256(abi.encodePacked(name, tickname, block.timestamp));
        quoteToken = Clones.cloneDeterministic(lamboTokenImplementation, salt);

        // Initialize the cloned LamboToken
        LamboTokenV2(quoteToken).initialize(
            name, 
            tickname
        );

        emit TokenDeployed(quoteToken);
    }

    function createLaunchPad(
        string memory name, 
        string memory tickname,
        uint256 virtualLiquidityAmount,
        address virtualLiquidityToken
    ) public returns (address quoteToken, address pool)  {
        quoteToken = _deployLamboToken(name, tickname);
        pool = IPoolFactory(LaunchPadUtils.UNISWAP_POOL_FACTORY_).createPair(virtualLiquidityToken, quoteToken);

        VirtualToken(virtualLiquidityToken).takeLoan(pool, virtualLiquidityAmount);
        IERC20(quoteToken).transfer(pool, LaunchPadUtils.TOTAL_AMOUNT_OF_QUOTE_TOKEN);

        IPool(pool).mint(dexFees);
        DexFees(payable(dexFees)).BurnOrLockedFees(address(pool));

        emit PoolCreated(quoteToken, pool);
    }

    function createLaunchPadAndInitialBuy(
        string memory name, 
        string memory tickname,
        uint256 virtualLiquidityAmount,
        address virtualLiquidityToken,
        uint256 buyAmount
    ) public payable returns (address quoteToken, address pool) {
        (quoteToken, pool) = createLaunchPad(name, tickname, virtualLiquidityAmount, virtualLiquidityToken);

        // minReturn can be set to 0 because initial buy
        LamboV2Router(payable(lamboRouter)).buyQuote{value: buyAmount}(quoteToken, buyAmount, 0);

        emit PoolCreated(quoteToken, pool);
    }

}
