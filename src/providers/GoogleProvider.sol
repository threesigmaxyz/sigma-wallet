// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { IProvider } from "./interfaces/IProvider.sol";
import { JsmnSolLib } from "src/dependencies/JsmnSolLib.sol";
import { Verifier } from "src/verify/Verifier.sol";
//import { Functions, FunctionsClient } from "lib/functions-hardhat-starter-kit/contracts/dev/functions/FunctionsClient.sol";
import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import { FunctionsConsumer } from "lib/functions-hardhat-starter-kit/contracts/FunctionsConsumer.sol";

// Google Provider
contract GoogleProvider is Verifier, IProvider {

    // Internal variables
    string internal constant _name = "Google";

    address internal immutable _functionsConsumer;
    address internal immutable _providerManager;
    uint64 internal immutable _subscriptionId;

    event newKeys(bytes32 indexed requestId, string result, bytes err, uint256 index);
    event DebugEvent();

    modifier onlyProviderManager() {
        if (msg.sender != _providerManager) revert OnlyProviderManager(msg.sender);
        _;
    }

    constructor(address functionsConsumer_, uint64 subscriptionId_){
        _providerManager = msg.sender;
        _functionsConsumer = functionsConsumer_; // 0xC3C14Ea1f95b62e5eeA48897cf14A8Bd06A43448
        _subscriptionId = subscriptionId_; // 566
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

    function requestPublicKeysUpdate() external {
        bytes memory data_ = FunctionsConsumer(_functionsConsumer).latestResponse();
        string memory response_ = string(data_); 
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
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOracle() external view returns (address) {
        return _functionsConsumer;
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
