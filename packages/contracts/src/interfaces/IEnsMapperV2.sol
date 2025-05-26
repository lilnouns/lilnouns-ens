// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

interface IEnsMapperV2 {
  function domainLabel() external view returns (string memory);
  function domainHash() external view returns (bytes32);
  function nodeToTokenId(bytes32 node) external view returns (uint256);
  function tokenIdToNode(uint256 tokenId) external view returns (bytes32);
  function nodeToLabel(bytes32 node) external view returns (string memory);
  function getTokenDomain(uint256 tokenId) external view returns (string memory);
  function getTokensDomains(uint256[] calldata tokenIds) external view returns (string[] memory);

  function registerWrappedSubdomain(string calldata label, uint256 tokenId) external;
  function claimAndWrapLegacySubdomain(uint256 tokenId) external;

  event RegisterSubdomain(address indexed registrar, uint256 indexed tokenId, string indexed label);
  event SubdomainMigrated(address indexed owner, uint256 indexed tokenId, string indexed label);

  error NotNFTOwner();
  error AlreadyRegistered();
  error RecordExists();
  error NoOldNode();
  error InvalidLabel();
  error AlreadyMigrated();
  error SubdomainNotReclaimable();
  error NotRegistered();
  error ZeroAddressNotAllowed();
  error EmptyLabelNotAllowed();
  error ZeroParentNodeNotAllowed();
}
