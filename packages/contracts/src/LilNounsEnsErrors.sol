// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

/// @title LilNouns ENS Shared Errors
/// @notice Defines common custom errors used across LilNouns ENS contracts.
/// @dev Present tense, active voice. Prefer custom errors to save gas and enable tooling.
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
}
