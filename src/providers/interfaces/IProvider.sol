// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IProvider {
    struct PublicKey {
        string kuid;
        bytes32 modulusHash;
    }

    function name() external view returns (string memory);

    function publicKeys() external view returns (PublicKey[] memory);
}
