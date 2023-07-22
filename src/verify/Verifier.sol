// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./Base64.sol";
import "./JsmnSolLib2.sol";
import "./SolRsaVerify.sol";
import "./Strings.sol";

contract Verifier {
    using Base64 for string;
    using StringUtils for *;
    using SolRsaVerify for *;
    using JsmnSolLib2 for string;

    mapping(string => bytes) keys;

    function _verifyToken(
        string memory headerJson,
        string memory payloadJson,
        bytes memory signature,
        string memory subject
    ) internal view {
        string memory headerBase64 = headerJson.encode();
        string memory payloadBase64 = payloadJson.encode();
        StringUtils.slice[] memory slices = new StringUtils.slice[](2);
        slices[0] = headerBase64.toSlice();
        slices[1] = payloadBase64.toSlice();
        string memory message = ".".toSlice().join(slices);
        string memory kid = _parseHeader(headerJson);
        bytes memory exponent = _getRsaExponent(kid);
        bytes memory modulus = _getRsaModulus(kid);
        require(message.pkcs1Sha256VerifyString(signature, exponent, modulus) == 0, "RSA signature check failed");

        (string memory aud, string memory nonce, string memory sub) = _parseToken(payloadJson);
        aud; // silence warning
        nonce; // silence warning

        require(sub.strCompare(subject) == 0, "Subject does not match");

        // Nonce not used for now
        //string memory senderBase64 = "0";
        //require(senderBase64.strCompare(nonce) == 0, "Sender does not match nonce");
    }

    function _parseHeader(string memory json) internal pure returns (string memory kid) {
        (uint256 exitCode, JsmnSolLib2.Token[] memory tokens, uint256 ntokens) = json.parse(20);
        require(exitCode == 0, "JSON parse failed");

        require(tokens[0].jsmnType == JsmnSolLib2.JsmnType.OBJECT, "Expected JWT to be an object");
        uint256 i = 1;
        while (i < ntokens) {
            require(tokens[i].jsmnType == JsmnSolLib2.JsmnType.STRING, "Expected JWT to contain only string keys");
            string memory key = json.getBytes(tokens[i].start, tokens[i].end);
            if (key.strCompare("kid") == 0) {
                require(tokens[i + 1].jsmnType == JsmnSolLib2.JsmnType.STRING, "Expected kid to be a string");
                return json.getBytes(tokens[i + 1].start, tokens[i + 1].end);
            }
            i += 2;
        }
    }

    function _parseToken(string memory json)
        internal
        pure
        returns (string memory aud, string memory nonce, string memory sub)
    {
        (uint256 exitCode, JsmnSolLib2.Token[] memory tokens, uint256 ntokens) = json.parse(40);
        require(exitCode == 0, "JSON parse failed");

        require(tokens[0].jsmnType == JsmnSolLib2.JsmnType.OBJECT, "Expected JWT to be an object");
        uint256 i = 1;
        while (i < ntokens) {
            require(tokens[i].jsmnType == JsmnSolLib2.JsmnType.STRING, "Expected JWT to contain only string keys");
            string memory key = json.getBytes(tokens[i].start, tokens[i].end);
            if (key.strCompare("sub") == 0) {
                require(tokens[i + 1].jsmnType == JsmnSolLib2.JsmnType.STRING, "Expected sub to be a string");
                sub = json.getBytes(tokens[i + 1].start, tokens[i + 1].end);
            } else if (key.strCompare("aud") == 0) {
                require(tokens[i + 1].jsmnType == JsmnSolLib2.JsmnType.STRING, "Expected aud to be a string");
                aud = json.getBytes(tokens[i + 1].start, tokens[i + 1].end);
            } else if (key.strCompare("nonce") == 0) {
                require(tokens[i + 1].jsmnType == JsmnSolLib2.JsmnType.STRING, "Expected nonce to be a string");
                nonce = json.getBytes(tokens[i + 1].start, tokens[i + 1].end);
            }
            i += 2;
        }
    }

    function _getRsaModulus(string memory kid) internal view returns (bytes memory modulus) {
        modulus = keys[kid];
        if (modulus.length == 0) revert("Key not found");
    }

    function _getRsaExponent(string memory) internal pure returns (bytes memory) {
        return
        hex"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010001";
    }

    function _addKey(string memory kid, bytes memory modulus) internal {
        // will require onlyAdmin
        keys[kid] = modulus;
    }
}
