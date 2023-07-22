// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { IProvider } from "./interfaces/IProvider.sol";
import { IOracle } from "src/providers/oracles/interfaces/IOracle.sol";
import { IOracleMessageReceiver } from "src/providers/oracles/interfaces/IOracleMessageReceiver.sol";
import { JsmnSolLib } from "src/dependencies/JsmnSolLib.sol";
import { Verifier } from "src/verify/Verifier.sol";
import { Functions, FunctionsClient } from "lib/functions-hardhat-starter-kit/contracts/dev/functions/FunctionsClient.sol";
import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

// Google Provider
contract GoogleProvider is FunctionsClient, Verifier, IProvider {
    using Functions for Functions.Request;

    // Internal variables
    string internal constant _name = "Google";
    string internal constant _publicKeysUrl =
        "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com";

    address internal immutable _providerManager;
    address internal immutable _oracle;
    uint64 internal constant _subscriptionId = 3845;

    event newKeys(bytes32 indexed requestId, string result, bytes err, uint256 index);
    event DebugEvent();

    modifier onlyProviderManager() {
        if (msg.sender != _providerManager) revert OnlyProviderManager(msg.sender);
        _;
    }

    constructor(address oracle_) FunctionsClient(oracle_){
        _providerManager = msg.sender;
        _oracle = oracle_;
    }

    function verifyToken(
        string memory headerJson,
        string memory payloadJson,
        bytes memory signature,
        string memory subject
    ) external view override returns (bool) {
        _verifyToken(headerJson, payloadJson, signature, subject);
        return true;
    }

    function requestPublicKeysUpdate(
        string calldata source,
        uint32 gasLimit
    ) external returns (bytes32) {
        Functions.Request memory req;
        req.initializeRequest(Functions.Location.Inline, Functions.CodeLanguage.JavaScript, source);
        bytes32 assignedReqID = sendRequest(req, _subscriptionId, gasLimit);
        return assignedReqID;
    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        string memory response_ = string(response); 
        (, JsmnSolLib.Token[] memory tokens_,) = JsmnSolLib.parse(response_, 10);
        uint256 i_ = 1;
        while (tokens_[i_].jsmnType != JsmnSolLib.JsmnType.UNDEFINED) {
            string memory kuid_ = JsmnSolLib.getBytes(response_, tokens_[i_].start, tokens_[i_].end);
            bytes memory modulus_ = bytes(JsmnSolLib.getBytes(response_, tokens_[i_ + 1].start, tokens_[i_ + 1].end));
            _addKey(kuid_, modulus_);
            unchecked {
                i_ += 2;
            }
        }

        emit newKeys(requestId, response_, err, i_);
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function addKeys(bytes memory publicKeys_) external override {
        //onlyProviderManager
        (string[] memory kuids_, bytes[] memory modulusHashes_) = abi.decode(publicKeys_, (string[], bytes[]));
        for (uint256 i_; i_ < kuids_.length;) {
            _addKey(kuids_[i_], modulusHashes_[i_]);
            unchecked {
                i_ += 1;
            }
        }
    }
}
