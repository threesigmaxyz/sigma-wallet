// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOracleMessageReceiver {
    function handleOracleMessage(string memory message) external;
}
