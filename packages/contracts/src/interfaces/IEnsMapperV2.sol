// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

/// @title ENS Mapper V2 Interface
/// @notice Interface for the ENS Mapper V2 contract that maps ENS subdomains to token IDs
/// @dev This interface provides methods for domain management and token-to-node mappings
interface IEnsMapperV2 {
  /// @notice Returns the base domain label
  /// @return The domain label string
  function domainLabel() external view returns (string memory);

  /// @notice Returns the namehash of the base domain
  /// @return The domain namehash as bytes32
  function domainHash() external view returns (bytes32);

  /// @notice Maps an ENS node to a token ID
  /// @param node The ENS node (namehash)
  /// @return The corresponding token ID
  function nodeToTokenId(bytes32 node) external view returns (uint256);

  /// @notice Maps a token ID to an ENS node
  /// @param tokenId The token ID
  /// @return The corresponding ENS node (namehash)
  function tokenIdToNode(uint256 tokenId) external view returns (bytes32);

  /// @notice Gets the label for a given ENS node
  /// @param node The ENS node (namehash)
  /// @return The subdomain label string
  function nodeToLabel(bytes32 node) external view returns (string memory);

  /// @notice Gets the full domain name for a given token ID
  /// @param tokenId The token ID
  /// @return The full domain name string (e.g., "example.eth")
  function getTokenDomain(uint256 tokenId) external view returns (string memory);

  /// @notice Gets multiple full domain names for an array of token IDs
  /// @param tokenIds Array of token IDs
  /// @return An array of domain name strings corresponding to the token IDs
  function getTokensDomains(uint256[] calldata tokenIds) external view returns (string[] memory);

  /// @notice Registers a wrapped subdomain for a token
  /// @param label The subdomain label to register
  /// @param tokenId The token ID to associate with the subdomain
  function registerWrappedSubdomain(string calldata label, uint256 tokenId) external;

  /// @notice Claims and wraps a legacy subdomain for a token
  /// @param tokenId The token ID to associate with the legacy subdomain
  function claimAndWrapLegacySubdomain(uint256 tokenId) external;

  /// @notice Emitted when a subdomain is registered
  /// @param registrar Address of the account registering the subdomain
  /// @param tokenId Token ID associated with the subdomain
  /// @param label The subdomain label that was registered
  event RegisterSubdomain(address indexed registrar, uint256 indexed tokenId, string indexed label);

  /// @notice Emitted when a subdomain is migrated from legacy system
  /// @param owner Address of the owner of the migrated subdomain
  /// @param tokenId Token ID associated with the migrated subdomain
  /// @param label The subdomain label that was migrated
  event SubdomainMigrated(address indexed owner, uint256 indexed tokenId, string indexed label);

  /// @notice Error thrown when an operation is attempted by someone who is not the NFT owner
  error NotNFTOwner();

  /// @notice Error thrown when attempting to register a subdomain that is already registered
  error AlreadyRegistered();

  /// @notice Error thrown when a record already exists for the given parameters
  error RecordExists();

  /// @notice Error thrown when no old node exists during migration
  error NoOldNode();

  /// @notice Error thrown when an invalid label is provided
  error InvalidLabel();

  /// @notice Error thrown when attempting to migrate a subdomain that is already migrated
  error AlreadyMigrated();

  /// @notice Error thrown when a subdomain cannot be reclaimed
  error SubdomainNotReclaimable();

  /// @notice Error thrown when attempting to access a subdomain that is not registered
  error NotRegistered();

  /// @notice Error thrown when a zero address is provided where not allowed
  error ZeroAddressNotAllowed();

  /// @notice Error thrown when an empty label is provided
  error EmptyLabelNotAllowed();

  /// @notice Error thrown when a zero parent node is provided where not allowed
  error ZeroParentNodeNotAllowed();

  /// @notice Custom error for unexpected node returned from nameWrapper
  error UnexpectedNodeReturned();
}
