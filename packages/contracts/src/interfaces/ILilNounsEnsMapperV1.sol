// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title ILilNounsEnsMapperV1
/// @notice Interface for the legacy ENS mapper contract used by Lil Nouns.
/// @dev Provides read access to subdomain mappings and ENS resolver data.
interface ILilNounsEnsMapperV1 {
  /// @notice Returns the NFT contract associated with the ENS records
  function nft() external view returns (IERC721);

  /// @notice Returns the ENS domain hash (namehash of the root domain, e.g., "lilnouns.eth")
  function domainHash() external view returns (bytes32);

  /// @notice Get the ENS name for a given node (namehash).
  /// @param node The ENS node (e.g., namehash of "noun42.lilnouns.eth")
  /// @return The ENS name string (e.g., "noun42.lilnouns.eth"), or empty string if unregistered.
  function name(bytes32 node) external view returns (string memory);

  /// @notice Get the current address owner associated with a node.
  /// @dev Resolves to the current owner of the linked ERC721 token.
  /// @param node The ENS node to resolve.
  /// @return The address of the NFT owner.
  function addr(bytes32 node) external view returns (address);

  /// @notice Returns a custom text record for a given node.
  /// @dev Special-cased for key = "avatar".
  /// @param node ENS node
  /// @param key The text record key (e.g., "avatar", "description")
  /// @return The associated text value.
  function text(bytes32 node, string calldata key) external view returns (string memory);

  /// @notice Get the ENS nodehash associated with a given tokenId.
  /// @dev Returns 0x0 if the token does not have a registered subdomain.
  /// @param tokenId Token ID of the NFT.
  /// @return The node (namehash) of the subdomain.
  function tokenHashmap(uint256 tokenId) external view returns (bytes32);

  /// @notice Get the tokenId associated with a given node.
  /// @param node ENS node (namehash)
  /// @return The ERC721 tokenId linked to the subdomain.
  function hashToIdMap(bytes32 node) external view returns (uint256);

  /// @notice Get the label (e.g., "noun42") mapped to a node.
  /// @param node ENS node (namehash)
  /// @return The label originally claimed.
  function hashToDomainMap(bytes32 node) external view returns (string memory);
}
