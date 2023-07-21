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

    // Getters

    function getProviders() external view override returns (Provider[] memory providers_) {
        providers_ = new Provider[](_providerList.length);
        for (uint256 i = 0; i < _providerList.length; i++) {
            providers_[i] = Provider(_providerList[i].name(), address(_providerList[i]), _providerList[i].publicKeys());
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
