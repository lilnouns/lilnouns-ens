// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { LilNounsEnsHolder } from "./LilNounsEnsHolder.sol";
import { LilNounsEnsWrapper } from "./LilNounsEnsWrapper.sol";
import { LilNounsEnsResolver } from "./LilNounsEnsResolver.sol";
import { LilNounsEnsBase } from "./LilNounsEnsBase.sol";
import { ERC1155HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { LilNounsEnsErrors } from "./LilNounsEnsErrors.sol";

/// @title LilNounsEnsMapperV2
/// @notice Orchestrator combining Holder, Wrapper, and Resolver on top of LilNounsEnsBase.
/// @author LilNouns ENS Contributors
contract LilNounsEnsMapperV2 is LilNounsEnsHolder, LilNounsEnsWrapper, LilNounsEnsResolver {
  /// @notice Disable initializers in the implementation contract to prevent misuse
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice Initialize the mapper with owner, ENS-related contracts, NFT, and root domain configuration.
  /// @param initialOwner The initial owner/admin of the contract.
  /// @param ensAddr ENS registry contract.
  /// @param baseRegistrarAddr .eth Base Registrar contract.
  /// @param nameWrapperAddr ENS NameWrapper contract.
  /// @param legacyAddr Legacy mapper (V1) contract address for backward reads.
  /// @param nftAddr Lil Nouns ERC-721 contract address.
  /// @param rootNode_ The ENS namehash of "{rootLabel}.eth" under which subdomains are created.
  /// @param rootLabel_ The ASCII root label (e.g., "lilnouns").
  function initialize(
    address initialOwner,
    address ensAddr,
    address baseRegistrarAddr,
    address nameWrapperAddr,
    address legacyAddr,
    address nftAddr,
    bytes32 rootNode_,
    string calldata rootLabel_
  ) public initializer {
    LilNounsEnsBase.Config memory cfg = LilNounsEnsBase.Config({
      ens: ensAddr,
      baseRegistrar: baseRegistrarAddr,
      nameWrapper: nameWrapperAddr,
      legacy: legacyAddr,
      nft: nftAddr,
      rootNode: rootNode_,
      rootLabel: rootLabel_
    });
    __LilNounsEnsBase_init(initialOwner, cfg);
  }

  /// @notice Emitted when an address record is updated for an ENS node
  /// @param node The ENS node being updated (indexed)
  /// @param a The new address for the node
  // solhint-disable-next-line gas-indexed-events -- Preserve event ABI; adding indexed would be a breaking change
  event AddrChanged(bytes32 indexed node, address a);

  /// @notice Emitted when a text record is updated for an ENS node
  /// @param node The ENS node being updated (indexed)
  /// @param key The text record key (indexed)
  /// @param value The new text value
  /// @param updatedBy The caller who performed the update (indexed)
  event TextChanged(bytes32 indexed node, string indexed key, string value, address indexed updatedBy);

  /// @notice Emitted when a subdomain is successfully registered
  /// @param registrar The address receiving the subdomain ownership
  /// @param tokenId The associated token ID
  /// @param label The registered label
  event RegisterSubdomain(address indexed registrar, uint256 indexed tokenId, string indexed label);

  /// @notice Emitted when legacy domain data is imported from V1 mapper
  /// @param tokenId The token ID being imported
  /// @param node The ENS node being imported
  /// @param label The imported label
  /// @param importedBy The caller who imported the legacy data (indexed)
  event LegacyImported(uint256 indexed tokenId, bytes32 indexed node, string label, address indexed importedBy);

  /// @notice Emitted when multiple address records are updated in batch
  /// @param tokenIds The list of token IDs updated
  /// @param updatedBy The caller who performed the batch update (indexed)
  /// @param count The number of tokens processed
  event BatchAddressesUpdated(uint256[] tokenIds, address indexed updatedBy, uint256 count);

  /// @notice Emitted when the contract is paused
  /// @param account The account that paused the contract (indexed)
  event ContractPaused(address indexed account);

  /// @notice Emitted when the contract is unpaused
  /// @param account The account that unpaused the contract (indexed)
  event ContractUnpaused(address indexed account);

  /// @notice Ensures the caller is authorized to perform actions on behalf of a token
  modifier authorised(uint256 tokenId) {
    if (msg.sender != owner() && msg.sender != nft.ownerOf(tokenId)) revert LilNounsEnsErrors.NotAuthorised();
    _;
  }

  /// @notice Pause/unpause that emit events expected by legacy tests
  function pause() external override onlyOwner {
    _pause();
    emit ContractPaused(msg.sender);
  }

  /// @notice Unpauses the contract if not within a scheduled pause window
  function unpause() external override onlyOwner {
    _requirePauseLiftable();
    _unpause();
    emit ContractUnpaused(msg.sender);
  }

  /// @notice Checks ERC-165 support including resolver facets and base receivers
  /// @param interfaceId The interface identifier as specified in ERC-165
  /// @return supported True if the interface is supported
  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC1155HolderUpgradeable) returns (bool supported) {
    return _supportsResolverInterface(interfaceId) || super.supportsInterface(interfaceId);
  }

  /// @notice Claims a subdomain for an NFT token
  function claim(string calldata label, uint256 tokenId) external whenNotPaused nonReentrant authorised(tokenId) {
    if (bytes(label).length == 0) revert LilNounsEnsErrors.EmptyLabel();
    _claimInternal(label, tokenId);
  }

  /// @notice Sets a text record for an ENS node
  function setText(
    bytes32 node,
    string calldata key,
    string calldata value
  ) external whenNotPaused authorised(_hashToId[node]) {
    if (bytes(key).length == 0) revert LilNounsEnsErrors.EmptyKey();
    if (keccak256(bytes(key)) == AVATAR_KEY_HASH) revert LilNounsEnsErrors.AvatarLocked();
    _setText(node, key, value);
    emit TextChanged(node, key, value, msg.sender);
  }

  /// @notice Imports a legacy domain registration to the current contract
  function importLegacy(uint256 tokenId) external whenNotPaused nonReentrant authorised(tokenId) {
    bytes32 oldNode = legacy.tokenHashmap(tokenId);
    if (oldNode == bytes32(0) || _hashToId[oldNode] != 0) revert LilNounsEnsErrors.NothingToImport();

    string memory label = legacy.hashToDomainMap(oldNode);
    _claimInternal(label, tokenId);
    emit LegacyImported(tokenId, oldNode, label, msg.sender);
  }

  /// @notice Internal function to handle the domain claiming process
  function _claimInternal(string memory label, uint256 tokenId) internal {
    bytes32 preNode = _nodeForLabel(label);
    if (_hashToId[preNode] != 0 || legacy.hashToIdMap(preNode) != 0) revert LilNounsEnsErrors.AlreadyClaimed();

    // Store state changes before external call (checks-effects-interactions pattern)
    bytes32 node = _mapOnClaim(label, tokenId);

    // Create subnode via NameWrapper
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

  /// @notice Updates address records for multiple tokens to reflect current NFT ownership
  // slither-disable-start calls-loop
  function updateAddresses(uint256[] calldata ids) external whenNotPaused {
    if (ids.length == 0 || ids.length > 50) revert LilNounsEnsErrors.EmptyArray();
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
