// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { LilNounsEnsHolder } from "./LilNounsEnsHolder.sol";
import { LilNounsEnsWrapper } from "./LilNounsEnsWrapper.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ILilNounsEnsMapperV1 } from "./interfaces/ILilNounsEnsMapperV1.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ERC1155HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { LilNounsEnsErrors } from "./LilNounsEnsErrors.sol";

/// @title LilNounsEnsMapperV2
/// @notice UUPS-upgradeable orchestrator combining the Holder and ENS Wrapper capabilities.
/// @dev
/// - Uses initializer pattern; constructor disables initializers for proxies.
/// - Authorizes upgrades via onlyOwner from Ownable2StepUpgradeable inherited through Holder/Wrapper.
/**
 * @author LilNouns ENS Authors
 */
contract LilNounsEnsMapperV2 is LilNounsEnsHolder, LilNounsEnsWrapper, UUPSUpgradeable, PausableUpgradeable {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice Initialize the mapper with owner, ENS-related contracts, NFT, and root domain configuration.
  /// @dev Calls internal initializers of Holder and Wrapper. Reverts on zero addresses or misconfiguration.
  /// @param initialOwner The initial owner/admin of the contract.
  /// @param ens_ ENS registry contract.
  /// @param baseRegistrar_ .eth Base Registrar contract.
  /// @param nameWrapper_ ENS NameWrapper contract.
  /// @param legacy_ Legacy mapper (V1) contract address for backward reads.
  /// @param nft_ Lil Nouns ERC-721 contract address.
  /// @param rootNode_ The ENS namehash of "{rootLabel}.eth" under which subdomains are created.
  /// @param rootLabel_ The ASCII root label (e.g., "lilnouns").
  function initialize(
    address initialOwner,
    address ens_,
    address baseRegistrar_,
    address nameWrapper_,
    address legacy_,
    address nft_,
    bytes32 rootNode_,
    string calldata rootLabel_
  ) public initializer {
    __LilNounsEnsHolder_init(initialOwner);
    __LilNounsEnsWrapper_init(ens_, baseRegistrar_, nameWrapper_);

    if (legacy_ == address(0)) revert LilNounsEnsErrors.InvalidLegacyAddress();
    if (nft_ == address(0)) revert LilNounsEnsErrors.ZeroAddress();
    if (rootNode_ == bytes32(0)) revert LilNounsEnsErrors.InvalidParams();
    if (bytes(rootLabel_).length == 0) revert LilNounsEnsErrors.EmptyLabel();

    legacy = ILilNounsEnsMapperV1(legacy_);
    nft = IERC721(nft_);
    rootNode = rootNode_;
    rootLabel = rootLabel_;
  }

  /// @dev UUPS authorization hook: restrict to owner.
  function _authorizeUpgrade(address) internal override onlyOwner {
    // Intentionally empty: access control enforced by onlyOwner modifier
    return;
  }

  /// @notice Hash of the "avatar" key for text records
  /// @dev Used to identify and protect avatar text records from manual modification. Fixed by EIP-155 and ENS text record schema.
  bytes32 internal constant AVATAR_KEY_HASH = keccak256("avatar");

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

  /// @notice The LilNouns NFT contract (configurable)
  /// @dev Set once during initialize; used for ownership checks and avatar text record.
  IERC721 internal nft;

  /// @notice The ENS root node under which subdomains are created (e.g., namehash("lilnouns.eth"))
  /// @dev Set once during initialize; used to compute subnode hashes and set subnode records.
  bytes32 internal rootNode;

  /// @notice The human-readable root label (e.g., "lilnouns")
  /// @dev Used for name() and domain composition; set once during initialize.
  string internal rootLabel;

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

  /**
   * @notice Ensures the caller is authorized to perform actions on behalf of a token
   * @param tokenId The token ID to check authorization for
   * @dev Authorization is granted to either the contract owner or the current NFT owner
   */
  modifier authorised(uint256 tokenId) {
    if (msg.sender != owner() && msg.sender != nft.ownerOf(tokenId)) revert LilNounsEnsErrors.NotAuthorised();
    _;
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
  function supportsInterface(
    bytes4 interfaceId
  ) public view override(LilNounsEnsWrapper, ERC1155HolderUpgradeable) returns (bool) {
    return
      interfaceId == 0x3b3b57de || // addr(bytes32)
      interfaceId == 0x59d1d43c || // text(bytes32,string)
      interfaceId == 0x691f3431 || // name(bytes32)
      super.supportsInterface(interfaceId);
  }

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
  function _nodeForLabel(string memory label) private view returns (bytes32) {
    return keccak256(abi.encodePacked(rootNode, _labelHash(label)));
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
    if (id == 0) revert LilNounsEnsErrors.UnknownNode();
    return nft.ownerOf(id);
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
    if (id == 0) revert LilNounsEnsErrors.UnknownNode();

    if (keccak256(bytes(key)) == AVATAR_KEY_HASH) {
      return string.concat("eip155:1/erc721:", Strings.toHexString(address(nft)), "/", Strings.toString(id));
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
    return string.concat(label, ".", rootLabel, ".eth");
  }

  /* ───────────── NFT ↔ ENS helpers ───────────── */

  /**
   * @notice Gets the ENS node hash associated with a token ID
   * @param tokenId The NFT token ID to look up
   * @return node The ENS node hash, or bytes32(0) if not registered
   * @dev Checks current contract first, then falls back to legacy contract
   */
  // slither-disable-next-line calls-loop
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
  // slither-disable-next-line calls-loop
  function getTokenDomain(uint256 tokenId) public view returns (string memory) {
    bytes32 node = tokenNode(tokenId);
    if (node == bytes32(0)) revert LilNounsEnsErrors.UnregisteredToken();

    string memory label = (_hashToId[node] != 0) ? _texts[node]["__label"] : legacy.hashToDomainMap(node);
    return string.concat(label, ".", rootLabel, ".eth");
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
    if (len > 100) revert LilNounsEnsErrors.EmptyArray(); // Reuse existing error for simplicity, prevents DoS
    out = new string[](len);
    // slither-disable-next-line calls-inside-a-loop, calls-loop
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
    if (bytes(label).length == 0) revert LilNounsEnsErrors.EmptyLabel();
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
    if (bytes(key).length == 0) revert LilNounsEnsErrors.EmptyKey();
    if (keccak256(bytes(key)) == AVATAR_KEY_HASH) revert LilNounsEnsErrors.AvatarLocked();
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
    if (oldNode == bytes32(0) || _hashToId[oldNode] != 0) revert LilNounsEnsErrors.NothingToImport();

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
    if (_hashToId[node] != 0 || legacy.hashToIdMap(node) != 0) revert LilNounsEnsErrors.AlreadyClaimed();

    // Store state changes before external call (checks-effects-interactions pattern)
    _hashToId[node] = tokenId;
    _idToHash[tokenId] = node;
    _texts[node]["__label"] = label;

    // External call after state changes
    bytes32 resultNode = nameWrapper.setSubnodeRecord(
      rootNode,
      label,
      address(this),
      address(this),
      0,
      0,
      type(uint64).max
    );
    if (resultNode == bytes32(0)) revert LilNounsEnsErrors.SubnodeRecordFailed();

    address currentOwner = nft.ownerOf(tokenId);
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
  // slither-disable-start calls-loop
  function updateAddresses(uint256[] calldata ids) external whenNotPaused {
    if (ids.length == 0 || ids.length > 50) revert LilNounsEnsErrors.EmptyArray(); // Limit array size to prevent DoS
    for (uint256 i; i < ids.length; ) {
      bytes32 node = tokenNode(ids[i]);
      if (node == bytes32(0)) revert LilNounsEnsErrors.UnregisteredToken();
      emit AddrChanged(node, nft.ownerOf(ids[i]));
      unchecked {
        ++i;
      }
    }
    emit BatchAddressesUpdated(ids, msg.sender, ids.length);
  }
  // slither-disable-end calls-loop
}
