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

/**
 * @title LilNounsEnsMapperV2
 * @notice Upgradeable ENS resolver and controller for Lil Nouns NFTs.
 * @dev Uses UUPS upgrade ability. Implements IAddrResolver, ITextResolver, INameResolver.
 */
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

  /// @notice ENS registry
  ENS public ens;

  /// @notice Legacy V1 ENS mapping contract
  ILilNounsEnsMapperV1 public legacy;

  /// @notice ERC721 contract for Lil Nouns
  IERC721 public nft;

  /// @notice ENS node hash for the root domain (namehash of "lilnouns.eth")
  bytes32 public rootNode;

  /// @notice Human-readable label for root domain
  string public rootLabel;

  /// @dev tokenId => ENS node
  mapping(uint256 => bytes32) private _tokenToNode;

  /// @dev ENS node => tokenId
  mapping(bytes32 => uint256) private _nodeToToken;

  /// @dev ENS node => label
  mapping(bytes32 => string) private _nodeToLabel;

  /// @dev ENS node => text records
  mapping(bytes32 => mapping(string => string)) private _texts;

  /// @notice Emitted when a subdomain is claimed
  event SubdomainClaimed(address indexed registrar, uint256 indexed tokenId, bytes32 indexed node, string label);

  /// @notice Emitted when a text record is changed
  event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

  /**
   * @notice Initializes the contract with ENS and legacy registry data
   * @param legacyAddr Address of LilNounsEnsMapperV1
   * @param ensRegistry Address of ENS registry
   * @param ensRoot ENS node of "lilnouns.eth"
   * @param labelRoot Human-readable label ("lilnouns")
   */
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

  /**
   * @notice Claims a subdomain and assigns this contract as resolver and controller
   * @param label Desired ENS label (e.g., "noun42")
   * @param tokenId NFT tokenId to link
   */
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

    emit SubdomainClaimed(msg.sender, tokenId, node, label);
    emit AddrChanged(node, msg.sender);
  }

  /**
   * @notice Restores this contract as the resolver for a node
   * @param tokenId Token with registered subdomain
   */
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

  /**
   * @notice Sets a text record for a node (except "avatar")
   * @param node ENS node
   * @param key Record key (e.g., "description")
   * @param value Record value
   */
  function setText(bytes32 node, string calldata key, string calldata value) external {
    uint256 tokenId = _nodeToToken[node];
    if (_tokenToNode[tokenId] == 0) revert LilNounsEnsErrors.UnregisteredNode(node);
    if (msg.sender != owner() && nft.ownerOf(tokenId) != msg.sender) {
      revert LilNounsEnsErrors.NotAuthorised(tokenId);
    }
    if (keccak256(bytes(key)) == keccak256("avatar")) {
      revert LilNounsEnsErrors.OverrideAvatarKey();
    }

    _texts[node][key] = value;
    emit TextChanged(node, key, key);
  }

  /**
   * @notice Migrates a subdomain from V1 into V2
   * @param tokenId Token ID with an existing V1 subdomain
   */
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

    emit SubdomainClaimed(nft.ownerOf(tokenId), tokenId, node, label);
    emit AddrChanged(node, nft.ownerOf(tokenId));
  }

  /**
   * @notice Emits AddrChanged events for off-chain indexing
   * @dev Warning: calls `nft.ownerOf` inside a loop. Validate input length.
   */
  function emitAddrEvents(uint256[] calldata tokenIds) external {
    for (uint256 i; i < tokenIds.length; ++i) {
      bytes32 node = _tokenToNode[tokenIds[i]];
      emit AddrChanged(node, nft.ownerOf(tokenIds[i]));
    }
  }

  /**
   * @notice Emits TextChanged for multiple nodes (off-chain reindex)
   */
  function emitTextEvents(uint256[] calldata tokenIds, string calldata key) external {
    for (uint256 i; i < tokenIds.length; ++i) {
      bytes32 node = _tokenToNode[tokenIds[i]];
      emit TextChanged(node, key, key);
    }
  }

  /// @dev Authorizes UUPS upgrade (onlyOwner)
  function _authorizeUpgrade(address) internal override onlyOwner {}

  /// @dev Converts address to lowercase hex string (non-checksummed)
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
