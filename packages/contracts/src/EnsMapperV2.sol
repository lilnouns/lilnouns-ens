// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { ENS } from "@ensdomains/ens-contracts/registry/ENS.sol";
import { INameWrapper } from "@ensdomains/ens-contracts/wrapper/INameWrapper.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { IEnsMapper } from "./interfaces/IEnsMapper.sol";
import { IEnsMapperV2 } from "./interfaces/IEnsMapperV2.sol";

contract EnsMapperV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable, IEnsMapperV2 {
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
    address ensAddress,
    address nameWrapperAddress,
    address nftAddress,
    address oldMapperAddress,
    string memory label,
    bytes32 parentNode
  ) external initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();

    ens = ENS(ensAddress);
    nameWrapper = INameWrapper(nameWrapperAddress);
    nft = IERC721(nftAddress);
    old = IEnsMapper(oldMapperAddress);
    domainLabel = label;
    domainHash = parentNode;
  }

  function registerWrappedSubdomain(string calldata label, uint256 tokenId) external {
    if (nft.ownerOf(tokenId) != msg.sender) revert NotNFTOwner();

    bytes32 labelHash = keccak256(abi.encodePacked(label));
    bytes32 node = keccak256(abi.encodePacked(domainHash, labelHash));

    if (tokenIdToNode[tokenId] != bytes32(0)) revert AlreadyRegistered();
    if (ens.owner(node) != address(0)) revert RecordExists();

    nameWrapper.setSubnodeOwner(domainHash, label, msg.sender, 0, type(uint64).max);

    tokenIdToNode[tokenId] = node;
    nodeToTokenId[node] = tokenId;
    nodeToLabel[node] = label;

    emit RegisterSubdomain(msg.sender, tokenId, label);
  }

  function claimAndWrapLegacySubdomain(uint256 tokenId) external {
    if (nft.ownerOf(tokenId) != msg.sender) revert NotNFTOwner();

    bytes32 oldNode = old.tokenHashmap(tokenId);
    if (oldNode == bytes32(0)) revert NoOldNode();

    string memory label = old.hashToDomainMap(oldNode);
    if (bytes(label).length == 0) revert InvalidLabel();

    bytes32 labelHash = keccak256(abi.encodePacked(label));
    bytes32 newNode = keccak256(abi.encodePacked(domainHash, labelHash));

    if (tokenIdToNode[tokenId] != bytes32(0)) revert AlreadyMigrated();

    address currentEnsOwner = ens.owner(newNode);
    if (currentEnsOwner != address(0) && currentEnsOwner != msg.sender) revert SubdomainNotReclaimable();

    nameWrapper.setSubnodeOwner(domainHash, label, msg.sender, 0, type(uint64).max);

    tokenIdToNode[tokenId] = newNode;
    nodeToTokenId[newNode] = tokenId;
    nodeToLabel[newNode] = label;

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
      domains[i] = string(abi.encodePacked(nodeToLabel[node], ".", domainLabel, ".eth"));
    }
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
