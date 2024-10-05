// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VirtualToken} from "../src/VirtualToken.sol";
import {V2Factory} from "../src/V2Factory.sol";
import {DexFees} from "../src/DexFees.sol";
import {LamboTokenV2} from "../src/LamboTokenV2.sol";
import {AggregationRouterV6, IWETH} from "../src/libraries/1inchV6.sol";
import {LamboV2Router} from "../src/LamboV2Router.sol";
import {LaunchPadUtils} from "../src/Utils/LaunchPadUtils.sol";
import "forge-std/console2.sol";

contract DeployAll is Script {
    // forge script script/deployAll.s.sol --rpc-url https://base-rpc.publicnode.com --broadcast -vvvv --legacy
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address multiSigAdmin = vm.addr(privateKey);

        vm.startBroadcast(privateKey);

        DexFees dexFees = new DexFees();
        console2.log("DexFees address:", address(dexFees));
        
        LamboTokenV2 lamboTokenV2 = new LamboTokenV2();
        console2.log("LamboTokenV2 address:", address(lamboTokenV2));
        
        VirtualToken vETH = new VirtualToken("vETH", "vETH", LaunchPadUtils.NATIVE_TOKEN, multiSigAdmin);
        console2.log("VirtualToken address:", address(vETH));
        
        V2Factory factory = new V2Factory(
            multiSigAdmin,
            payable(address(dexFees)),
            address(lamboTokenV2),
            address(vETH)
        );
        console2.log("V2Factory address:", address(factory));

        LamboV2Router lamboRouter = new LamboV2Router(
            address(vETH),
            address(LaunchPadUtils.UNISWAP_POOL_FACTORY_),
            address(factory)
        );
        console2.log("LamboV2Router address:", address(lamboRouter));

        vETH.updateFactory(address(factory));
        vETH.addToWhiteList(address(lamboRouter));
        vETH.addToWhiteList(multiSigAdmin);
        factory.setLamboRouter(address(lamboRouter));

        vm.stopBroadcast();
    }

}
