// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "@forge-std/Script.sol";

import { GoogleProvider } from "src/providers/GoogleProvider.sol";
import { ProviderManager } from "src/providers/ProviderManager.sol";
import { FunctionsConsumer } from "lib/functions-hardhat-starter-kit/contracts/FunctionsConsumer.sol";

import { SigmaWallet } from "src/SigmaWallet.sol";
import { SigmaWalletFactory } from "src/SigmaWalletFactory.sol";

import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { UserOperationLib, UserOperation } from "@account-abstraction/contracts/interfaces/UserOperation.sol";


/// @dev See the "Solidity Scripting" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/tutorials/solidity-scripting?highlight=scripts#solidity-scripting
contract Global is Script {

    address functionsConsumer = 0xC3C14Ea1f95b62e5eeA48897cf14A8Bd06A43448;
    uint64 subscriptionId = 566;
    address ourAddr = 0xff07F25C4753BE90D919A908F54Eb64adA79DD3d;
    IEntryPoint public constant ENTRY_POINT = IEntryPoint(0x0576a174D229E3cFA37253523E645A78A0C91B57);

    function setUp() public {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @dev You can send multiple transactions inside a single script.
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        ProviderManager providerManager = new ProviderManager();
        GoogleProvider google = new GoogleProvider(functionsConsumer, subscriptionId);
        providerManager.addProviderSimple(google, "Google");

        // Already done before
        /*bytes memory encodedCode = hex"636f6e7374204150495f454e44504f494e54203d202768747470733a2f2f7777772e676f6f676c65617069732e636f6d2f726f626f742f76312f6d657461646174612f783530392f736563757265746f6b656e4073797374656d2e67736572766963656163636f756e742e636f6d270a636f6e73742072657175657374506172616d73203d207b0a75726c3a2060247b4150495f454e44504f494e547d600a7d0a636f6e737420676f6f676c6552657175657374203d2046756e6374696f6e732e6d616b6548747470526571756573742872657175657374506172616d73290a6c657420726573706f6e73650a747279207b0a726573706f6e7365203d20617761697420676f6f676c65526571756573740a7d20636174636820286572726f7229207b0a7468726f77206e6577204572726f722860476f6f676c65204150492072657175657374206661696c65643a20247b6572726f722e6d6573736167657d60290a7d0a69662028726573706f6e73652e73746174757320213d3d2032303029207b0a7468726f77206e6577204572726f722860476f6f676c65204150492072657475726e656420616e206572726f723a20247b726573706f6e73652e737461747573546578747d60290a7d0a636f6e73742064617461203d20726573706f6e73652e646174610a636f6e7374206b657973203d204f626a6563742e6b657973286461746129200a636f6e7374206a736f6e203d204a534f4e2e737472696e67696679286b657973290a72657475726e2046756e6374696f6e732e656e636f6465537472696e672860247b6a736f6e7d6029";
        string memory code = string(encodedCode);
        string[] memory args = new string[](0);
        bytes32 requestId = FunctionsConsumer(functionsConsumer).executeRequest(code, bytes(""), args, subscriptionId, 0);*/

        google.requestPublicKeysUpdate();

        SigmaWalletFactory factory = new SigmaWalletFactory(ENTRY_POINT, ProviderManager(providerManager));
        SigmaWallet carolinaWallet = SigmaWallet(payable(factory.getAddress("NJMGKrEHfJWA1YaOuS8wi5fbJ6W2", 0)));
        payable(address(carolinaWallet)).transfer(0.5 ether);

        UserOperation[] memory userOperations_ = new UserOperation[](1);

        userOperations_[0].sender = address(carolinaWallet);
        userOperations_[0].nonce = 0;
        userOperations_[0].initCode =
            abi.encodePacked(address(factory), abi.encodeCall(factory.createAccount, ("NJMGKrEHfJWA1YaOuS8wi5fbJ6W2", 0)));
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
            '{"sub":"NJMGKrEHfJWA1YaOuS8wi5fbJ6W2","name":"John Doe","iat":1516239022,"nonce":"xf30B2uPOlNXxeOVq5cLW1QJj-8","aud":"theaudience.zeppelin.solutions"}';
        bytes memory signature = "0x123456789abcd";
        bytes memory data = abi.encode(providerName_, headerJson_, payloadJson_, signature);
        userOperations_[0].signature = data; //_createSignature(abi.encode(providerName_, jwtToken_), ALICE_PK);
        ENTRY_POINT.handleOps(userOperations_, payable(ourAddr));


        vm.stopBroadcast();
    }
}
