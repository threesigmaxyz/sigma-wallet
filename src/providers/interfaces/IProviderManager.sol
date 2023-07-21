// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./IProvider.sol";

interface IProviderManager {
    struct Provider {
        string name;
        address providerAddress;
        IProvider.PublicKey[] publicKeys;
    }

}
