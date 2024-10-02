// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {VirtualToken} from "../src/VirtualToken.sol";
import {V2Factory} from "../src/V2Factory.sol";
import {DexFees} from "../src/DexFees.sol";
import {LamboTokenV2} from "../src/LamboTokenV2.sol";
import {AggregationRouterV6, IWETH} from "../src/libraries/1inchV6.sol";
import {LamboV2Router} from "../src/LamboV2Router.sol";
import {LaunchPadUtils} from "../src/Utils/LaunchPadUtils.sol";

contract BaseTest is Test {
    VirtualToken public vETH;
    V2Factory public factory;
    DexFees public dexFees;
    AggregationRouterV6 public aggregatorRouter;
    LamboV2Router public lamboRouter;
    LamboTokenV2 public lamboTokenV2;

    address public multiSigAdmin = makeAddr("multiSigAdmin");

    function setUp() public virtual {
        // ankr eth mainnet
        // vm.createSelectFork("https://rpc.ankr.com/eth");

        // ankr base mainnet
        vm.createSelectFork("https://rpc.ankr.com/base");

        dexFees = new DexFees();
        lamboTokenV2 = new LamboTokenV2();

        vETH = new VirtualToken("vETH", "vETH", LaunchPadUtils.NATIVE_TOKEN, multiSigAdmin);
        factory = new V2Factory(
            multiSigAdmin,
            payable(address(dexFees)),
            address(lamboTokenV2),
            address(vETH)
        );

        aggregatorRouter = new AggregationRouterV6(IWETH(LaunchPadUtils.WETH));

        lamboRouter = new LamboV2Router(
            address(vETH),
            address(LaunchPadUtils.UNISWAP_POOL_FACTORY_),
            address(factory)
        );


        vm.startPrank(multiSigAdmin);
        vETH.updateFactory(address(factory));
        vETH.addToWhiteList(address(lamboRouter));
        factory.setLamboRouter(address(lamboRouter));
        vm.stopPrank();
    }
}
