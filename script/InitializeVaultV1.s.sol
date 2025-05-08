// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VaultV1} from "../src/VaultV1.sol";
import {TestToken} from "../src/TestToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract InitializeVaultV1 is Script {
    address vault = 0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519;
    address owner = vm.envAddress("OWNER_ADDRESS");
    VaultV1 vaultV1 = VaultV1(vault);
    
    function run() external returns (address, address) {
        address vaultV1Address = DevOpsTools.get_most_recent_deployment(
            "VaultV1",
            block.chainid
        );

        console.log("Token Owner Address: ", owner);
        console.log("Most recently deployed vault address: ", vaultV1Address);

  

        address tokenAddress = deployToken();
        initializeVaultV1(tokenAddress, owner);

        console.log("Token Contract Address: ", address(tokenAddress));

        return (vaultV1Address, address(tokenAddress));
    }

    function deployToken() public returns (address) {
        vm.startBroadcast();
        TestToken token = new TestToken(owner);
        vm.stopBroadcast();
        return address(token);
    }

    function initializeVaultV1(address _tokenAddress, address _owner) public{
        vm.startBroadcast();
        vaultV1.initialize(_tokenAddress, _owner);
        vm.stopBroadcast();
    }
}
