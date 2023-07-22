// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { IProvider } from "./interfaces/IProvider.sol";
import { IOracle } from "src/providers/oracles/interfaces/IOracle.sol";
import { IOracleMessageReceiver } from "src/providers/oracles/interfaces/IOracleMessageReceiver.sol";
import { JsmnSolLib } from "src/dependencies/JsmnSolLib.sol";
import { Verifier } from "src/verify/Verifier.sol";

// Google Provider
contract GoogleProvider is Verifier, IProvider, IOracleMessageReceiver {
    // Internal variables
    string internal constant _name = "Google";
    string internal constant _publicKeysUrl =
        "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com";

    address internal immutable _providerManager;
    address internal immutable _oracle;

    modifier onlyProviderManager() {
        if (msg.sender != _providerManager) revert OnlyProviderManager(msg.sender);
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != _oracle) revert OnlyOracle(msg.sender);
        _;
    }

    constructor(address oracle_) {
        _providerManager = msg.sender;
        _oracle = oracle_;
    }

    function verifyToken(string memory headerJson, string memory payloadJson, bytes memory signature, string memory subject) external view override returns (bool) {
        _verifyToken(headerJson, payloadJson, signature, subject);
        // verify token_ is signed by providerPublicKey
        return true;
    }

    function requestPublicKeysUpdate() external override {
        if (_oracle == address(0)) revert NoOracleError();
        IOracle(_oracle).requestData(_publicKeysUrl);
    }

    function handleOracleMessage(string memory response_) external override onlyOracle {
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

    function addKeys(bytes memory publicKeys_) external override { //onlyProviderManager
        (string[] memory kuids_, bytes[] memory modulusHashes_) = abi.decode(publicKeys_, (string[], bytes[]));
        for (uint256 i_; i_ < kuids_.length;) {
            _addKey(kuids_[i_], modulusHashes_[i_]);
            unchecked {
                i_ += 1;
            }
        }
    }
}
