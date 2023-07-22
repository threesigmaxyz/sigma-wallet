// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "@forge-std/Test.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { UserOperationLib, UserOperation } from "@account-abstraction/contracts/interfaces/UserOperation.sol";

import { SigmaWallet } from "src/SigmaWallet.sol";
import { SigmaWalletFactory } from "src/SigmaWalletFactory.sol";

import { IProvider } from "src/providers/interfaces/IProvider.sol";
import { IProviderManager } from "src/providers/interfaces/IProviderManager.sol";
import { GoogleProvider } from "src/providers/GoogleProvider.sol";
import { ProviderManager } from "src/providers/ProviderManager.sol";

// https://github.com/dawnwallet/erc4337-wallet/blob/master/test/fork/e2eDeployAndPaymaster.t.sol
contract EndToEnd is Test {
    IEntryPoint public constant ENTRY_POINT = IEntryPoint(0x0576a174D229E3cFA37253523E645A78A0C91B57);
    SigmaWalletFactory public factory;

    address public alice;
    uint256 public constant ALICE_PK = 20;

    address public governor;

    SigmaWallet public aliceWallet;

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

        // Set up provider
        google = new GoogleProvider(address(0x0)); // TODO: send oracle in constructor
        // Set up provider keys
        string[] memory kids = new string[](2);
        bytes[] memory modulus = new bytes[](2);
        kids[0] = "3db3ed6b9574ee3fcd9f149e59ff0eef4f932153";
        kids[1] = "8a63fe71e53067524cbbc6a3a58463b3864c0787";
        modulus[0] =
            "0xd8a729bf80b14e8782284217ce786a3e0db53210803fd0e75f9b36fd4759d5bcce56147caa2a24fcff23ef2f1817633625cf2bd9bb5f0a02461658db92db557385ef9de3de3d3fa119ff4f7a423545487bca4e8f786d240899e6716620617c572fc3f44c33479379964f80e5c8dd8209c968c067d154b25b7b5a82d4d0764573f2723d117c3369229e4758c67cc0f8c8f309eb5796a9a102bfb02cf83f40b2b0002c91205d8524781f3ecbea69e17b257a34cc73dc1ae1d43aa5c21e89fa2a21d917b382e1bcd3b93133562a494cb632f505322f83362fc6d0bb5212512697863fa2d564f4443270aa98a8385a6b545aaa915bdb516d275c3ff1d540389ef7fb";
        modulus[1] =
            "0xc9b3cb7ce8a86e462a3c97f64bdf1390fd1876fcf24aa3d200d6b5470f1012d4f6231ab67eed4314e9fdf2b7b5aa3627e4740f956e87be7fffc3d26694677e98a83f5c9bef11af354e6fad3fdb53ae07e5022ce36d31df5fdfa7f4d16529aff56e52781ca627d6f9219b08423e6bb25de6fbb07641227bef8e5e25695077555c2282a82b799045eb96a874c715908ab307ee95cbf58a791a8047eb0d7097fcb1d48dbce4b03cf43f830dcc437f1289e9b155591f9e7e805a2721b8423ded2dbae08bb380d245e538a9a533e3ce326ffaac62b110ea326bda7a48b53c27bc098f4429027105664ecba5a56ddcb5826cce78bb171152f922c1722c65fa4ead7699";
        bytes memory publicKeys_ = abi.encode(kids, modulus);
        google.addKeys(publicKeys_);

        vm.prank(governor);
        providerManager.addProviderSimple(google, "Google");

        alice = vm.addr(ALICE_PK);
        vm.label(alice, "alice");

        bundler = makeAddr("bundler");
        deal(bundler, 1 ether);

        factory = new SigmaWalletFactory(ENTRY_POINT, providerManager);

        aliceWallet = SigmaWallet(payable(factory.getAddress("aliceGoogleId", 0)));

        vm.label(0x0576a174D229E3cFA37253523E645A78A0C91B57, "EntryPoint");
    }

    function test_SendUserOperation_DeployWallet() public {
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
        string memory headerJson_ = '{"alg":"RS256","kid": "3db3ed6b9574ee3fcd9f149e59ff0eef4f932153", "typ":"JWT"}';
        string memory payloadJson_ =
            '{"sub":"aliceGoogleId","name":"John Doe","iat":1516239022,"nonce":"xf30B2uPOlNXxeOVq5cLW1QJj-8","aud":"theaudience.zeppelin.solutions"}';
        bytes memory signature = "0x123456789abcd";
        bytes memory data = abi.encode(providerName_, headerJson_, payloadJson_, signature);
        emit LogBytes(signature);
        _assertCorrectDecoding(providerName_, headerJson_, payloadJson_, signature, data);
        userOperations_[0].signature = data; //_createSignature(abi.encode(providerName_, jwtToken_), ALICE_PK);

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
        bytes memory signature_,
        bytes memory data_
    ) internal {
        (
            string memory decodedName_,
            string memory decodedHeader_,
            string memory decodedPayload_,
            bytes memory decodedSignature_
        ) = abi.decode((data_), (string, string, string, bytes));
        assertEq(providerName_, decodedName_);
        assertEq(headerJson_, decodedHeader_);
        assertEq(payloadJson_, decodedPayload_);
        assertEq(signature_, decodedSignature_);

        emit LogString("Decoded asserted");
    }
}
