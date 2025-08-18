// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

/// @title LilNouns ENS Shared Errors
/// @notice Defines common custom errors used across LilNouns ENS contracts.
/// @dev Present tense, active voice. Prefer custom errors to save gas and enable tooling.
/// @author LilNouns ENS Contributors
library LilNounsEnsErrors {
  /// @notice Thrown when a function receives the zero address for a required parameter.
  error ZeroAddress();

  /// @notice Thrown when an amount is invalid (e.g., zero where a positive value is required).
  error InvalidAmount();

  /// @notice Thrown when two arrays are expected to have the same length but do not.
  error LengthMismatch();

  /// @notice Thrown when ENS-related contracts are misconfigured or inconsistent.
  error MisconfiguredENS();

  /// @notice Thrown when a required approval is missing for a token operation.
  /// @dev Includes the tokenId to aid debugging.
  /// @param tokenId The ERC-721 token id related to the operation.
  error NotApproved(uint256 tokenId);

  /// @notice Thrown when input parameters are invalid (e.g., empty label or zero values).
  error InvalidParams();

  /// @notice Thrown when caller is not authorized to perform the action
  /// @dev Authorization requires being either the contract owner or the NFT owner
  error NotAuthorised();

  /// @notice Thrown when trying to resolve a node that doesn't exist
  error UnknownNode();

  /// @notice Thrown when attempting to claim a subdomain that's already claimed
  error AlreadyClaimed();

  /// @notice Thrown when trying to modify the locked avatar text record
  /// @dev Avatar records are automatically generated and cannot be manually set
  error AvatarLocked();

  /// @notice Thrown when receiving an unexpected ERC1155 batch transfer
  error Unexpected1155Batch();

  /// @notice Thrown when receiving an unexpected ERC1155 token
  error Unexpected1155Token();

  /// @notice Thrown when querying information for an unregistered token
  error UnregisteredToken();

  /// @notice Thrown when trying to import legacy data that doesn't exist or is already imported
  error NothingToImport();

  /// @notice Thrown when ENS subnode record creation fails
  error SubnodeRecordFailed();

  /// @notice Thrown when providing an empty label for subdomain registration
  error EmptyLabel();

  /// @notice Thrown when providing an empty key for text record operations
  error EmptyKey();

  /// @notice Thrown when providing an empty array to functions that require non-empty arrays
  error EmptyArray();

  /// @notice Thrown when initializing with an invalid legacy contract address
  error InvalidLegacyAddress();

  /// @notice Thrown when a scheduled pause window is active and prevents unpausing or execution
  error PauseWindowActive();
}
