// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "@forge-std/Script.sol";

import { GoogleProvider } from "src/providers/GoogleProvider.sol";
import { ProviderManager } from "src/providers/ProviderManager.sol";


/// @dev See the "Solidity Scripting" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/tutorials/solidity-scripting?highlight=scripts#solidity-scripting
contract Deploy is Script {

    address chainlinkOracle = 0x649a2C205BE7A3d5e99206CEEFF30c794f0E31EC;

    function setUp() public {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @dev You can send multiple transactions inside a single script.
    function run() public {
        vm.startBroadcast();

        ProviderManager providerManager = new ProviderManager();
        GoogleProvider google = new GoogleProvider(chainlinkOracle);
        providerManager.addProviderSimple(google, "Google");

        vm.stopBroadcast();
    }
}
