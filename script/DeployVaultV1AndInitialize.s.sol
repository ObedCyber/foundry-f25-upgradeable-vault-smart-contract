// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {VaultV1} from "../src/VaultV1.sol";
import {TestToken} from "../src/TestToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {console} from "forge-std/console.sol";

contract DeployVaultV1AndInitialize is Script {
    address owner = vm.envAddress("ANVIL_OWNER_ADDRESS");

    function run() external returns (address) {
        
        (address proxy, address vaultV1) = deployVaultV1();
        console.log("Proxy address:", proxy);
        console.log("VaultV1 address:", vaultV1);
        return proxy;
    }

    function deployVaultV1() public returns (address, address) {
        vm.startBroadcast();
        TestToken token = new TestToken(owner);
        VaultV1 vaultv1 = new VaultV1();
        ERC1967Proxy proxy = new ERC1967Proxy(address(vaultv1), "");
        vm.stopBroadcast();
        // initialize
        vaultv1 = VaultV1(address(proxy));
        vaultv1.initialize(address(token), owner);

        return (address(proxy), address(vaultv1));
    }
}
