// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "@forge-std/Test.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { UserOperationLib, UserOperation } from "@account-abstraction/contracts/interfaces/UserOperation.sol";

import { SigmaWallet } from "src/SigmaWallet.sol";
import { SigmaWalletFactory } from "src/SigmaWalletFactory.sol";

import { GoogleProvider } from "src/providers/GoogleProvider.sol";
import { IProviderManager } from "src/providers/interfaces/IProviderManager.sol";
import { GoogleProvider } from "src/providers/GoogleProvider.sol";
import { ProviderManager } from "src/providers/ProviderManager.sol";
import { ChainlinkOracle } from "src/providers/oracles/ChainlinkOracle.sol";

// https://github.com/dawnwallet/erc4337-wallet/blob/master/test/fork/e2eDeployAndPaymaster.t.sol
contract Chainlink is Test {
    IEntryPoint public constant ENTRY_POINT = IEntryPoint(0x0576a174D229E3cFA37253523E645A78A0C91B57);
    SigmaWalletFactory public factory;

    // Can paste multiple line code to solidty
    string code = "const API_ENDPOINT = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'...";

    address public alice;
    uint256 public constant ALICE_PK = 20;

    address public governor;

    SigmaWallet public aliceWallet;

    GoogleProvider public google;
    IProviderManager public providerManager;

    address public bundler;
    address public oracle;

    event LogBytes(bytes info);
    event LogBytes32(bytes32 info);
    event LogString(string info);

    function setUp() external {
        vm.createSelectFork(vm.envString("RPC_URL_SEPOLIA"));

        vm.prank(governor);
        oracle = address(new ChainlinkOracle());

        vm.prank(governor);
        providerManager = new ProviderManager();

        // Set up provider and keys
        google = new GoogleProvider(oracle);
        bytes32 requestId = google.requestPublicKeysUpdate(code, 100000);
        bytes memory response = hex"5b2262326466663738613062646435613032323132303633343939643737656634646565643166363562222c2231346562386133623638333766363135386565623630373665366138633432386135663632613762225d";
        bytes memory err = "";
        vm.prank(oracle);
        google.handleOracleFulfillment(requestId, response, err);

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
