// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "@forge-std/Test.sol";

import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { UserOperationLib, UserOperation } from "@account-abstraction/contracts/interfaces/UserOperation.sol";

import { SigmaWallet } from "src/SigmaWallet.sol";
import { SigmaWalletFactory } from "src/SigmaWalletFactory.sol";

import { IProviderManager } from "src/providers/interfaces/IProviderManager.sol";
import { GoogleProvider } from "src/providers/GoogleProvider.sol";
import { ProviderManager } from "src/providers/ProviderManager.sol";
import { ChainlinkOracle } from "src/providers/oracles/ChainlinkOracle.sol";

import { FunctionsConsumerMock } from "./ConsumerMock.sol";


// https://github.com/dawnwallet/erc4337-wallet/blob/master/test/fork/e2eDeployAndPaymaster.t.sol
contract Chainlink is Test {
    IEntryPoint public constant ENTRY_POINT = IEntryPoint(0x0576a174D229E3cFA37253523E645A78A0C91B57);
    SigmaWalletFactory public factory;

    // Can paste multiple line code to solidty
    bytes private encodedCode = hex"636f6e7374204150495f454e44504f494e54203d202768747470733a2f2f7777772e676f6f676c65617069732e636f6d2f726f626f742f76312f6d657461646174612f783530392f736563757265746f6b656e4073797374656d2e67736572766963656163636f756e742e636f6d270a636f6e73742072657175657374506172616d73203d207b0a75726c3a2060247b4150495f454e44504f494e547d600a7d0a636f6e737420676f6f676c6552657175657374203d2046756e6374696f6e732e6d616b6548747470526571756573742872657175657374506172616d73290a6c657420726573706f6e73650a747279207b0a726573706f6e7365203d20617761697420676f6f676c65526571756573740a7d20636174636820286572726f7229207b0a7468726f77206e6577204572726f722860476f6f676c65204150492072657175657374206661696c65643a20247b6572726f722e6d6573736167657d60290a7d0a69662028726573706f6e73652e73746174757320213d3d2032303029207b0a7468726f77206e6577204572726f722860476f6f676c65204150492072657475726e656420616e206572726f723a20247b726573706f6e73652e737461747573546578747d60290a7d0a636f6e73742064617461203d20726573706f6e73652e646174610a636f6e7374206b657973203d204f626a6563742e6b657973286461746129200a636f6e7374206a736f6e203d204a534f4e2e737472696e67696679286b657973290a72657475726e2046756e6374696f6e732e656e636f6465537472696e672860247b6a736f6e7d6029";

    address public alice;
    uint256 public constant ALICE_PK = 20;

    address public governor;

    SigmaWallet public aliceWallet;

    GoogleProvider public google;
    IProviderManager public providerManager;

    address public bundler;
    address public functionsConsumer;

    event LogBytes(bytes info);
    event LogBytes32(bytes32 info);
    event LogString(string info);

    function setUp() external {
        vm.createSelectFork(vm.envString("RPC_URL_SEPOLIA"));

        vm.prank(governor);
        providerManager = new ProviderManager();

        vm.prank(governor);
        functionsConsumer = address(new FunctionsConsumerMock());

        // Set up provider
        google = new GoogleProvider(functionsConsumer, uint64(566));
        vm.prank(governor);
        providerManager.addProviderSimple(google, "Google");

        // Set up keys
        google.requestPublicKeysUpdate();

        alice = vm.addr(ALICE_PK);
        vm.label(alice, "alice");

        bundler = makeAddr("bundler");
        deal(bundler, 1 ether);

        factory = new SigmaWalletFactory(ENTRY_POINT, providerManager);

        aliceWallet = SigmaWallet(payable(factory.getAddress("aliceGoogleId", 0)));

        vm.label(0x0576a174D229E3cFA37253523E645A78A0C91B57, "EntryPoint");
    }

    function test_Chainlink() public {
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

        //bytes32 userOpHash_ = ENTRY_POINT.getUserOpHash(userOperations_[0]);
        string memory providerName_ = "Google";
        string memory headerJson_ = '{"alg":"RS256","kid": "b2dff78a0bdd5a02212063499d77ef4deed1f65b", "typ":"JWT"}';
        string memory payloadJson_ =
            '{"sub":"aliceGoogleId","name":"John Doe","iat":1516239022,"nonce":"xf30B2uPOlNXxeOVq5cLW1QJj-8","aud":"theaudience.zeppelin.solutions"}';
        bytes memory signature = "0x123456789abcd";
        bytes memory data = abi.encode(providerName_, headerJson_, payloadJson_, signature);
        emit LogBytes(signature);
        userOperations_[0].signature = data; //_createSignature(abi.encode(providerName_, jwtToken_), ALICE_PK);

        deal(address(aliceWallet), 1 ether);

        vm.prank(bundler);
        ENTRY_POINT.handleOps(userOperations_, payable(bundler));
    }
}
