// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { ILilNounsEnsMapperV1 } from "./interfaces/ILilNounsEnsMapperV1.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC1155HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { INameWrapper } from "@ensdomains/ens-contracts/wrapper/INameWrapper.sol";

/**
 * @title LilNounsEnsMapperV2
 * @author LilNouns DAO
 * @notice An upgradeable ENS resolver and registrar for managing "lilnouns.eth" subdomains
 * @dev This contract serves as a delta-only follow-up to the legacy mapper (0x27c4...),
 *      providing enhanced functionality for controlling wrapped ENS domains under "lilnouns.eth".
 *      It implements the ENS resolver interface and allows NFT holders to claim and manage subdomains.
 *
 * Key Features:
 * - Upgradeable architecture using UUPS pattern
 * - Pausable functionality for emergency stops
 * - Reentrancy protection for critical operations
 * - Integration with legacy mapper for backward compatibility
 * - Automatic avatar record generation using EIP-155 format
 * - Owner and NFT holder authorization system
 *
 * @custom:version 2.0.0
 * @custom:oz-upgrades-safe
 */
contract LilNounsEnsMapperV2 is
  Initializable,
  PausableUpgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  UUPSUpgradeable,
  ERC1155HolderUpgradeable
{
  using Strings for uint256;
  using Strings for address;

  /* ───────────── custom errors ───────────── */

  /// @notice Thrown when caller is not authorized to perform the action
  /// @dev Authorization requires being either the contract owner or the NFT owner
  error NotAuthorised();

  /// @notice Thrown when trying to resolve a node that doesn't exist
  error UnknownNode();

  /// @notice Thrown when attempting to claim a subdomain that's already claimed
  error AlreadyClaimed();

  /// @notice Thrown when trying to modify the locked avatar text record
  /// @dev Avatar records are automatically generated and cannot be manually set
  error AvatarLocked();

  /// @notice Thrown when receiving an unexpected ERC1155 batch transfer
  error Unexpected1155Batch();

  /// @notice Thrown when receiving an unexpected ERC1155 token
  error Unexpected1155Token();

  /// @notice Thrown when querying information for an unregistered token
  error UnregisteredToken();

  /// @notice Thrown when trying to import legacy data that doesn't exist or is already imported
  error NothingToImport();

  /// @notice Thrown when ENS subnode record creation fails
  error SubnodeRecordFailed();

  /// @notice Thrown when providing an empty label for subdomain registration
  error EmptyLabel();

  /// @notice Thrown when providing an empty key for text record operations
  error EmptyKey();

  /// @notice Thrown when providing an empty array to functions that require non-empty arrays
  error EmptyArray();

  /// @notice Thrown when initializing with an invalid legacy contract address
  error InvalidLegacyAddress();

  /* ───────────── constants ───────────── */

  /// @notice The LilNouns NFT contract address
  IERC721 internal constant NFT = IERC721(0x4b10701Bfd7BFEdc47d50562b76b436fbB5BdB3B);

  /// @notice The ENS Name Wrapper contract for managing wrapped domains
  INameWrapper internal constant WRAPPER = INameWrapper(0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401);

  /// @notice The root node hash for "lilnouns.eth"
  /// @dev Computed as namehash("lilnouns.eth")
  bytes32 internal constant ROOT_NODE = 0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492;

  /// @notice The root label for the domain
  string internal constant ROOT_LABEL = "lilnouns";

  /// @notice Hash of the "avatar" key for text records
  /// @dev Used to identify and protect avatar text records from manual modification
  bytes32 internal constant AVATAR_KEY_HASH = keccak256("avatar");

  /* ───────────── storage (delta‑only) ───────────── */

  /// @notice Reference to the legacy mapper contract for backward compatibility
  /// @dev Used to read historical data during migration and fallback operations
  ILilNounsEnsMapperV1 public legacy;

  /// @notice Maps node hashes to text record key-value pairs for new registrations
  /// @dev Only stores text records for domains registered in this contract version
  mapping(bytes32 => mapping(string => string)) private _texts;

  /// @notice Maps node hashes to token IDs for new registrations
  /// @dev Used to resolve which token owns a specific ENS node
  mapping(bytes32 => uint256) private _hashToId;

  /// @notice Maps token IDs to their corresponding node hashes
  /// @dev Used for reverse lookup from token to ENS node
  mapping(uint256 => bytes32) private _idToHash;

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[47] private __gap;

  /* ───────────── events ───────────── */

  /**
   * @notice Emitted when an address record is updated for an ENS node
   * @param node The ENS node hash that was updated
   * @param a The new address associated with the node
   * @dev This event maintains signature compatibility with the legacy contract
   */
  event AddrChanged(bytes32 indexed node, address a);

  /**
   * @notice Emitted when a subdomain is successfully registered
   * @param registrar The address that registered the subdomain (current NFT owner)
   * @param tokenId The token ID that was used to register the subdomain
   * @param label The subdomain label that was registered
   * @dev This event maintains signature compatibility with the legacy contract
   */
  event RegisterSubdomain(address indexed registrar, uint256 indexed tokenId, string indexed label);

  /**
   * @notice Emitted when a text record is updated for an ENS node
   * @param node The ENS node hash that was updated
   * @param key The text record key that was updated
   * @param value The new value for the text record
   * @param updatedBy The address that performed the update
   */
  event TextChanged(bytes32 indexed node, string indexed key, string value, address indexed updatedBy);

  /**
   * @notice Emitted when legacy domain data is imported from V1 mapper
   * @param tokenId The token ID that was imported
   * @param node The ENS node hash for the imported domain
   * @param label The domain label that was imported
   * @param importedBy The address that performed the import
   */
  event LegacyImported(uint256 indexed tokenId, bytes32 indexed node, string label, address indexed importedBy);

  /**
   * @notice Emitted when multiple address records are updated in batch
   * @param tokenIds Array of token IDs that were updated
   * @param updatedBy The address that performed the batch update
   * @param count The number of addresses updated
   */
  event BatchAddressesUpdated(uint256[] tokenIds, address indexed updatedBy, uint256 count);

  /**
   * @notice Emitted when the contract is paused
   * @param account The address that paused the contract
   */
  event ContractPaused(address indexed account);

  /**
   * @notice Emitted when the contract is unpaused
   * @param account The address that unpaused the contract
   */
  event ContractUnpaused(address indexed account);

  /**
   * @notice Emitted when the contract is upgraded to a new implementation
   * @param previousImplementation The address of the previous implementation
   * @param newImplementation The address of the new implementation
   * @param upgradedBy The address that performed the upgrade
   */
  event ContractUpgraded(
    address indexed previousImplementation,
    address indexed newImplementation,
    address indexed upgradedBy
  );

  /* ───────────── modifiers ───────────── */

  /**
   * @notice Ensures the caller is authorized to perform actions on behalf of a token
   * @param tokenId The token ID to check authorization for
   * @dev Authorization is granted to either the contract owner or the current NFT owner
   */
  modifier authorised(uint256 tokenId) {
    if (msg.sender != owner() && msg.sender != NFT.ownerOf(tokenId)) revert NotAuthorised();
    _;
  }

  /* ───────────── initializer / upgrade ───────────── */

  /**
   * @notice Contract constructor that disables initializers
   * @dev Required for upgradeable contracts to prevent initialization of the implementation
   * @custom:oz-upgrades-unsafe-allow constructor
   */
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initializes the contract with the legacy mapper address
   * @param legacyAddress Address of the legacy LilNounsEnsMapperV1 contract
   * @dev This function can only be called once during deployment
   *      Initializes all parent contracts in the correct inheritance order
   * @custom:initializer
   */
  function initialize(address legacyAddress) external initializer {
    // Initialize parent contracts in inheritance order
    __Pausable_init();
    __Ownable_init(msg.sender);
    __ReentrancyGuard_init();
    __UUPSUpgradeable_init();
    // Note: ERC1155HolderUpgradeable doesn't have an initializer

    if (legacyAddress == address(0)) revert InvalidLegacyAddress();
    legacy = ILilNounsEnsMapperV1(legacyAddress);
  }

  /**
   * @notice Authorizes contract upgrades
   * @param newImplementation The address of the new implementation (unused)
   * @dev Only the contract owner can authorize upgrades
   *      This function is intentionally minimal as per OpenZeppelin UUPS pattern
   */
  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
    // Only owner can authorize upgrades - no additional logic needed
    // This function is intentionally empty as per OpenZeppelin UUPS pattern
  }

  /**
   * @notice Overrides the upgrade function to emit ContractUpgraded event
   * @param newImplementation The address of the new implementation
   * @param data The initialization data for the upgrade
   * @dev Emits ContractUpgraded event with previous and new implementation addresses
   */
  function _upgradeToAndCall(address newImplementation, bytes memory data) internal override {
    address previousImplementation = _getImplementation();
    super._upgradeToAndCall(newImplementation, data);
    emit ContractUpgraded(previousImplementation, newImplementation, msg.sender);
  }

  /* ───────────── pause functionality ───────────── */

  /**
   * @notice Pauses all pausable contract functions
   * @dev Only the contract owner can pause the contract
   *      When paused, functions with whenNotPaused modifier will revert
   */
  function pause() external onlyOwner {
    _pause();
    emit ContractPaused(msg.sender);
  }

  /**
   * @notice Unpauses all pausable contract functions
   * @dev Only the contract owner can unpause the contract
   */
  function unpause() external onlyOwner {
    _unpause();
    emit ContractUnpaused(msg.sender);
  }

  /* ───────────── ERC‑165 support ───────────── */

  /**
   * @notice Checks if the contract supports a given interface
   * @param interfaceId The interface identifier to check
   * @return bool True if the interface is supported
   * @dev Supports ENS resolver interfaces:
   *      - 0x3b3b57de: addr(bytes32) - Address resolution
   *      - 0x59d1d43c: text(bytes32,string) - Text record resolution
   *      - 0x691f3431: name(bytes32) - Name resolution
   *      Plus all interfaces from parent contracts
   */
  function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    return
      interfaceId == 0x3b3b57de || // addr(bytes32)
      interfaceId == 0x59d1d43c || // text(bytes32,string)
      interfaceId == 0x691f3431 || // name(bytes32)
      super.supportsInterface(interfaceId);
  }

  /* ───────────── internal helpers ───────────── */

  /**
   * @notice Resolves a node hash to its token ID, checking both new and legacy mappings
   * @param node The ENS node hash to resolve
   * @return id The token ID associated with the node
   * @return fresh True if the mapping exists in this contract, false if from legacy
   * @dev First checks the current contract's mapping, then falls back to legacy contract
   */
  function _resolve(bytes32 node) private view returns (uint256 id, bool fresh) {
    id = _hashToId[node];
    fresh = id != 0;
    if (!fresh) id = legacy.hashToIdMap(node);
  }

  /**
   * @notice Computes the keccak256 hash of a label string
   * @param label The label string to hash
   * @return bytes32 The keccak256 hash of the label
   * @dev Used in ENS node computation following ENS specification
   */
  function _labelHash(string memory label) private pure returns (bytes32) {
    return keccak256(bytes(label));
  }

  /**
   * @notice Computes the ENS node hash for a given label under the root domain
   * @param label The subdomain label
   * @return bytes32 The computed node hash for the full domain
   * @dev Computes keccak256(abi.encodePacked(ROOT_NODE, keccak256(label)))
   *      This follows the ENS namehash algorithm for subdomains
   */
  function _nodeForLabel(string memory label) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ROOT_NODE, _labelHash(label)));
  }

  /* ───────────── resolver interface ───────────── */

  /**
   * @notice Resolves an ENS node to its associated Ethereum address
   * @param node The ENS node hash to resolve
   * @return address The Ethereum address of the current NFT owner
   * @dev Returns the current owner of the NFT associated with the node
   *      Reverts with UnknownNode if the node doesn't exist
   */
  function addr(bytes32 node) external view returns (address) {
    (uint256 id, ) = _resolve(node);
    if (id == 0) revert UnknownNode();
    return NFT.ownerOf(id);
  }

  /**
   * @notice Retrieves a text record for an ENS node
   * @param node The ENS node hash to query
   * @param key The text record key to retrieve
   * @return string The value associated with the key, or empty string if not found
   * @dev Special handling for "avatar" key - automatically generates EIP-155 NFT URI
   *      For other keys, checks current contract first, then falls back to legacy
   *      Avatar format: "eip155:1/erc721:{contractAddress}/{tokenId}"
   */
  function text(bytes32 node, string calldata key) external view returns (string memory) {
    (uint256 id, bool fresh) = _resolve(node);
    if (id == 0) revert UnknownNode();

    if (keccak256(bytes(key)) == AVATAR_KEY_HASH) {
      return string.concat("eip155:1/erc721:", address(NFT).toHexString(), "/", id.toString());
    }
    return fresh ? _texts[node][key] : legacy.texts(node, key);
  }

  /**
   * @notice Resolves an ENS node to its full domain name
   * @param node The ENS node hash to resolve
   * @return string The full domain name (e.g., "label.lilnouns.eth"), or empty if node doesn't exist
   * @dev Constructs the full domain name by combining the stored label with the root domain
   *      Checks current contract first, then falls back to legacy for the label
   */
  function name(bytes32 node) external view returns (string memory) {
    (uint256 id, bool fresh) = _resolve(node);
    if (id == 0) return "";

    string memory label = fresh ? _texts[node]["__label"] : legacy.hashToDomainMap(node);
    return string.concat(label, ".", ROOT_LABEL, ".eth");
  }

  /* ───────────── NFT ↔ ENS helpers ───────────── */

  /**
   * @notice Gets the ENS node hash associated with a token ID
   * @param tokenId The NFT token ID to look up
   * @return node The ENS node hash, or bytes32(0) if not registered
   * @dev Checks current contract first, then falls back to legacy contract
   */
  function tokenNode(uint256 tokenId) public view returns (bytes32 node) {
    node = _idToHash[tokenId];
    if (node == bytes32(0)) node = legacy.tokenHashmap(tokenId);
  }

  /**
   * @notice Gets the ENS node hash for a given subdomain label
   * @param label The subdomain label to look up
   * @return node The ENS node hash if the domain is registered, bytes32(0) otherwise
   * @dev Computes the node hash and checks if it's registered in either contract
   */
  function domainMap(string calldata label) external view returns (bytes32 node) {
    node = _nodeForLabel(label);
    if (_hashToId[node] == 0 && legacy.hashToIdMap(node) == 0) node = bytes32(0);
  }

  /**
   * @notice Gets the full domain name for a token ID
   * @param tokenId The NFT token ID to get the domain for
   * @return string The full domain name (e.g., "label.lilnouns.eth")
   * @dev Combines the stored label with the root domain to form the complete name
   *      Reverts with UnregisteredToken if the token has no associated domain
   */
  function getTokenDomain(uint256 tokenId) public view returns (string memory) {
    bytes32 node = tokenNode(tokenId);
    if (node == bytes32(0)) revert UnregisteredToken();

    string memory label = (_hashToId[node] != 0) ? _texts[node]["__label"] : legacy.hashToDomainMap(node);
    return string.concat(label, ".", ROOT_LABEL, ".eth");
  }

  /**
   * @notice Gets the full domain names for multiple token IDs
   * @param ids Array of NFT token IDs to get domains for
   * @return out Array of full domain names corresponding to the input token IDs
   * @dev Batch version of getTokenDomain for gas efficiency
   *      Will revert if any token ID is not registered
   *      WARNING: Contains external calls inside loop - consider gas limits for large arrays
   */
  function getTokensDomains(uint256[] calldata ids) external view returns (string[] memory out) {
    uint256 len = ids.length;
    if (len > 100) revert EmptyArray(); // Reuse existing error for simplicity, prevents DoS
    out = new string[](len);
    for (uint256 i; i < len; ) {
      out[i] = getTokenDomain(ids[i]);
      unchecked {
        ++i;
      }
    }
  }

  /* ───────────── registrar logic ───────────── */

  /**
   * @notice Claims a subdomain for an NFT token
   * @param label The subdomain label to claim (e.g., "alice" for "alice.lilnouns.eth")
   * @param tokenId The NFT token ID to associate with the subdomain
   * @dev The caller must be authorized (owner or NFT holder) and the contract must not be paused
   *      The label cannot be empty and the subdomain must not already be claimed
   *      Creates an ENS subnode record and emits events for the registration
   */
  function claim(string calldata label, uint256 tokenId) external whenNotPaused nonReentrant authorised(tokenId) {
    if (bytes(label).length == 0) revert EmptyLabel();
    _claimInternal(label, tokenId);
  }

  /**
   * @notice Sets a text record for an ENS node
   * @param node The ENS node hash to set the text record for
   * @param key The text record key
   * @param value The text record value
   * @dev The caller must be authorized for the associated token
   *      Cannot set the "avatar" key as it's automatically generated
   *      The key cannot be empty
   */
  function setText(
    bytes32 node,
    string calldata key,
    string calldata value
  ) external whenNotPaused authorised(_hashToId[node]) {
    if (bytes(key).length == 0) revert EmptyKey();
    if (keccak256(bytes(key)) == AVATAR_KEY_HASH) revert AvatarLocked();
    _texts[node][key] = value;
    emit TextChanged(node, key, value, msg.sender);
  }

  /**
   * @notice Imports a legacy domain registration to the current contract
   * @param tokenId The NFT token ID that has a legacy domain registration
   * @dev The caller must be authorized and there must be a valid legacy registration
   *      The domain must not already be imported to this contract
   *      Recreates the domain registration with the same label
   */
  function importLegacy(uint256 tokenId) external whenNotPaused nonReentrant authorised(tokenId) {
    bytes32 oldNode = legacy.tokenHashmap(tokenId);
    if (oldNode == bytes32(0) || _hashToId[oldNode] != 0) revert NothingToImport();

    string memory label = legacy.hashToDomainMap(oldNode);
    _claimInternal(label, tokenId);
    emit LegacyImported(tokenId, oldNode, label, msg.sender);
  }

  /**
   * @notice Internal function to handle the domain claiming process
   * @param label The subdomain label to claim
   * @param tokenId The NFT token ID to associate with the subdomain
   * @dev Follows checks-effects-interactions pattern for security
   *      Updates internal mappings before making external calls
   *      Creates ENS subnode record and emits appropriate events
   */
  function _claimInternal(string memory label, uint256 tokenId) internal {
    bytes32 node = _nodeForLabel(label);
    if (_hashToId[node] != 0 || legacy.hashToIdMap(node) != 0) revert AlreadyClaimed();

    // Store state changes before external call (checks-effects-interactions pattern)
    _hashToId[node] = tokenId;
    _idToHash[tokenId] = node;
    _texts[node]["__label"] = label;

    // External call after state changes
    bytes32 resultNode = WRAPPER.setSubnodeRecord(
      ROOT_NODE,
      label,
      address(this),
      address(this),
      0,
      0,
      type(uint64).max
    );
    if (resultNode == bytes32(0)) revert SubnodeRecordFailed();

    address currentOwner = NFT.ownerOf(tokenId);
    emit RegisterSubdomain(currentOwner, tokenId, label);
    emit AddrChanged(node, currentOwner);
  }

  /* ───────────── maintenance ───────────── */

  /**
   * @notice Updates address records for multiple tokens to reflect current NFT ownership
   * @param ids Array of NFT token IDs to update
   * @dev Useful when NFTs are transferred and ENS records need to be updated
   *      Emits AddrChanged events for each updated token
   *      All token IDs must have associated domain registrations
   *      WARNING: Contains external calls inside loop - consider gas limits for large arrays
   */
  function updateAddresses(uint256[] calldata ids) external whenNotPaused {
    if (ids.length == 0 || ids.length > 50) revert EmptyArray(); // Limit array size to prevent DoS
    for (uint256 i; i < ids.length; ) {
      bytes32 node = tokenNode(ids[i]);
      if (node == bytes32(0)) revert UnregisteredToken();
      emit AddrChanged(node, NFT.ownerOf(ids[i]));
      unchecked {
        ++i;
      }
    }
    emit BatchAddressesUpdated(ids, msg.sender, ids.length);
  }
}
