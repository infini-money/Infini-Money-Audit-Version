// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VirtualToken} from "../../src/VirtualToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "forge-std/console2.sol";

contract ApproveAdminMintVETH is Script {

    address vETH_Address = address(0x829f02110c49edbcF393a7cD0F7cDA2f56b341D5);

    // forge script script/admin/approve_admin_and_mint_vETH.s.sol --rpc-url https://base-rpc.publicnode.com --broadcast -vvvv --legacy
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        uint256 shanesonPrivateKey = vm.envUint("SHANESON_PRIVATE_KEY");
        address multiSigAdmin = vm.addr(privateKey);
        address shaneson = 0x790ac11183ddE23163b307E3F7440F2460526957;

        // vm.startBroadcast(privateKey);

        // // VirtualToken(vETH_Address).addToWhiteList(shaneson);
        // // VirtualToken(vETH_Address).withdraw(payable(vETH_Address).balance);

        // vm.stopBroadcast();

        vm.startBroadcast(privateKey);

        uint256 beforeAmount0 = VirtualToken(vETH_Address).balanceOf(multiSigAdmin);
        VirtualToken(vETH_Address).cashIn{value: 2 ether}();
        require(VirtualToken(vETH_Address).balanceOf(multiSigAdmin) == beforeAmount0 + 2 ether);

        VirtualToken(vETH_Address).transfer(shaneson, VirtualToken(vETH_Address).balanceOf(multiSigAdmin));

        vm.stopBroadcast();

        vm.startBroadcast(shanesonPrivateKey);

        VirtualToken(vETH_Address).cashOut(2 ether);

        vm.stopBroadcast();

    }

    receive() external payable {}
}