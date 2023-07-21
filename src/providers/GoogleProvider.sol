// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { IProvider } from "./interfaces/IProvider.sol";
// Google Provider
abstract contract GoogleProvider is IProvider {
    
    string internal constant _name = "Google";

}