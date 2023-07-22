// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "@forge-std/Test.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { UserOperationLib, UserOperation } from "@account-abstraction/contracts/interfaces/UserOperation.sol";

import { SuperAccount } from "src/SuperAccount.sol";
import { SuperAccountFactory } from "src/SuperAccountFactory.sol";

import { IProvider } from "src/providers/interfaces/IProvider.sol";
import { IProviderManager } from "src/providers/interfaces/IProviderManager.sol";
import { GoogleProvider } from "src/providers/GoogleProvider.sol";
import { ProviderManager } from "src/providers/ProviderManager.sol";

// https://github.com/dawnwallet/erc4337-wallet/blob/master/test/fork/e2eDeployAndPaymaster.t.sol
contract EndToEnd is Test {
    IEntryPoint public constant ENTRY_POINT = IEntryPoint(0x0576a174D229E3cFA37253523E645A78A0C91B57);
    SuperAccountFactory public factory;

    address public alice;
    uint256 public constant ALICE_PK = 20;

    address public governor;

    SuperAccount public aliceWallet;

    IProvider public google;
    IProviderManager public providerManager;

    address public bundler;

    event LogBytes(bytes info);
    event LogBytes32(bytes32 info);
    event LogString(string info);

    function setUp() external {
        vm.createSelectFork(vm.envString("RPC_URL_SEPOLIA"));

        vm.prank(governor);
        providerManager = new ProviderManager();

        google = new GoogleProvider(address(0x0)); // TODO: send oracle in constructor

        vm.prank(governor);
        providerManager.addProviderSimple(google, "Google");

        alice = vm.addr(ALICE_PK);
        vm.label(alice, "alice");

        bundler = makeAddr("bundler");
        deal(bundler, 1 ether);

        factory = new SuperAccountFactory(ENTRY_POINT, providerManager);

        aliceWallet = SuperAccount(payable(factory.getAddress(alice, 0)));

        vm.label(0x0576a174D229E3cFA37253523E645A78A0C91B57, "EntryPoint");
    }

    function test_SendUserOperation_DeployWallet() public {
        UserOperation[] memory userOperations_ = new UserOperation[](1);

        userOperations_[0].sender = address(aliceWallet);
        userOperations_[0].nonce = 0;
        userOperations_[0].initCode =
            abi.encodePacked(address(factory), abi.encodeCall(factory.createAccount, (alice, 0)));
        userOperations_[0].callData;
        userOperations_[0].callGasLimit = 10e6;
        userOperations_[0].verificationGasLimit = 10e6;
        userOperations_[0].preVerificationGas = 0;
        userOperations_[0].maxFeePerGas = 20e9;
        userOperations_[0].maxPriorityFeePerGas = 2e9;
        userOperations_[0].paymasterAndData;

        //bytes32 userOpHash_ = ENTRY_POINT.getUserOpHash(userOperations_[0]);
        string memory providerName_ = "Google";
        string memory headerJson_ = "this is the header";
        string memory payloadJson_ = "this is the payload";
        string memory subject_ = "this is the subject";
        bytes memory signature_ = abi.encode(providerName_, headerJson_, payloadJson_, subject_);
        emit LogBytes(signature_);
        _assertCorrectDecoding(providerName_, headerJson_, payloadJson_, subject_, signature_);
        userOperations_[0].signature = signature_; //_createSignature(abi.encode(providerName_, jwtToken_), ALICE_PK);

        deal(address(aliceWallet), 1 ether);

        vm.prank(bundler);
        ENTRY_POINT.handleOps(userOperations_, payable(bundler));
    }

    function hash(UserOperation calldata userOperation_) public pure returns (bytes32) {
        return UserOperationLib.hash(userOperation_);
    }

    function _createSignature(
        bytes memory messageHash, // in form of ECDSA.toEthSignedMessageHash
        uint256 ownerPrivateKey
    ) internal pure returns (bytes memory) {
        /*
        bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        bytes memory signature = bytes.concat(r, s, bytes1(v));
        return signature;*/
    }

    function _assertCorrectDecoding(
        string memory providerName_,
        string memory headerJson_,
        string memory payloadJson_,
        string memory subject_,
        bytes memory signature_
    ) internal {
        (
            string memory decodedName_,
            string memory decodedHeader_,
            string memory decodedPayload_,
            string memory decodedSubject_
        ) = abi.decode((signature_), (string, string, string, string));
        assertEq(providerName_, decodedName_);
        assertEq(headerJson_, decodedHeader_);
        assertEq(payloadJson_, decodedPayload_);
        assertEq(subject_, decodedSubject_);

        emit LogString("Decoded asserted");
    }
}
