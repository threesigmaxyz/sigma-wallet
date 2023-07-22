// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// This contract is only for tests, real oracle is already deployed by chainlink
contract ChainlinkOracle {
    constructor() { }

    function sendRequest(uint64 subscriptionId, bytes calldata data, uint32 gasLimit) external pure returns (bytes32){
        subscriptionId; // Silence warning
        data;
        gasLimit;
        return bytes32(uint256(100));
    }

    function getRegistry() external view returns (address){
        return address(this);
    }
}
