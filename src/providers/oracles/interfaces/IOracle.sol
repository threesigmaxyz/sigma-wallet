// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOracle {
    function requestData(string memory url_) external returns (bytes32 requestId);
}
