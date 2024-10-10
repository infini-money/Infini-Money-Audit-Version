


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {InfiniCardVault} from "../../src/InfiniCardVault.sol";

contract MorphoInvestScript is Script {
    // forge script script/strategys/morpho_invest.s.sol:MorphoInvestScript --rpc-url https://eth-pokt.nodies.app --broadcast --legacy
    function run() external {
        // 1. send usdc to infiniCardVault
        address morpho_strategy = 0x8D859BA19cC903cb71F7d36390f694c76821fCE2;
        address payable infiniCardVault = payable(0xB26AaA980fEADD4E06E51ff435d1ac9617D9FAcc);

        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        address adminRole = vm.addr(adminPrivateKey);

        vm.startBroadcast(adminPrivateKey);

        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

        uint256 usdcBalance = IERC20(USDC).balanceOf(adminRole);
        IERC20(USDC).transfer(infiniCardVault, usdcBalance);

        // 2. deposit usdc to morpho
        InfiniCardVault(infiniCardVault).invest(address(morpho_strategy), usdcBalance, "");

        vm.stopBroadcast();

    }
}