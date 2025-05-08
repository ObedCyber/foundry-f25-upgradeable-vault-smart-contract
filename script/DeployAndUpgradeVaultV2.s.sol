// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {VaultV1} from "../src/VaultV1.sol";
import {VaultV2} from "../src/VaultV2.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract DeployAndUpgradeVaultV2 is Script {

    uint256 APY = 50;
    uint256 minimumDeposit = 0.01 ether;

    address owner = vm.addr(vm.envUint("ANVIL_OWNER_ADDRESS"));

    bytes public initData = abi.encodeWithSelector(
            VaultV2.initializeV2.selector,
            owner,
            APY,
            minimumDeposit
        );

    function run() external returns (address) {
        address mostRecentlyDeployedProxy = DevOpsTools.get_most_recent_deployment("ERC1967Proxy", block.chainid);
        console.log("ProxyAddress: ", mostRecentlyDeployedProxy);
        
        vm.startBroadcast();
        VaultV2 vaultV2 = new VaultV2();
        vm.stopBroadcast();

        address proxy = upgradeVault(mostRecentlyDeployedProxy, address(vaultV2));
        return proxy;
    }

    function upgradeVault(address proxyAddress, address newVault) public returns (address){
        vm.startBroadcast();
        VaultV1 proxy = VaultV1(payable(proxyAddress));
        proxy.upgradeToAndCall(newVault, initData);
        vm.stopBroadcast();
        return address(proxy);
    }
}