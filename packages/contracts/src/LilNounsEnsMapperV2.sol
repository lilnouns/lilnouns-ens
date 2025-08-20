// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

/// @notice ENS contracts
import { ENS } from "@ensdomains/ens-contracts/registry/ENS.sol";
import { IAddrResolver } from "@ensdomains/ens-contracts/resolvers/profiles/IAddrResolver.sol";
import { ITextResolver } from "@ensdomains/ens-contracts/resolvers/profiles/ITextResolver.sol";
import { INameResolver } from "@ensdomains/ens-contracts/resolvers/profiles/INameResolver.sol";

/// @notice OpenZeppelin upgradeable utilities
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/// @notice Local imports
import { ILilNounsEnsMapperV1 } from "./interfaces/ILilNounsEnsMapperV1.sol";
import { LilNounsEnsErrors } from "./libraries/LilNounsEnsErrors.sol";

/// @title LilNounsEnsMapperV2
/// @notice Upgradeable ENS resolver and controller for Lil Nouns NFTs.
/// @dev
/// - Manages one ENS subname per NFT tokenId under a configured root (e.g. `lilnouns.eth`).
/// - Implements ENS resolver interfaces: addr/text/name.
/// - Supports migration from legacy V1 mapper.
/// - UUPS upgradeable, controlled by contract owner.
/// - Reentrancy-locked via OZ `ReentrancyGuardUpgradeable`.
contract LilNounsEnsMapperV2 is
  Initializable,
  UUPSUpgradeable,
  Ownable2StepUpgradeable,
  ReentrancyGuardUpgradeable,
  IAddrResolver,
  ITextResolver,
  INameResolver,
  IERC165
{
  using Strings for uint256;

  /// @notice ENS registry reference.
  ENS public ens;

  /// @notice Legacy V1 mapping contract.
  ILilNounsEnsMapperV1 public legacy;

  /// @notice Lil Nouns NFT contract.
  IERC721 public nft;

  /// @notice ENS namehash of the root name (e.g. namehash("lilnouns.eth")).
  bytes32 public rootNode;

  /// @notice Human-readable root label (e.g. "lilnouns"), used for `name()` composition.
  string public rootLabel;

  /// @dev tokenId => ENS node.
  mapping(uint256 => bytes32) private _tokenToNode;

  /// @dev ENS node => tokenId.
  mapping(bytes32 => uint256) private _nodeToToken;

  /// @dev ENS node => label.
  mapping(bytes32 => string) private _nodeToLabel;

  /// @dev ENS node => text records (e.g., description, avatar, etc.).
  mapping(bytes32 => mapping(string => string)) private _texts;

  /// @dev Marks tokens whose legacy subname has been explicitly released, allowing V2 claim.
  mapping(uint256 => bool) private _legacyReleased;

  /// @notice Emitted when a new subname is registered.
  event SubnameClaimed(address indexed registrar, uint256 indexed tokenId, bytes32 indexed node, string label);

  /// @notice Emitted when a text record is updated.
  event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

  /// @notice Initializes the resolver/controller.
  /// @param initialOwner Address to set as the initial contract owner.
  /// @param legacyAddr Address of the legacy V1 mapping contract.
  /// @param ensRegistry Address of the ENS registry.
  /// @param ensRoot ENS namehash of the root name (e.g. namehash("lilnouns.eth")).
  /// @param labelRoot Human-readable root label (e.g. "lilnouns").
  function initialize(
    address initialOwner,
    address legacyAddr,
    address ensRegistry,
    bytes32 ensRoot,
    string calldata labelRoot
  ) external initializer {
    if (legacyAddr == address(0)) revert LilNounsEnsErrors.InvalidLegacyAddress();
    if (ensRegistry == address(0)) revert LilNounsEnsErrors.InvalidENSRegistry();

    // Initialize Ownable with explicit owner, then 2-step ownership extension.
    __Ownable_init(initialOwner);
    __Ownable2Step_init();
    __UUPSUpgradeable_init();
    __ReentrancyGuard_init();

    legacy = ILilNounsEnsMapperV1(legacyAddr);
    nft = legacy.nft();
    ens = ENS(ensRegistry);
    rootNode = ensRoot;
    rootLabel = labelRoot;
  }

  /// @inheritdoc UUPSUpgradeable
  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address) internal override onlyOwner {
    // Intentionally empty: authorization enforced by onlyOwner modifier.
  }

  /// @notice Claims a new subname for a Lil Noun NFT.
  /// @dev
  /// - Reentrancy-protected.
  /// - One subname per tokenId.
  /// - Reverts if:
  ///   - caller is not token owner,
  ///   - tokenId already mapped in V2 or exists in legacy V1,
  ///   - label already taken by another tokenId.
  /// @param label Desired label (e.g., "noun42").
  /// @param tokenId Token ID to associate with the subname.
  function claimSubname(string calldata label, uint256 tokenId) external nonReentrant {
    if (nft.ownerOf(tokenId) != msg.sender) revert LilNounsEnsErrors.NotTokenOwner(tokenId);
    if (_tokenToNode[tokenId] != bytes32(0)) revert LilNounsEnsErrors.AlreadyClaimed(tokenId);
    if (legacy.tokenHashmap(tokenId) != bytes32(0) && !_legacyReleased[tokenId]) {
      revert LilNounsEnsErrors.AlreadyClaimed(tokenId);
    }
    if (bytes(label).length == 0) revert LilNounsEnsErrors.InvalidLabel();

    bytes32 labelHash = keccak256(abi.encodePacked(label));
    bytes32 node = keccak256(abi.encodePacked(rootNode, labelHash));

    uint256 existing = _nodeToToken[node];
    bool taken = (existing != 0) || (_tokenToNode[0] == node);
    if (taken) revert LilNounsEnsErrors.AlreadyClaimed(existing);

    /// @dev Effects first: mutate storage before external call (reentrancy-safe)
    _tokenToNode[tokenId] = node;
    _nodeToToken[node] = tokenId;
    _nodeToLabel[node] = label;
    if (_legacyReleased[tokenId]) {
      delete _legacyReleased[tokenId];
    }

    /// @dev Interactions: ENS registry call — external, but trusted
    ens.setSubnodeRecord(rootNode, labelHash, address(this), address(this), 0);

    /// @custom:slither-safe-event-after-call
    emit SubnameClaimed(msg.sender, tokenId, node, label);
    /// @custom:slither-safe-event-after-call
    emit AddrChanged(node, msg.sender);
  }

  /// @notice Resets the resolver for a claimed subname back to this contract.
  /// @dev
  /// - Useful if resolver was changed elsewhere.
  /// - Callable by contract owner or NFT owner.
  /// @param tokenId Token ID with an associated subname.
  function restoreResolver(uint256 tokenId) external {
    bytes32 node = _tokenToNode[tokenId];
    if (node == bytes32(0)) revert LilNounsEnsErrors.UnregisteredNode(node);
    if (msg.sender != owner() && nft.ownerOf(tokenId) != msg.sender) {
      revert LilNounsEnsErrors.NotAuthorised(tokenId);
    }
    ens.setResolver(node, address(this));
  }

  /// @notice Releases (unclaims) a subname so it can be claimed again by someone else.
  /// @dev
  /// - Callable by contract owner or current NFT owner.
  /// - Clears internal mappings and clears the ENS subnode record.
  /// @param tokenId Token ID whose subname should be released.
  function relinquishSubname(uint256 tokenId) external nonReentrant {
    bytes32 node = _tokenToNode[tokenId];
    if (node == bytes32(0)) revert LilNounsEnsErrors.UnregisteredNode(node);

    if (msg.sender != owner() && nft.ownerOf(tokenId) != msg.sender) {
      revert LilNounsEnsErrors.NotAuthorised(tokenId);
    }

    string memory label = _nodeToLabel[node];
    bytes32 labelHash = keccak256(abi.encodePacked(label));

    // Effects: clear internal mappings
    delete _nodeToToken[node];
    delete _nodeToLabel[node];
    delete _tokenToNode[tokenId];
    // Note: _texts[node][key] entries (if any) become unreachable.

    // Interactions: clear the ENS subnode record for indexers/UIs
    ens.setSubnodeRecord(rootNode, labelHash, address(0), address(0), 0);

    // Emit reindex hint
    emit AddrChanged(node, address(0));
  }

  /// @notice Releases a legacy (V1) subname for a token so it can claim again in V2.
  /// @dev
  /// - Callable by contract owner or current NFT owner.
  /// - Marks the token as legacy-released and clears the ENS subnode record for the legacy label.
  /// @param tokenId Token ID with a legacy subname to release.
  function releaseLegacySubname(uint256 tokenId) external nonReentrant {
    bytes32 node = legacy.tokenHashmap(tokenId);
    if (node == bytes32(0)) revert LilNounsEnsErrors.UnregisteredNode(node);

    if (msg.sender != owner() && nft.ownerOf(tokenId) != msg.sender) {
      revert LilNounsEnsErrors.NotAuthorised(tokenId);
    }

    // Mark legacy as released to allow V2 claim
    _legacyReleased[tokenId] = true;

    // Best-effort: clear subnode in ENS for indexers/UIs
    string memory label = legacy.hashToDomainMap(node);
    if (bytes(label).length != 0) {
      bytes32 labelHash = keccak256(abi.encodePacked(label));
      ens.setSubnodeRecord(rootNode, labelHash, address(0), address(0), 0);
    }

    // Emit reindex hint on the legacy node
    emit AddrChanged(node, address(0));
  }

  /// @notice Migrates a V1 subname to V2 (owner-only).
  /// @dev Reentrancy-protected.
  /// @param tokenId NFT token ID to migrate.
  function migrateLegacySubname(uint256 tokenId) external onlyOwner nonReentrant {
    bytes32 node = legacy.tokenHashmap(tokenId);
    if (node == bytes32(0)) revert LilNounsEnsErrors.UnregisteredNode(node);

    string memory label = legacy.hashToDomainMap(node);
    if (bytes(label).length == 0) revert LilNounsEnsErrors.UnregisteredNode(node);

    uint256 existing = _nodeToToken[node];
    bool taken = (existing != 0) || (_tokenToNode[0] == node);
    if (taken) revert LilNounsEnsErrors.AlreadyClaimed(existing);

    /// @dev Effects first: mutate storage before external call
    _tokenToNode[tokenId] = node;
    _nodeToToken[node] = tokenId;
    _nodeToLabel[node] = label;

    /// @dev Interactions
    ens.setSubnodeRecord(rootNode, keccak256(abi.encodePacked(label)), address(this), address(this), 0);

    address currentOwner = nft.ownerOf(tokenId);
    /// @custom:slither-safe-event-after-call
    emit SubnameClaimed(currentOwner, tokenId, node, label);
    /// @custom:slither-safe-event-after-call
    emit AddrChanged(node, currentOwner);
  }

  /// @inheritdoc IAddrResolver
  function addr(bytes32 node) external view override returns (address payable) {
    uint256 tokenId = _nodeToExistingToken(node);
    return payable(nft.ownerOf(tokenId));
  }

  /// @inheritdoc ITextResolver
  function text(bytes32 node, string calldata key) external view override returns (string memory) {
    uint256 tokenId = _nodeToExistingToken(node);
    if (keccak256(bytes(key)) == keccak256("avatar")) {
      return string(abi.encodePacked("eip155:1/erc721:", _toHexString(address(nft)), "/", tokenId.toString()));
    }
    return _texts[node][key];
  }

  /// @inheritdoc INameResolver
  function name(bytes32 node) external view override returns (string memory) {
    string memory label = _nodeToLabel[node];
    if (bytes(label).length > 0) {
      return string(abi.encodePacked(label, ".", rootLabel, ".eth"));
    }
    return legacy.name(node);
  }

  /// @notice Returns the ENS node associated with a given tokenId (V2 first, then legacy).
  /// @param tokenId The NFT token id.
  /// @return node The ENS node for the token, or bytes32(0) if none is registered.
  function ensNodeOf(uint256 tokenId) external view returns (bytes32 node) {
    node = _tokenToNode[tokenId];
    if (node == bytes32(0)) {
      node = legacy.tokenHashmap(tokenId);
    }
  }

  /// @notice Returns the ENS name attached to a tokenId if present.
  /// @dev Prefers the V2 label if available; falls back to legacy resolver name.
  /// @param tokenId The NFT token id.
  /// @return The ENS name (e.g., "noun42.lilnouns.eth") or empty string if not registered.
  function ensNameOf(uint256 tokenId) public view returns (string memory) {
    bytes32 node = _tokenToNode[tokenId];
    if (node == bytes32(0)) {
      node = legacy.tokenHashmap(tokenId);
    }
    if (node == bytes32(0)) {
      return "";
    }

    string memory label = _nodeToLabel[node];
    if (bytes(label).length > 0) {
      return string(abi.encodePacked(label, ".", rootLabel, ".eth"));
    }
    return legacy.name(node);
  }

  /// @notice Returns whether a given ENS node is managed by the legacy V1 mapper.
  /// @dev A node is considered legacy if it is not mapped in V2, but the legacy V1 mapper resolves it.
  /// @param node The ENS node to check.
  /// @return isLegacy True if the node is legacy (exists only in V1), false otherwise.
  function isLegacyNode(bytes32 node) public view returns (bool isLegacy) {
    // If V2 has a mapping for this node, it's not legacy.
    if (_nodeToToken[node] != 0) {
      return false;
    }
    // bytes32(0) is not a valid legacy node.
    if (node == bytes32(0)) {
      return false;
    }
    // Consider legacy if the legacy mapper recognizes the node (has a label).
    // Using label presence to avoid relying on name() formatting.
    string memory label = legacy.hashToDomainMap(node);
    return bytes(label).length != 0;
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return
      interfaceId == type(IAddrResolver).interfaceId ||
      interfaceId == type(ITextResolver).interfaceId ||
      interfaceId == type(INameResolver).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }

  /// @notice Sets a text record (excluding "avatar").
  /// @param node ENS node.
  /// @param key Text key (e.g., "description").
  /// @param value Value for the text record.
  function setText(bytes32 node, string calldata key, string calldata value) external {
    uint256 tokenId = _nodeToExistingToken(node);
    if (msg.sender != owner() && nft.ownerOf(tokenId) != msg.sender) {
      revert LilNounsEnsErrors.NotAuthorised(tokenId);
    }
    if (keccak256(bytes(key)) == keccak256("avatar")) revert LilNounsEnsErrors.OverrideAvatarKey();

    _texts[node][key] = value;
    emit TextChanged(node, key, key);
  }

  /// @notice Emits AddrChanged for multiple tokenIds.
  /// @dev Useful for manual re-indexing by The Graph or Etherscan.
  /// @param tokenIds List of token IDs.
  function emitAddrEvents(uint256[] calldata tokenIds) external {
    // slither-disable-next-line calls-loop
    for (uint256 i = 0; i < tokenIds.length; ) {
      bytes32 node = _tokenToNode[tokenIds[i]];
      if (node != bytes32(0)) {
        // slither-disable-next-line calls-loop
        emit AddrChanged(node, nft.ownerOf(tokenIds[i]));
      }
      unchecked {
        ++i;
      }
    }
  }

  /// @notice Emits TextChanged for one key across multiple tokenIds.
  /// @dev Useful to force reindexing of off-chain profiles.
  /// @param tokenIds List of token IDs.
  /// @param key The text key to re-emit.
  function emitTextEvents(uint256[] calldata tokenIds, string calldata key) external {
    for (uint256 i = 0; i < tokenIds.length; ) {
      bytes32 node = _tokenToNode[tokenIds[i]];
      if (node != bytes32(0)) {
        emit TextChanged(node, key, key);
      }
      unchecked {
        ++i;
      }
    }
  }

  /// @dev Resolves a node to an existing tokenId with bijection check.
  /// @param node ENS node being resolved.
  /// @return tokenId TokenId mapped to `node`.
  function _nodeToExistingToken(bytes32 node) internal view returns (uint256 tokenId) {
    tokenId = _nodeToToken[node];
    if (tokenId == 0) {
      if (_tokenToNode[0] != node) revert LilNounsEnsErrors.UnregisteredNode(node);
      return 0;
    }
    if (_tokenToNode[tokenId] != node) revert LilNounsEnsErrors.UnregisteredNode(node);
  }

  /// @dev Converts an address to a lowercase hex string (no EIP-55 checksum).
  /// @param a Address to convert.
  /// @return str Hex string.
  function _toHexString(address a) internal pure returns (string memory str) {
    bytes memory alphabet = "0123456789abcdef";
    bytes20 data = bytes20(a);
    bytes memory buf = new bytes(42);
    buf[0] = "0";
    buf[1] = "x";
    for (uint256 i = 0; i < 20; ) {
      buf[2 + i * 2] = alphabet[uint8(data[i] >> 4)];
      buf[3 + i * 2] = alphabet[uint8(data[i] & 0x0f)];
      unchecked {
        ++i;
      }
    }
    str = string(buf);
  }

  /// @notice Reserved storage space for future variable additions in upgradeable contracts to prevent storage layout conflicts.
  // slither-disable-next-line naming-convention,unused-state
  uint256[43] private __gap;
}
