// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

// ENS contracts
import { ENS } from "@ensdomains/ens-contracts/registry/ENS.sol";
import { IAddrResolver } from "@ensdomains/ens-contracts/resolvers/profiles/IAddrResolver.sol";
import { ITextResolver } from "@ensdomains/ens-contracts/resolvers/profiles/ITextResolver.sol";
import { INameResolver } from "@ensdomains/ens-contracts/resolvers/profiles/INameResolver.sol";

// OpenZeppelin upgradeable utilities
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

// Local imports
import { ILilNounsEnsMapperV1 } from "./interfaces/ILilNounsEnsMapperV1.sol";
import { LilNounsEnsErrors } from "./libraries/LilNounsEnsErrors.sol";

/// @title LilNounsEnsMapperV2
/// @notice Upgradeable ENS resolver and controller for Lil Nouns NFTs
/// @dev Implements ENS Resolver interfaces and ENS subdomain registration
contract LilNounsEnsMapperV2 is
  Initializable,
  UUPSUpgradeable,
  Ownable2StepUpgradeable,
  IAddrResolver,
  ITextResolver,
  INameResolver,
  IERC165
{
  using Strings for uint256;

  /// @notice ENS registry reference
  ENS public ens;

  /// @notice Legacy V1 mapping contract
  ILilNounsEnsMapperV1 public legacy;

  /// @notice Lil Nouns NFT contract
  IERC721 public nft;

  /// @notice ENS namehash of the root domain (e.g. lilnouns.eth)
  bytes32 public rootNode;

  /// @notice Human-readable root label (e.g. "lilnouns")
  string public rootLabel;

  /// @dev tokenId => ENS node
  mapping(uint256 => bytes32) private _tokenToNode;

  /// @dev ENS node => tokenId
  mapping(bytes32 => uint256) private _nodeToToken;

  /// @dev ENS node => label
  mapping(bytes32 => string) private _nodeToLabel;

  /// @dev ENS node => text records (e.g., description, avatar, etc.)
  mapping(bytes32 => mapping(string => string)) private _texts;

  /// @notice Emitted when a new subdomain is registered
  event SubdomainClaimed(address indexed registrar, uint256 indexed tokenId, bytes32 indexed node, string label);

  /// @notice Emitted when a text record is updated
  event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

  /// @notice Initializes the resolver
  /// @param legacyAddr Address of the legacy V1 mapping contract
  /// @param ensRegistry Address of the ENS registry
  /// @param ensRoot ENS namehash of the root domain
  /// @param labelRoot Human-readable root label (e.g. "lilnouns")
  function initialize(
    address legacyAddr,
    address ensRegistry,
    bytes32 ensRoot,
    string calldata labelRoot
  ) external initializer {
    if (legacyAddr == address(0)) revert LilNounsEnsErrors.InvalidLegacyAddress();
    if (ensRegistry == address(0)) revert LilNounsEnsErrors.InvalidENSRegistry();

    __Ownable2Step_init();
    __UUPSUpgradeable_init();

    legacy = ILilNounsEnsMapperV1(legacyAddr);
    nft = legacy.nft();
    ens = ENS(ensRegistry);
    rootNode = ensRoot;
    rootLabel = labelRoot;
  }

  /// @notice Claims a new subdomain for a Lil Noun NFT
  /// @param label Desired label (e.g., "noun42")
  /// @param tokenId Token ID to associate with the subdomain
  function claimSubdomain(string calldata label, uint256 tokenId) external {
    if (nft.ownerOf(tokenId) != msg.sender) revert LilNounsEnsErrors.NotTokenOwner(tokenId);
    if (_tokenToNode[tokenId] != 0) revert LilNounsEnsErrors.AlreadyClaimed(tokenId);
    if (legacy.tokenHashmap(tokenId) != 0) revert LilNounsEnsErrors.AlreadyClaimed(tokenId);

    bytes32 labelHash = keccak256(abi.encodePacked(label));
    bytes32 node = keccak256(abi.encodePacked(rootNode, labelHash));

    // Reentrancy-safe: mutate storage before external call
    _tokenToNode[tokenId] = node;
    _nodeToToken[node] = tokenId;
    _nodeToLabel[node] = label;

    // ENS registry call — external, but safe and trusted
    ens.setSubnodeRecord(rootNode, labelHash, address(this), address(this), 0);

    /// @custom:slither-safe-event-after-call
    emit SubdomainClaimed(msg.sender, tokenId, node, label);
    /// @custom:slither-safe-event-after-call
    emit AddrChanged(node, msg.sender);
  }

  /// @notice Resets the resolver for a claimed subdomain
  /// @param tokenId Token ID with an associated subdomain
  function restoreResolver(uint256 tokenId) external {
    bytes32 node = _tokenToNode[tokenId];
    if (node == 0) revert LilNounsEnsErrors.UnregisteredNode(node);
    if (msg.sender != owner() && nft.ownerOf(tokenId) != msg.sender) {
      revert LilNounsEnsErrors.NotAuthorised(tokenId);
    }

    ens.setResolver(node, address(this));
  }

  /// @inheritdoc IAddrResolver
  function addr(bytes32 node) external view override returns (address payable) {
    uint256 tokenId = _nodeToToken[node];
    if (_tokenToNode[tokenId] == 0) revert LilNounsEnsErrors.UnregisteredNode(node);
    return payable(nft.ownerOf(tokenId));
  }

  /// @inheritdoc ITextResolver
  function text(bytes32 node, string calldata key) external view override returns (string memory) {
    uint256 tokenId = _nodeToToken[node];
    if (_tokenToNode[tokenId] == 0) revert LilNounsEnsErrors.UnregisteredNode(node);

    if (keccak256(bytes(key)) == keccak256("avatar")) {
      return string(abi.encodePacked("eip155:1/erc721:", _toChecksumString(address(nft)), "/", tokenId.toString()));
    }

    return _texts[node][key];
  }

  /// @inheritdoc INameResolver
  function name(bytes32 node) external view override returns (string memory) {
    string memory label = _nodeToLabel[node];
    if (bytes(label).length > 0) {
      return string(abi.encodePacked(label, ".", rootLabel, ".eth"));
    }
    return legacy.name(node); // fallback to legacy
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return
      interfaceId == type(IAddrResolver).interfaceId ||
      interfaceId == type(ITextResolver).interfaceId ||
      interfaceId == type(INameResolver).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }

  /// @notice Sets a text record (excluding "avatar")
  /// @param node ENS node
  /// @param key Key (e.g., "description")
  /// @param value Value of the text record
  function setText(bytes32 node, string calldata key, string calldata value) external {
    uint256 tokenId = _nodeToToken[node];
    if (_tokenToNode[tokenId] == 0) revert LilNounsEnsErrors.UnregisteredNode(node);
    if (msg.sender != owner() && nft.ownerOf(tokenId) != msg.sender) {
      revert LilNounsEnsErrors.NotAuthorised(tokenId);
    }
    if (keccak256(bytes(key)) == keccak256("avatar")) revert LilNounsEnsErrors.OverrideAvatarKey();

    _texts[node][key] = value;
    emit TextChanged(node, key, key);
  }

  /// @notice Migrates a V1 subdomain to V2
  /// @param tokenId NFT token ID to migrate
  function migrateSubdomainFromV1(uint256 tokenId) external onlyOwner {
    bytes32 node = legacy.tokenHashmap(tokenId);
    if (node == 0) revert LilNounsEnsErrors.UnregisteredNode(node);

    string memory label = legacy.hashToDomainMap(node);
    if (bytes(label).length == 0) revert LilNounsEnsErrors.UnregisteredNode(node);

    // Reentrancy-safe: mutate before ENS call
    _tokenToNode[tokenId] = node;
    _nodeToToken[node] = tokenId;
    _nodeToLabel[node] = label;

    ens.setSubnodeRecord(rootNode, keccak256(abi.encodePacked(label)), address(this), address(this), 0);

    /// @custom:slither-safe-event-after-call
    emit SubdomainClaimed(nft.ownerOf(tokenId), tokenId, node, label);
    /// @custom:slither-safe-event-after-call
    emit AddrChanged(node, nft.ownerOf(tokenId));
  }

  /// @notice Emits AddrChanged for one or more tokenIds
  /// @dev Useful for manual re-indexing by The Graph or Etherscan
  /// @param tokenIds List of token IDs to emit AddrChanged for
  function emitAddrEvents(uint256[] calldata tokenIds) external {
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      uint256 tokenId = tokenIds[i];
      emit AddrChanged(_tokenToNode[tokenId], nft.ownerOf(tokenId));
    }
  }

  /// @notice Emits TextChanged for one or more tokenIds
  /// @dev Useful to force reindexing of off-chain profiles
  /// @param tokenIds List of token IDs
  /// @param key The text key to re-emit
  function emitTextEvents(uint256[] calldata tokenIds, string calldata key) external {
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      emit TextChanged(_tokenToNode[tokenIds[i]], key, key);
    }
  }

  /// @inheritdoc UUPSUpgradeable
  function _authorizeUpgrade(address) internal override onlyOwner {}

  /// @dev Converts an address to a lowercase hex string
  /// @param input Address to convert
  /// @return checksummed Address string in hex format
  function _toChecksumString(address input) internal pure returns (string memory) {
    bytes memory alphabet = "0123456789abcdef";
    bytes20 data = bytes20(input);
    bytes memory str = new bytes(42);
    str[0] = "0";
    str[1] = "x";
    for (uint256 i = 0; i < 20; i++) {
      str[2 + i * 2] = alphabet[uint8(data[i] >> 4)];
      str[3 + i * 2] = alphabet[uint8(data[i] & 0x0f)];
    }
    return string(str);
  }
}
