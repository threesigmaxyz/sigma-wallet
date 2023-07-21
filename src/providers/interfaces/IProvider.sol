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


    function verifyToken(bytes memory token_) external view returns (bool);

    function requestPublicKeysUpdate() external;

    function name() external view returns (string memory);

    function publicKeys() external view returns (PublicKey[] memory);

    function forceUpdatePublicKeys(bytes memory publicKeys_) external;

}

