// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "@forge-std/Script.sol";

import { SigmaWallet } from "src/SigmaWallet.sol";
import { SigmaWalletFactory } from "src/SigmaWalletFactory.sol";

import { GoogleProvider } from "src/providers/GoogleProvider.sol";
import { ProviderManager } from "src/providers/ProviderManager.sol";

import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { UserOperationLib, UserOperation } from "@account-abstraction/contracts/interfaces/UserOperation.sol";



/// @dev See the "Solidity Scripting" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/tutorials/solidity-scripting?highlight=scripts#solidity-scripting
contract makeTransaction is Script {

    IEntryPoint public constant ENTRY_POINT = IEntryPoint(0x0576a174D229E3cFA37253523E645A78A0C91B57);
    address google = 0x9eAF93320EDd1De220D6C1744D4a9D0774A1F1Af;
    address providerManager = 0xFbd727f162ceF00F45C14b205562D7c43c590292;
    address ourAddr = 0xff07F25C4753BE90D919A908F54Eb64adA79DD3d;

    function setUp() public {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @dev You can send multiple transactions inside a single script.
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        GoogleProvider(google).requestPublicKeysUpdate();

        SigmaWalletFactory factory = new SigmaWalletFactory(ENTRY_POINT, ProviderManager(providerManager));
        SigmaWallet aliceWallet = SigmaWallet(payable(factory.getAddress("aliceGoogleId", 0)));

        UserOperation[] memory userOperations_ = new UserOperation[](1);

        userOperations_[0].sender = address(aliceWallet);
        userOperations_[0].nonce = 0;
        userOperations_[0].initCode =
            abi.encodePacked(address(factory), abi.encodeCall(factory.createAccount, ("aliceGoogleId", 0)));
        userOperations_[0].callData;
        userOperations_[0].callGasLimit = 10e6;
        userOperations_[0].verificationGasLimit = 10e6;
        userOperations_[0].preVerificationGas = 0;
        userOperations_[0].maxFeePerGas = 20e9;
        userOperations_[0].maxPriorityFeePerGas = 2e9;
        userOperations_[0].paymasterAndData;

        string memory providerName_ = "Google";
        string memory headerJson_ = '{"alg":"RS256","kid": "b2dff78a0bdd5a02212063499d77ef4deed1f65b", "typ":"JWT"}';
        string memory payloadJson_ =
            '{"sub":"aliceGoogleId","name":"John Doe","iat":1516239022,"nonce":"xf30B2uPOlNXxeOVq5cLW1QJj-8","aud":"theaudience.zeppelin.solutions"}';
        bytes memory signature = "0x123456789abcd";
        bytes memory data = abi.encode(providerName_, headerJson_, payloadJson_, signature);
        userOperations_[0].signature = data; //_createSignature(abi.encode(providerName_, jwtToken_), ALICE_PK);
        ENTRY_POINT.handleOps(userOperations_, payable(ourAddr));

        vm.stopBroadcast();
    }
}
