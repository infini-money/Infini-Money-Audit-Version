// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {V2Factory} from "../src/V2Factory.sol";
import {VirtualToken} from "../src/VirtualToken.sol";
import {LamboTokenV2} from "../src/LamboTokenV2.sol";
import {LaunchPadUtils} from "../src/Utils/LaunchPadUtils.sol";
import "forge-std/console2.sol";

contract DeployPool is Script {

    address FactoryAddress = 0x28ABC402F84A870CAdDd289a2c0e5231426E13cb;
    address vETH = 0x3479AF87f1587B8164700d9732CFFdeB7cf32522;
    // forge script script/DeployPool.s.sol --rpc-url https://base-rpc.publicnode.com --broadcast -vvvv --legacy
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address multiSigAdmin = vm.addr(privateKey);

        vm.startBroadcast(privateKey);
        // 创建 LaunchPad 并部署池
        (address quoteToken, address pool) = V2Factory(FactoryAddress).createLaunchPad(
            "LamboV2",
            "LamboV2",
            3.5 ether,
            address(vETH)
        );
        console2.log("QuoteToken address:", address(quoteToken));
        console2.log("Pool address:", address(pool));

        vm.stopBroadcast();
    }
}
