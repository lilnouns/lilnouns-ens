// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ILilNounsEnsMapperV1 } from "./interfaces/ILilNounsEnsMapperV1.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { LilNounsEnsErrors } from "./LilNounsEnsErrors.sol";

/// @title LilNounsEnsResolver
/// @notice Abstract, reusable ENS resolver logic for LilNouns-based mappers.
/// @dev
/// - Extracts and encapsulates all resolver-specific state and functions.
/// - Designed for inheritance by upgradeable orchestrator contracts (e.g., LilNounsEnsMapperV2).
/// - Uses OZ Initializable pattern; call __LilNounsEnsResolver_init() from the inheriting contract's initializer.
abstract contract LilNounsEnsResolver is Initializable {
  /// @notice Hash of the "avatar" key for text records
  /// @dev Used to identify and protect avatar text records from manual modification.
  bytes32 internal constant AVATAR_KEY_HASH = keccak256("avatar");

  /// @notice Reference to the legacy mapper contract for backward compatibility
  ILilNounsEnsMapperV1 public legacy;

  /// @notice Maps node hashes to text record key-value pairs for new registrations
  mapping(bytes32 => mapping(string => string)) internal _texts;

  /// @notice Maps node hashes to token IDs for new registrations
  mapping(bytes32 => uint256) internal _hashToId;

  /// @notice Maps token IDs to their corresponding node hashes
  mapping(uint256 => bytes32) internal _idToHash;

  /// @notice The LilNouns NFT contract (configurable)
  IERC721 internal nft;

  /// @notice The ENS root node under which subdomains are created (e.g., namehash("lilnouns.eth"))
  bytes32 internal rootNode;

  /// @notice The human-readable root label (e.g., "lilnouns")
  string internal rootLabel;

  /// @notice Initializer for resolver storage.
  /// @param legacy_ Legacy mapper (V1) contract address for backward reads.
  /// @param nft_ Lil Nouns ERC-721 contract address.
  /// @param rootNode_ The ENS namehash of the root (e.g., namehash("lilnouns.eth")).
  /// @param rootLabel_ The ASCII root label (e.g., "lilnouns").
  function __LilNounsEnsResolver_init(
    address legacy_,
    address nft_,
    bytes32 rootNode_,
    string calldata rootLabel_
  ) internal onlyInitializing {
    if (legacy_ == address(0)) revert LilNounsEnsErrors.InvalidLegacyAddress();
    if (nft_ == address(0)) revert LilNounsEnsErrors.ZeroAddress();
    if (rootNode_ == bytes32(0)) revert LilNounsEnsErrors.InvalidParams();
    if (bytes(rootLabel_).length == 0) revert LilNounsEnsErrors.EmptyLabel();

    legacy = ILilNounsEnsMapperV1(legacy_);
    nft = IERC721(nft_);
    rootNode = rootNode_;
    rootLabel = rootLabel_;
  }

  /// @notice Internal helper to advertise supported ENS resolver interfaces via ERC-165.
  function _supportsResolverInterface(bytes4 interfaceId) internal pure returns (bool) {
    return
      interfaceId == 0x3b3b57de || // addr(bytes32)
      interfaceId == 0x59d1d43c || // text(bytes32,string)
      interfaceId == 0x691f3431; // name(bytes32)
  }

  /// @dev Resolves node to token id with legacy fallback.
  function _resolve(bytes32 node) internal view returns (uint256 id, bool fresh) {
    id = _hashToId[node];
    fresh = id != 0;
    if (!fresh) id = legacy.hashToIdMap(node);
  }

  /// @dev keccak256(label)
  function _labelHash(string memory label) internal pure returns (bytes32) {
    return keccak256(bytes(label));
  }

  /// @dev namehash(rootNode,label) simplified: keccak256(abi.encodePacked(rootNode, keccak256(label)))
  function _nodeForLabel(string memory label) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(rootNode, _labelHash(label)));
  }

  /// @dev Sets text record and emits.
  function _setText(bytes32 node, string memory key, string memory value) internal {
    _texts[node][key] = value;
  }

  /// @dev Records mappings when a label is claimed. Returns the computed node.
  function _mapOnClaim(string memory label, uint256 tokenId) internal returns (bytes32 node) {
    node = _nodeForLabel(label);
    _hashToId[node] = tokenId;
    _idToHash[tokenId] = node;
    _texts[node]["__label"] = label;
  }

  /* ───────────── public resolver interface ───────────── */

  /// @notice Resolves an ENS node to its associated Ethereum address (current NFT owner).
  function addr(bytes32 node) external view returns (address) {
    (uint256 id, ) = _resolve(node);
    if (id == 0) revert LilNounsEnsErrors.UnknownNode();
    return nft.ownerOf(id);
  }

  /// @notice Retrieves a text record for an ENS node.
  /// @dev Special handling for "avatar" key: returns EIP-155 NFT URI.
  function text(bytes32 node, string calldata key) external view returns (string memory) {
    (uint256 id, bool fresh) = _resolve(node);
    if (id == 0) revert LilNounsEnsErrors.UnknownNode();

    if (keccak256(bytes(key)) == AVATAR_KEY_HASH) {
      return string.concat("eip155:1/erc721:", Strings.toHexString(address(nft)), "/", Strings.toString(id));
    }
    return fresh ? _texts[node][key] : legacy.texts(node, key);
  }

  /// @notice Resolves an ENS node to its full domain name or empty if unknown.
  function name(bytes32 node) external view returns (string memory) {
    (uint256 id, bool fresh) = _resolve(node);
    if (id == 0) return "";

    string memory label = fresh ? _texts[node]["__label"] : legacy.hashToDomainMap(node);
    return string.concat(label, ".", rootLabel, ".eth");
  }

  /// @notice Gets the ENS node hash associated with a token ID (with legacy fallback).
  function tokenNode(uint256 tokenId) public view returns (bytes32 node) {
    node = _idToHash[tokenId];
    if (node == bytes32(0)) node = legacy.tokenHashmap(tokenId);
  }

  /// @notice Gets the ENS node for a label if registered in current or legacy, otherwise 0x0.
  function domainMap(string calldata label) external view returns (bytes32 node) {
    node = _nodeForLabel(label);
    if (_hashToId[node] == 0 && legacy.hashToIdMap(node) == 0) node = bytes32(0);
  }

  /// @notice Gets the full domain for a token ID or reverts if unregistered.
  function getTokenDomain(uint256 tokenId) public view returns (string memory) {
    bytes32 node = tokenNode(tokenId);
    if (node == bytes32(0)) revert LilNounsEnsErrors.UnregisteredToken();

    string memory label = (_hashToId[node] != 0) ? _texts[node]["__label"] : legacy.hashToDomainMap(node);
    return string.concat(label, ".", rootLabel, ".eth");
  }

  /// @notice Batch version of getTokenDomain with a conservative upper bound for safety.
  function getTokensDomains(uint256[] calldata ids) external view returns (string[] memory out) {
    uint256 len = ids.length;
    if (len > 100) revert LilNounsEnsErrors.EmptyArray();
    out = new string[](len);
    for (uint256 i; i < len; ) {
      out[i] = getTokenDomain(ids[i]);
      unchecked {
        ++i;
      }
    }
  }
}
