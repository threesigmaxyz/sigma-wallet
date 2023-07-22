// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./interfaces/IProvider.sol";
import "./interfaces/IProviderManager.sol";

contract ProviderManager is IProviderManager {
    mapping(string => IProvider) internal _providers;
    IProvider[] internal _providerList; // data fetching purposes
    address internal _governance;

    modifier onlyGovernance() {
        if (msg.sender != _governance) revert OnlyGovernanceError(msg.sender);
        _;
    }

    constructor() {
        _governance = msg.sender;
    }

    function verifyToken(string memory providerName_, string memory headerJson, string memory payloadJson, bytes memory signature, string memory subject) external view override returns (bool) {
        IProvider provider_ = _providers[providerName_];
        if (address(provider_) == address(0)) revert ProviderNotFoundError(providerName_);
        return provider_.verifyToken(headerJson, payloadJson, signature, subject);
    }

    function updateProviderPublicKeys(string memory providerName_) external override {
        _providers[providerName_].requestPublicKeysUpdate();
    }

    // Governance functions

    function addProvider(bytes memory providerBytecode_) external override onlyGovernance {
        (IProvider provider_, string memory name_) = _addProvider(providerBytecode_);
        if (address(_providers[name_]) != address(0)) revert ProviderAlreadyExistsError(name_);

        _providers[name_] = provider_;
        _providerList.push(provider_);
    }

    function updateProvider(bytes memory providerBytecode_, uint256 providerIndex_) external override onlyGovernance {
        (IProvider provider_, string memory providerName_) = _addProvider(providerBytecode_);

        if (address(_providers[providerName_]) == address(0)) revert ProviderDoesNotExistError(providerName_);
        _providers[providerName_] = provider_;

        if (keccak256(bytes(_providerList[providerIndex_].name())) != keccak256(bytes(providerName_))) {
            revert WrongProviderIndexError(providerIndex_);
        }
        _providerList[providerIndex_] = provider_;
    }



    function forceUpdateProviderPublicKeys(string memory name_, bytes memory keys_) external override onlyGovernance {
        _providers[name_].addKeys(keys_);
    }
    
    // Getters

    function getProviders() external view override returns (Provider[] memory providers_) {
        providers_ = new Provider[](_providerList.length);
        for (uint256 i = 0; i < _providerList.length; i++) {
            providers_[i] = Provider(_providerList[i].name(), address(_providerList[i]));
        }
        return providers_;
    }

    // internal functions

    function _addProvider(bytes memory bytecode_) internal returns (IProvider, string memory) {
        address address_;
        assembly {
            address_ := create(0, add(bytecode_, 0x20), mload(bytecode_))
            if iszero(extcodesize(address_)) { revert(0, 0) }
        }
        return (IProvider(address_), IProvider(address_).name());
    }
}
