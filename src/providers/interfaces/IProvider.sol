// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IProvider {
    struct PublicKey {
        string kuid;
        bytes32 modulusHash;
    }

    error OnlyProviderManager(address);
    error NoOracleError();
    error OnlyOracle(address);
    error InvalidTokenError(bytes);

    function verifyToken(
        string memory headerJson,
        string memory payloadJson,
        bytes memory signature,
        string memory subject
    ) external view returns (bool);

    function requestPublicKeysUpdate() external;

    function name() external view returns (string memory);

    function addKeys(bytes memory publicKeys_) external;
}
