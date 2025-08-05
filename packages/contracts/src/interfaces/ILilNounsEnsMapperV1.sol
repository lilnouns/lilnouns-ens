// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

/**
 * @title ILilNounsEnsMapperV1
 * @notice Interface for mapping Lil Nouns tokens to ENS domains and associated metadata
 * @dev This interface provides bidirectional mapping between token IDs, hashes, and ENS domains
 */
interface ILilNounsEnsMapperV1 {
  /**
   * @notice Get the hash associated with a specific token ID
   * @param tokenId The token ID to look up
   * @return The bytes32 hash associated with the token
   */
  function tokenHashmap(uint256 tokenId) external view returns (bytes32);

  /**
   * @notice Get the token ID associated with a specific hash
   * @param hash The hash to look up
   * @return The token ID associated with the hash
   */
  function hashToIdMap(bytes32 hash) external view returns (uint256);

  /**
   * @notice Get the ENS domain name associated with a specific hash
   * @param hash The hash to look up
   * @return The domain name string associated with the hash
   */
  function hashToDomainMap(bytes32 hash) external view returns (string memory);

  /**
   * @notice Get text record data for a specific hash and key
   * @param node The hash/node to look up text records for
   * @param key The text record key to retrieve
   * @return The text record value associated with the node and key
   */
  function texts(bytes32 node, string calldata key) external view returns (string memory);
}
