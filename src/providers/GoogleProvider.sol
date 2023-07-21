// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { IProvider } from "./interfaces/IProvider.sol";
// Google Provider

contract GoogleProvider is IProvider {
    // Internal variables
    string internal constant _name = "Google";
    string[] internal _kuids;
    mapping(string => bytes32) internal _kuidToModulusHash;

    address internal immutable _providerManager;

    modifier onlyProviderManager() {
        if (msg.sender != _providerManager) revert OnlyProviderManager(msg.sender);
        _;
    }

    constructor() {
        _providerManager = msg.sender;
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
}
