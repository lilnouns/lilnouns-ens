// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

/// @title ENS Mapper Interface
/// @notice Interface for the legacy ENS Mapper contract that maps token IDs to ENS nodes
/// @dev This interface defines the core mapping functions between tokens and ENS domains
interface IEnsMapper {
  /// @notice Maps a token ID to its corresponding ENS node hash
  /// @param tokenId The ID of the token
  /// @return The ENS node (namehash) associated with the token ID
  function tokenHashmap(uint256 tokenId) external view returns (bytes32);

  /// @notice Maps an ENS node to its domain label
  /// @param node The ENS node (namehash)
  /// @return The domain label string associated with the node
  function hashToDomainMap(bytes32 node) external view returns (string memory);
}
