// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

/// @title LilNounsEnsErrors
/// @notice Custom errors used by LilNounsEnsMapperV2 and related ENS subdomain/resolver contracts.
/// @dev All errors are defined in this reusable library for gas efficiency and modularity.
library LilNounsEnsErrors {
  /**
   * @notice Reverts when an invalid address is provided for the legacy V1 contract.
   */
  error InvalidLegacyAddress();

  /**
   * @notice Reverts when an invalid address is provided for the ENS registry.
   */
  error InvalidENSRegistry();

  /**
   * @notice Reverts when the caller is not the owner of the specified tokenId.
   * @param tokenId The ERC721 tokenId in question.
   */
  error NotTokenOwner(uint256 tokenId);

  /**
   * @notice Reverts when a token already has a claimed subdomain in V1 or V2.
   * @param tokenId The tokenId that already has a subdomain claimed.
   */
  error AlreadyClaimed(uint256 tokenId);

  /**
   * @notice Reverts when an operation is attempted on an ENS node that has not been registered.
   * @param node The ENS namehash of the node.
   */
  error UnregisteredNode(bytes32 node);

  /**
   * @notice Reverts when the caller is neither the contract owner nor the NFT token holder.
   * @param tokenId The tokenId for which the authorization failed.
   */
  error NotAuthorised(uint256 tokenId);

  /**
   * @notice Reverts when an attempt is made to overwrite the 'avatar' text record.
   * @dev 'avatar' is reserved and hardcoded via the addr() function for consistency with EIP-155.
   */
  error OverrideAvatarKey();
}
