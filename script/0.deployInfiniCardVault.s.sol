
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/InfiniCardVault.sol";
import {InfiniEthenaStrategyVault} from "../src/strategys/ethena/InfiniEthenaStrategyVault.sol";
import {InfiniMorphoStrategyVault} from "../src/strategys/morpho/InfiniMorphoStrategyVault.sol";
import {InfiniEthenaStrategyManager} from "../src/strategys/ethena/InfiniEthenaStrategyManager.sol";

contract DeployInfiniCardVault is Script {
    // forge script script/0.deployInfiniCardVault.s.sol:DeployInfiniCardVault --broadcast --rpc-url https://eth.llamarpc.com --legacy
    //   vault: 0x1eDE905c7e3CcA39894333f7E7fd2751CeD68a21
    //   ethena strategy: 0x0280e57c5A352d98632b9Fde01d4D6AD987306D5
    //   morpho strategy: 0x135BfAcB085376E612e2BF3e6f33FFF722bBE5C9

    function run() external {
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        address adminRole = vm.addr(adminPrivateKey);
        address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address USDE = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
        address shaneson = 0x790ac11183ddE23163b307E3F7440F2460526957;
        

        vm.startBroadcast(adminPrivateKey);

        InfiniCardVault vault = new InfiniCardVault(adminRole, adminRole);
        vault.grantRole(vault.DEFAULT_ADMIN_ROLE(), adminRole);
        vault.addCusdianToWhiteList(shaneson);

        // strategys
        address EthenaMintingAddress = 0xe3490297a08d6fC8Da46Edb7B6142E4F461b62D3;

        InfiniEthenaStrategyVault ethena = new InfiniEthenaStrategyVault(
            adminRole,
            address(vault),
            USDT,
            USDE,
            EthenaMintingAddress
        );
        vault.addStrategy(address(ethena));

        InfiniEthenaStrategyManager ethenaManager = new InfiniEthenaStrategyManager(
            address(ethena),
            address(adminRole),
            adminRole
        );

        address MorphoMarket = 0xd63070114470f685b75B74D60EEc7c1113d33a3D;

        InfiniMorphoStrategyVault morpho = new InfiniMorphoStrategyVault(
            adminRole,
            address(vault),
            USDC,
            USDE,
            MorphoMarket,
            adminRole
        );
        vault.addStrategy(address(morpho));

        console2.log( "vault:", address(vault));
        console2.log( "ethena strategy:", address(ethena));
        console2.log( "ethena manager:", address(ethenaManager));
        console2.log( "morpho strategy:", address(morpho));

        vm.stopBroadcast();
    }
}