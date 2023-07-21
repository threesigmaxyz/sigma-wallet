// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { IProvider } from "./interfaces/IProvider.sol";
import { IOracle } from "src/providers/oracles/interfaces/IOracle.sol";
import { IOracleMessageReceiver } from "src/providers/oracles/interfaces/IOracleMessageReceiver.sol";
import { JsmnSolLib } from "src/dependencies/JsmnSolLib.sol";

// Google Provider
contract GoogleProvider is IProvider, IOracleMessageReceiver {
    // Internal variables
    string internal constant _name = "Google";
    string internal constant _publicKeysUrl =
        "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com";

    string[] internal _kuids;
    mapping(string => bytes32) internal _kuidToModulusHash;

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

    function verifyToken(bytes memory token_) external view override returns (bool) {
        // verify token_ is signed by providerPublicKey
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
            string memory modulus_ = JsmnSolLib.getBytes(response_, tokens_[i_ + 1].start, tokens_[i_ + 1].end);
            _kuidToModulusHash[kuid_] = keccak256(bytes(modulus_));
            _kuids.push(kuid_);
            unchecked {
                i_ += 2;
            }
        }
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function publicKeys() external view override returns (PublicKey[] memory publicKeys_) {
        publicKeys_ = new PublicKey[](_kuids.length);
        for (uint256 i_; i_ < publicKeys_.length;) {
            publicKeys_[i_] = PublicKey(_kuids[i_], _kuidToModulusHash[_kuids[i_]]);
            unchecked {
                i_ += 1;
            }
        }
    }

    function forceUpdatePublicKeys(bytes memory publicKeys_) external override onlyProviderManager {
        (string[] memory kuids_, bytes32[] memory modulusHashes_) = abi.decode(publicKeys_, (string[], bytes32[]));
        for (uint256 i_; i_ < kuids_.length;) {
            _kuidToModulusHash[kuids_[i_]] = modulusHashes_[i_];
            _kuids.push(kuids_[i_]);
            unchecked {
                i_ += 1;
            }
        }
    }
}
