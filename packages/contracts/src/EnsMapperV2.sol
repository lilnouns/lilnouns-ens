// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { ENS } from "@ensdomains/ens-contracts/registry/ENS.sol";
import { INameWrapper } from "@ensdomains/ens-contracts/wrapper/INameWrapper.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { IEnsMapper } from "./interfaces/IEnsMapper.sol";
import { IEnsMapperV2 } from "./interfaces/IEnsMapperV2.sol";

/// @title ENS Mapper V2
/// @notice Maps NFT token IDs to ENS subdomains and vice versa
/// @dev Implements IEnsMapperV2 interface and provides functionality for managing ENS subdomains
///      Uses ENS NameWrapper for subdomain management and supports migration from legacy ENS Mapper
contract EnsMapperV2 is
  Initializable,
  Ownable2StepUpgradeable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable,
  IEnsMapperV2
{
  /// @notice ENS registry contract
  ENS public ens;

  /// @notice ENS NameWrapper contract
  INameWrapper public nameWrapper;

  /// @notice NFT contract whose tokens are mapped to domains
  IERC721 public nft;

  /// @notice Legacy ENS Mapper contract
  IEnsMapper public old;

  /// @notice Base domain label (e.g., "lilnouns")
  string public domainLabel;

  /// @notice Namehash of the parent domain
  bytes32 public domainHash;

  /// @notice Mapping from ENS node to token ID
  mapping(bytes32 => uint256) public nodeToTokenId;

  /// @notice Mapping from token ID to ENS node
  mapping(uint256 => bytes32) public tokenIdToNode;

  /// @notice Mapping from ENS node to label
  mapping(bytes32 => string) public nodeToLabel;

  /// @custom:oz-upgrades-unsafe-allow constructor
  /// @notice Constructor that disables initializers to prevent implementation contract initialization
  constructor() {
    _disableInitializers();
  }

  /// @notice Initializes the contract with required parameters
  /// @dev This function replaces the constructor for upgradeable contracts
  /// @param initialOwner Address of the initial owner of the contract
  /// @param ensAddress Address of the ENS registry contract
  /// @param nameWrapperAddress Address of the ENS NameWrapper contract
  /// @param nftAddress Address of the NFT contract
  /// @param oldMapperAddress Address of the legacy ENS Mapper contract
  /// @param label Base domain label (e.g., "lilnouns")
  /// @param parentNode Namehash of the parent domain
  function initialize(
    address initialOwner,
    address ensAddress,
    address nameWrapperAddress,
    address nftAddress,
    address oldMapperAddress,
    string calldata label,
    bytes32 parentNode
  ) external initializer {
    // Validate inputs before state changes to save gas on revert
    if (
      initialOwner == address(0) ||
      ensAddress == address(0) ||
      nameWrapperAddress == address(0) ||
      nftAddress == address(0) ||
      oldMapperAddress == address(0)
    ) revert ZeroAddressNotAllowed();
    if (bytes(label).length == 0) revert EmptyLabelNotAllowed();
    if (parentNode == bytes32(0)) revert ZeroParentNodeNotAllowed();

    // Initialize OpenZeppelin upgradeable contracts
    __Ownable_init(initialOwner);
    __UUPSUpgradeable_init();
    __ReentrancyGuard_init();

    // Set state variables
    ens = ENS(ensAddress);
    nameWrapper = INameWrapper(nameWrapperAddress);
    nft = IERC721(nftAddress);
    old = IEnsMapper(oldMapperAddress);
    domainLabel = label;
    domainHash = parentNode;
  }

  /// @notice Registers a new wrapped subdomain for a token
  /// @dev Associates a token ID with an ENS subdomain and wraps it using ENS NameWrapper
  /// @param label The subdomain label to register
  /// @param tokenId The token ID to associate with the subdomain
  function registerWrappedSubdomain(string calldata label, uint256 tokenId) external nonReentrant {
    // Validate input parameters first
    if (bytes(label).length == 0) revert InvalidLabel();
    if (nft.ownerOf(tokenId) != msg.sender) revert NotNFTOwner();
    if (tokenIdToNode[tokenId] != bytes32(0)) revert AlreadyRegistered();

    // Calculate hashes
    bytes32 labelHash = keccak256(abi.encodePacked(label));
    bytes32 node = keccak256(abi.encodePacked(domainHash, labelHash));

    // Check for existing ENS record
    if (ens.owner(node) != address(0)) revert RecordExists();

    // Update state before external call
    tokenIdToNode[tokenId] = node;
    nodeToTokenId[node] = tokenId;
    nodeToLabel[node] = label;

    // Make external call after state update and verify return value
    bytes32 createdNode = nameWrapper.setSubnodeOwner(domainHash, label, msg.sender, 0, type(uint64).max);
    if (createdNode != node) revert UnexpectedNodeReturned();

    emit RegisterSubdomain(msg.sender, tokenId, label);
  }

  /// @notice Claims and wraps a legacy subdomain for a token
  /// @dev Migrates a subdomain from the legacy ENS Mapper to this contract
  /// @param tokenId The token ID associated with the legacy subdomain
  function claimAndWrapLegacySubdomain(uint256 tokenId) external nonReentrant {
    // Check ownership first
    if (nft.ownerOf(tokenId) != msg.sender) revert NotNFTOwner();
    if (tokenIdToNode[tokenId] != bytes32(0)) revert AlreadyMigrated();

    // Get legacy data
    bytes32 oldNode = old.tokenHashmap(tokenId);
    if (oldNode == bytes32(0)) revert NoOldNode();

    string memory label = old.hashToDomainMap(oldNode);
    if (bytes(label).length == 0) revert InvalidLabel();

    // Calculate new node
    bytes32 labelHash = keccak256(abi.encodePacked(label));
    bytes32 newNode = keccak256(abi.encodePacked(domainHash, labelHash));

    // Check if domain is reclaimable
    address currentEnsOwner = ens.owner(newNode);
    if (currentEnsOwner != address(0) && currentEnsOwner != msg.sender) {
      revert SubdomainNotReclaimable();
    }

    // Update state in a single code block
    tokenIdToNode[tokenId] = newNode;
    nodeToTokenId[newNode] = tokenId;
    nodeToLabel[newNode] = label;

    // Make external call and verify return value
    bytes32 createdNode = nameWrapper.setSubnodeOwner(domainHash, label, msg.sender, 0, type(uint64).max);
    if (createdNode != newNode) revert UnexpectedNodeReturned();

    // Emit events
    emit SubdomainMigrated(msg.sender, tokenId, label);
    emit RegisterSubdomain(msg.sender, tokenId, label);
  }

  /// @notice Gets the full domain name for a token
  /// @dev Constructs the full domain name from the subdomain label, domain label, and ".eth"
  /// @param tokenId The token ID to get the domain for
  /// @return The full domain name (e.g., "subdomain.lilnouns.eth")
  function getTokenDomain(uint256 tokenId) external view returns (string memory) {
    bytes32 node = tokenIdToNode[tokenId];
    if (node == bytes32(0)) revert NotRegistered();

    string memory label = nodeToLabel[node];
    return string(abi.encodePacked(label, ".", domainLabel, ".eth"));
  }

  /// @notice Gets the full domain names for multiple tokens
  /// @dev Batch version of getTokenDomain to reduce gas costs for multiple lookups
  /// @param tokenIds Array of token IDs to get domains for
  /// @return domains Array of domain names corresponding to the token IDs
  function getTokensDomains(uint256[] calldata tokenIds) external view returns (string[] memory domains) {
    uint256 len = tokenIds.length;
    domains = new string[](len);

    // Cache the domain suffix to avoid repeated string operations
    string memory suffix = string(abi.encodePacked(".", domainLabel, ".eth"));

    for (uint256 i = 0; i < len; ) {
      bytes32 node = tokenIdToNode[tokenIds[i]];
      if (node == bytes32(0)) {
        domains[i] = ""; // Empty string for unregistered tokens
      } else {
        domains[i] = string(abi.encodePacked(nodeToLabel[node], suffix));
      }

      // Use unchecked to save gas on increment as it cannot overflow
      unchecked {
        ++i;
      }
    }
  }

  /// @notice Authorizes an upgrade to a new implementation
  /// @dev Required by UUPSUpgradeable contract
  /// @param newImplementation Address of the new implementation contract
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
