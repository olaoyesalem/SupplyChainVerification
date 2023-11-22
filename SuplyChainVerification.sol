// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IProofOfIdentity.sol";

/**
 *author Olaoye Salem
 * @title SupplyChainVerification
 * @dev Smart contract for decentralized supply chain verification using Proof of Identity.
 */
contract SupplyChainVerification is AccessControl {
    using SafeMath for uint256;

    /* STATE VARIABLES
    ==================================================*/
    /**
     * @dev The Proof of Identity Contract.
     */
    IProofOfIdentity private _proofOfIdentity;

    /**
     * @dev Role representing a producer in the supply chain.
     */
    bytes32 public constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");

    /**
     * @dev Role representing a verifier in the supply chain.
     */
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    struct Product {
        uint256 productId;
        address producer;
        uint256 productionTimestamp;
        bool[] verificationSteps;  // Track each step of verification
        uint256 reward;  // Reward for the verifier
    }

    /**
     * @dev Mapping from product ID to product details.
     */
    mapping(uint256 => Product) private _products;

    /* EVENTS
    ==================================================*/
    /**
     * @notice Emits the new Proof of Identity contract address.
     * @param poiAddress The new Proof of Identity contract address.
     */
    event POIAddressUpdated(address indexed poiAddress);

    /**
     * @notice Emits information about a product being added to the supply chain.
     * @param productId The unique identifier of the product.
     * @param producer The address of the producer adding the product.
     * @param timestamp The timestamp when the product was added.
     */
    event ProductAdded(uint256 indexed productId, address indexed producer, uint256 timestamp);

    /**
     * @notice Emits information about a product being verified in the supply chain.
     * @param productId The unique identifier of the product.
     * @param verifier The address of the entity verifying the product.
     * @param timestamp The timestamp when the product was verified.
     * @param verificationStep The step at which the product was verified.
     * @param reward The reward given to the verifier.
     */
    event ProductVerified(
        uint256 indexed productId,
        address indexed verifier,
        uint256 timestamp,
        uint256 verificationStep,
        uint256 reward
    );

    /* ERRORS
    ==================================================*/
    /**
     * @notice Error to throw when the zero address has been supplied and it
     * is not allowed.
     */
    error SupplyChainVerification__ZeroAddress();

    /**
     * @notice Error to throw when an account does not have a Proof of Identity
     * NFT.
     */
    error SupplyChainVerification__NoIdentityNFT();

    /**
     * @notice Error to throw when an account is not authorized for a specific role.
     * @param role The role that is not authorized.
     */
    error SupplyChainVerification__UnauthorizedRole(bytes32 role);

    /**
     * @notice Error to throw when an account is suspended.
     */
    error SupplyChainVerification__Suspended();

    /**
     * @notice Error to throw when an attribute has expired.
     * @param attribute The name of the required attribute.
     * @param expiry The expiry timestamp of the attribute.
     */
    error SupplyChainVerification__AttributeExpired(string attribute, uint256 expiry);

    /* MODIFIERS
    ==================================================*/
    /**
     * @dev Modifier to be used on any functions that require a user be
     * permissioned per this contract's definition.
     * Ensures that the account:
     * -    has a Proof of Identity NFT;
     * -    is not suspended.
     *
     * May revert with `SupplyChainVerification__NoIdentityNFT`.
     * May revert with `SupplyChainVerification__Suspended`.
     * May revert with `SupplyChainVerification__AttributeExpired`.
     */
    modifier onlyPermissioned(address account) {
        // ensure the account has a Proof of Identity NFT
        if (!_hasID(account)) revert SupplyChainVerification__NoIdentityNFT();

        // ensure the account is not suspended
        if (_isSuspended(account)) revert SupplyChainVerification__Suspended();

        _;
    }

    /**
     * @dev Modifier to be used on functions that require the sender to have a specific role.
     * @param role The required role.
     */
    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) revert SupplyChainVerification__UnauthorizedRole(role);
        _;
    }

    /* FUNCTIONS
    ==================================================*/
    /* Constructor
    ========================================*/
    /**
     * @param admin The address of the admin.
     * @param proofOfIdentity_ The address of the Proof of Identity contract.
     */
    constructor(
        address admin,
        address proofOfIdentity_
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        setPOIAddress(proofOfIdentity_);

        _setupRole(PRODUCER_ROLE, admin);
        _setupRole(VERIFIER_ROLE, admin);
    }

    /* External
    ========================================*/
    /**
     * @notice Adds a new product to the supply chain.
     *
     * @param productId The unique identifier of the product.
     * @param productionTimestamp The timestamp when the product was produced.
     *
     * @dev
     * May revert with `SupplyChainVerification__NoIdentityNFT`.
     * May revert with `SupplyChainVerification__Suspended`.
     * May revert with `SupplyChainVerification__AttributeExpired`.
     */
    function addProduct(uint256 productId, uint256 productionTimestamp) external onlyPermissioned(msg.sender) onlyRole(PRODUCER_ROLE) {
        // Additional checks and product addition logic can be implemented here

        // Save product details
        _products[productId] = Product({
            productId: productId,
            producer: msg.sender,
            productionTimestamp: productionTimestamp,
            verificationSteps: new bool[](3),  // Assuming three verification steps
            reward: 0
        });

        // Emit an event indicating the addition of the product
        emit ProductAdded(productId, msg.sender, block.timestamp);
    }

    /**
     * @notice Verifies a product in the supply chain.
     *
     * @param productId The unique identifier of the product.
     * @param verificationStep The step at which the product is verified.
     * @param reward The reward given to the verifier.
     *
     * @dev
     * May revert with `SupplyChainVerification__NoIdentityNFT`.
     * May revert with `SupplyChainVerification__Suspended`.
     * May revert with `SupplyChainVerification__AttributeExpired`.
     */
    function verifyProduct(uint256 productId, uint256 verificationStep, uint256 reward) external onlyPermissioned(msg.sender) onlyRole(VERIFIER_ROLE) {
        require(verificationStep < _products[productId].verificationSteps.length, "SupplyChainVerification__InvalidStep");

        // Update product verification information
        _products[productId].verificationSteps[verificationStep] = true;
        _products[productId].reward = _products[productId].reward.add(reward);

        // Emit an event indicating the verification of the product
        emit ProductVerified(productId, msg.sender, block.timestamp, verificationStep, reward);
    }

    /**
     * @notice Returns the details of a product.
     * @param productId The unique identifier of the product.
     * @return The product details.
     */
    function getProductDetails(uint256 productId) external view returns (Product memory) {
        return _products[productId];
    }

    /**
     * @notice Updates the Proof of Identity contract address.
     * @param poiAddress The new Proof of Identity contract address.
     */
    function setPOIAddress(address poiAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(poiAddress != address(0), "SupplyChainVerification__ZeroAddress");
        _proofOfIdentity = IProofOfIdentity(poiAddress);
        emit POIAddressUpdated(poiAddress);
    }

    /**
     * @notice Returns whether an `account` is eligible to participate in the
     * supply chain.
     *
     * @param account The account to check.
     *
     * @return True if the account can participate, false otherwise.
     *
     * @dev Requires that the account:
     * -    has a Proof of Identity NFT;
     * -    is not suspended.
     */
    function accountEligible(address account) external view returns (bool) {
        if (!_hasID(account)) return false;
        if (_isSuspended(account)) return false;
        return true;
    }

    /**
     * @notice Grants a role to an address.
     * @param account The address to grant the role to.
     * @param role The role to grant.
     */
    function grantRole(address account, bytes32 role) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(role, account);
    }

    /**
     * @notice Revokes a role from an address.
     * @param account The address to revoke the role from.
     * @param role The role to revoke.
     */
    function revokeRole(address account, bytes32 role) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(role, account);
    }

    /**
     * @notice Checks if an account has a specific role.
     * @param account The address to check.
     * @param role The role to check.
     * @return True if the account has the role, false otherwise.
     */
    function hasAccountRole(address account, bytes32 role) external view returns (bool) {
        return hasRole(role, account);
    }

    /* Private
    ========================================*/
    /**
     * @notice Returns whether an account holds a Proof of Identity NFT.
     * @param account The account to check.
     * @return True if the account holds a Proof of Identity NFT, else false.
     */
    function _hasID(address account) private view returns (bool) {
        return _proofOfIdentity.balanceOf(account) > 0;
    }

    /**
     * @notice Returns whether an account is suspended.
     * @param account The account to check.
     * @return True if the account is suspended, false otherwise.
     */
    function _isSuspended(address account) private view returns (bool) {
        return _proofOfIdentity.isSuspended(account);
    }
}
