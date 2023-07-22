// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@forge-std/Test.sol";
import "../src/verify/Verifier.sol";
import "../src/providers/GoogleProvider.sol";

contract VerificationTest is Test {
    GoogleProvider public googleProvider;

    address oracle = address(1);

    function setUp() public {
        // Set up Provider
        googleProvider = new GoogleProvider(oracle);

        // Set up keys
        string[] memory kids = new string[](2);
        bytes[] memory modulus = new bytes[](2);
        kids[0] = "3db3ed6b9574ee3fcd9f149e59ff0eef4f932153";
        kids[1] = "8a63fe71e53067524cbbc6a3a58463b3864c0787";
        modulus[0] =
            "0xd8a729bf80b14e8782284217ce786a3e0db53210803fd0e75f9b36fd4759d5bcce56147caa2a24fcff23ef2f1817633625cf2bd9bb5f0a02461658db92db557385ef9de3de3d3fa119ff4f7a423545487bca4e8f786d240899e6716620617c572fc3f44c33479379964f80e5c8dd8209c968c067d154b25b7b5a82d4d0764573f2723d117c3369229e4758c67cc0f8c8f309eb5796a9a102bfb02cf83f40b2b0002c91205d8524781f3ecbea69e17b257a34cc73dc1ae1d43aa5c21e89fa2a21d917b382e1bcd3b93133562a494cb632f505322f83362fc6d0bb5212512697863fa2d564f4443270aa98a8385a6b545aaa915bdb516d275c3ff1d540389ef7fb";
        modulus[1] =
            "0xc9b3cb7ce8a86e462a3c97f64bdf1390fd1876fcf24aa3d200d6b5470f1012d4f6231ab67eed4314e9fdf2b7b5aa3627e4740f956e87be7fffc3d26694677e98a83f5c9bef11af354e6fad3fdb53ae07e5022ce36d31df5fdfa7f4d16529aff56e52781ca627d6f9219b08423e6bb25de6fbb07641227bef8e5e25695077555c2282a82b799045eb96a874c715908ab307ee95cbf58a791a8047eb0d7097fcb1d48dbce4b03cf43f830dcc437f1289e9b155591f9e7e805a2721b8423ded2dbae08bb380d245e538a9a533e3ce326ffaac62b110ea326bda7a48b53c27bc098f4429027105664ecba5a56ddcb5826cce78bb171152f922c1722c65fa4ead7699";
        bytes memory publicKeys_ = abi.encode(kids, modulus);
        googleProvider.addKeys(publicKeys_);
    }

    function testDecript() public view {
        string memory header = '{"alg":"RS256","kid": "3db3ed6b9574ee3fcd9f149e59ff0eef4f932153", "typ":"JWT"}';
        string memory payload =
            '{"sub":"1234567890","name":"John Doe","iat":1516239022,"nonce":"xf30B2uPOlNXxeOVq5cLW1QJj-8","aud":"theaudience.zeppelin.solutions"}';
        bytes memory signature = "0x123456789abcd";
        string memory subject = "1234567890";

        googleProvider.verifyToken(header, payload, signature, subject);
        //identity.recover(header, payload, signature);
    }

    function testDebug() public {
        /*string memory header = '{"alg":"RS256","kid": "123", "typ":"JWT"}';
        string memory payload = '{"sub":"1234567890","name":"John Doe","iat":1516239022,"nonce":"0","aud":"theaudience.zeppelin.solutions"}';
        bytes memory signature = '0x123456789abcd';
        bytes memory modulus = "4564444444444444444444444444444444444444444444444444444444444444444444444444444444444444444";

       bytes memory exponent = hex"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010001";

       solRsaVerify.pkcs1Sha256VerifyStr(payload, signature, exponent, modulus);*/
    }
}
