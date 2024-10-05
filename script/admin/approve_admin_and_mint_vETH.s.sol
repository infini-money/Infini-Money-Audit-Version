// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VirtualToken} from "../../src/VirtualToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract ApproveAdminMintVETH is Script {

    address vETH_Address = address(0xAcFa296E66b65daE12cd63aeeF53be8D5Cc0f329);

    // forge script script/admin/approve_admin_and_mint_vETH.s.sol --rpc-url https://base-rpc.publicnode.com --broadcast -vvvv --legacy
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address multiSigAdmin = vm.addr(privateKey);

        uint256 beforeAmount0 = VirtualToken(vETH_Address).balanceOf(multiSigAdmin);
        vm.startBroadcast(privateKey);

        // VirtualToken(vETH_Address).cashIn{value: 2 ether}();
        // require(VirtualToken(vETH_Address).balanceOf(multiSigAdmin) == beforeAmount0 + 2 ether);


        uint256 beforeAmount = payable(multiSigAdmin).balance;
        VirtualToken(vETH_Address).cashOut(2 ether);
        require(payable(multiSigAdmin).balance == beforeAmount + 2 ether);

        vm.stopBroadcast();
    }
}