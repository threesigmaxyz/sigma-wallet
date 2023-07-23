// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;


contract FunctionsConsumerMock {
    bytes public latestResponse = hex"5b2262326466663738613062646435613032323132303633343939643737656634646565643166363562222c2231346562386133623638333766363135386565623630373665366138633432386135663632613762225d";

    function executeRequest(
        string calldata source,
        bytes calldata secrets,
        string[] calldata args,
        uint64 subscriptionId,
        uint32 gasLimit
    ) public returns (bytes32) {
        source;
        secrets;
        args;
        subscriptionId;
        gasLimit;
        return bytes32(uint256(0));
    }

}