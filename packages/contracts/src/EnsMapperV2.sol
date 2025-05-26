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

contract EnsMapperV2 is
  Initializable,
  Ownable2StepUpgradeable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable,
  IEnsMapperV2
{
  // Custom error for unexpected node returned from nameWrapper
  error UnexpectedNodeReturned();

  ENS public ens;
  INameWrapper public nameWrapper;
  IERC721 public nft;
  IEnsMapper public old;

  string public domainLabel;
  bytes32 public domainHash;

  mapping(bytes32 => uint256) public nodeToTokenId;
  mapping(uint256 => bytes32) public tokenIdToNode;
  mapping(bytes32 => string) public nodeToLabel;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address initialOwner,
    address ensAddress,
    address nameWrapperAddress,
    address nftAddress,
    address oldMapperAddress,
    string memory label,
    bytes32 parentNode
  ) external initializer {
    __Ownable_init(initialOwner);
    __UUPSUpgradeable_init();
    __ReentrancyGuard_init();

    if (initialOwner == address(0)) revert ZeroAddressNotAllowed();
    if (ensAddress == address(0)) revert ZeroAddressNotAllowed();
    if (nameWrapperAddress == address(0)) revert ZeroAddressNotAllowed();
    if (nftAddress == address(0)) revert ZeroAddressNotAllowed();
    if (oldMapperAddress == address(0)) revert ZeroAddressNotAllowed();
    if (bytes(label).length == 0) revert EmptyLabelNotAllowed();
    if (parentNode == bytes32(0)) revert ZeroParentNodeNotAllowed();

    ens = ENS(ensAddress);
    nameWrapper = INameWrapper(nameWrapperAddress);
    nft = IERC721(nftAddress);
    old = IEnsMapper(oldMapperAddress);
    domainLabel = label;
    domainHash = parentNode;
  }

  function registerWrappedSubdomain(string calldata label, uint256 tokenId) external nonReentrant {
    if (nft.ownerOf(tokenId) != msg.sender) revert NotNFTOwner();
    if (bytes(label).length == 0) revert InvalidLabel();

    bytes32 labelHash = keccak256(abi.encodePacked(label));
    bytes32 node = keccak256(abi.encodePacked(domainHash, labelHash));

    if (tokenIdToNode[tokenId] != bytes32(0)) revert AlreadyRegistered();
    if (ens.owner(node) != address(0)) revert RecordExists();

    // Update state before external call
    tokenIdToNode[tokenId] = node;
    nodeToTokenId[node] = tokenId;
    nodeToLabel[node] = label;

    // Make external call after state update and capture the return value
    bytes32 createdNode = nameWrapper.setSubnodeOwner(domainHash, label, msg.sender, 0, type(uint64).max);

    // Verify the returned node matches our calculated node
    if (createdNode != node) revert UnexpectedNodeReturned();

    emit RegisterSubdomain(msg.sender, tokenId, label);
  }

  function claimAndWrapLegacySubdomain(uint256 tokenId) external nonReentrant {
    if (nft.ownerOf(tokenId) != msg.sender) revert NotNFTOwner();

    bytes32 oldNode = old.tokenHashmap(tokenId);
    if (oldNode == bytes32(0)) revert NoOldNode();

    string memory label = old.hashToDomainMap(oldNode);
    if (bytes(label).length == 0) revert InvalidLabel();

    bytes32 labelHash = keccak256(abi.encodePacked(label));
    bytes32 newNode = keccak256(abi.encodePacked(domainHash, labelHash));

    if (tokenIdToNode[tokenId] != bytes32(0)) revert AlreadyMigrated();

    address currentEnsOwner = ens.owner(newNode);
    if (currentEnsOwner != address(0) && currentEnsOwner != msg.sender) {
      revert SubdomainNotReclaimable();
    }

    // Update state before external call
    tokenIdToNode[tokenId] = newNode;
    nodeToTokenId[newNode] = tokenId;
    nodeToLabel[newNode] = label;

    // Make external call after state update and store the return value
    bytes32 createdNode = nameWrapper.setSubnodeOwner(domainHash, label, msg.sender, 0, type(uint64).max);

    // Verify the returned node matches our expected node
    if (createdNode != newNode) revert UnexpectedNodeReturned();

    emit SubdomainMigrated(msg.sender, tokenId, label);
    emit RegisterSubdomain(msg.sender, tokenId, label);
  }

  function getTokenDomain(uint256 tokenId) external view returns (string memory) {
    bytes32 node = tokenIdToNode[tokenId];
    if (node == bytes32(0)) revert NotRegistered();
    return string(abi.encodePacked(nodeToLabel[node], ".", domainLabel, ".eth"));
  }

  function getTokensDomains(uint256[] calldata tokenIds) external view returns (string[] memory domains) {
    uint256 len = tokenIds.length;
    domains = new string[](len);
    for (uint256 i = 0; i < len; ++i) {
      bytes32 node = tokenIdToNode[tokenIds[i]];
      if (node == bytes32(0)) {
        domains[i] = ""; // Empty string for unregistered tokens
      } else {
        domains[i] = string(abi.encodePacked(nodeToLabel[node], ".", domainLabel, ".eth"));
      }
    }
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
