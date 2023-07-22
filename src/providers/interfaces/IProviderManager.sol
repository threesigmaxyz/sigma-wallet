// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./IProvider.sol";

interface IProviderManager {
    struct Provider {
        string name;
        address providerAddress;
    }

    error OnlyGovernanceError(address);
    error ProviderAlreadyExistsError(string providerName);
    error ProviderDoesNotExistError(string providerName);
    error WrongProviderIndexError(uint256 index);
    error ProviderNotFoundError(string providerName);

    function verifyToken(string memory providerName_, string memory headerJson, string memory payloadJson, bytes memory signature, string memory subject) external view returns (bool);
    function updateProviderPublicKeys(string memory providerName_) external;
    function addProvider(bytes memory providerBytecode_) external;
    function updateProvider(bytes memory providerBytecode_, uint256 providerIndex_) external;
    function getProviders() external view returns (Provider[] memory providers_);
    function forceUpdateProviderPublicKeys(string memory providerName_, bytes memory publicKeys_) external;
}
