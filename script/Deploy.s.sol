// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "@forge-std/Script.sol";

import { GoogleProvider } from "src/providers/GoogleProvider.sol";
import { ProviderManager } from "src/providers/ProviderManager.sol";


/// @dev See the "Solidity Scripting" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/tutorials/solidity-scripting?highlight=scripts#solidity-scripting
contract Deploy is Script {

    address functionsConsumer = 0xC3C14Ea1f95b62e5eeA48897cf14A8Bd06A43448;
    uint64 subscriptionId = 566;

    function setUp() public {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @dev You can send multiple transactions inside a single script.
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        ProviderManager providerManager = new ProviderManager();
        GoogleProvider google = new GoogleProvider(functionsConsumer, subscriptionId);
        providerManager.addProviderSimple(google, "Google");

        vm.stopBroadcast();
    }
}
