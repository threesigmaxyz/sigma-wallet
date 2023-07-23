// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@account-abstraction/contracts/samples/callback/TokenCallbackHandler.sol";

import { IProviderManager } from "./providers/interfaces/IProviderManager.sol";

/**
 * minimal account.
 *  this is sample minimal account.
 *  has execute, eth handling methods
 *  has a single signer that can send requests through the entryPoint.
 */
contract SigmaWallet is BaseAccount, TokenCallbackHandler, UUPSUpgradeable, Initializable {
    using ECDSA for bytes32;

    string public ownerId;
    IProviderManager internal immutable _providerManager;
    uint96 internal _nonce;


    IEntryPoint private immutable _entryPoint;

    event SimpleAccountInitialized(IEntryPoint indexed entryPoint, string indexed ownerId);
    event LogString(string info);

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable { }

    constructor(IEntryPoint anEntryPoint, IProviderManager providerManager_) {
        _entryPoint = anEntryPoint;
        _providerManager = providerManager_;
        _disableInitializers();
    }

    /**
     * execute a transaction (called directly from entryPoint)
     */
    function execute(address dest, uint256 value, bytes calldata func) external {
        _requireFromEntryPoint();
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external {
        _requireFromEntryPoint();
        require(dest.length == func.length, "wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of SimpleAccount must be deployed with the new EntryPoint address, then upgrading
     * the implementation by calling `upgradeTo()`
     */
    function initialize(string memory anOwnerid) public virtual initializer {
        _initialize(anOwnerid);
    }

    function _initialize(string memory anOwnerid) internal virtual {
        ownerId = anOwnerid;
        emit SimpleAccountInitialized(_entryPoint, anOwnerid);
    }

    /// implement template method of BaseAccount
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        virtual
        override
        returns (uint256 validationData)
    {
        _nonce++;
        userOpHash; // silence warning

        emit LogString("Decoding signature");
        (string memory providerName_, string memory headerJson_, string memory payloadJson_, bytes memory signature) =
            abi.decode((userOp.signature), (string, string, string, bytes));
        emit LogString(providerName_);
        emit LogString("Verifying Token");
        _providerManager.verifyToken(providerName_, headerJson_, payloadJson_, signature, ownerId);

        emit LogString("Token verified");
        /*
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        if (owner != hash.recover(userOp.signature)) {
            return SIG_VALIDATION_FAILED;
        }*/
        return 0;
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{ value: value }(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function getNonce() public view virtual override returns (uint256) {
        return _nonce;
    }

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{ value: msg.value }(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public {
        _requireFromEntryPoint();
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal view override {
        (newImplementation);
        _requireFromEntryPoint();
    }

    function _verifyToken(
        string memory headerJson,
        string memory payloadJson,
        bytes memory signature,
        string memory subject
    ) internal view {
        return;
    }
}
