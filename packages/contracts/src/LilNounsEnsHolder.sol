// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { LilNounsEnsErrors } from "./LilNounsEnsErrors.sol";
import { LilNounsEnsBase } from "./LilNounsEnsBase.sol";
import { ERC721HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import { ERC1155HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

/// @title LilNounsEnsHolder
/// @notice Thin holder that relies on LilNounsEnsBase for upgradeability, access control, pausing, and receivers.
/// @dev Avoids re-importing OZ modules; delegates to base for security and lifecycle.
/// @author LilNouns ENS Contributors
abstract contract LilNounsEnsHolder is LilNounsEnsBase, ERC721HolderUpgradeable, ERC1155HolderUpgradeable {
  /// @notice Emitted when an ERC-721 token is withdrawn from the vault.
  /// @param token The ERC-721 contract address.
  /// @param tokenId The token ID being withdrawn.
  /// @param to The recipient address.
  event ERC721Withdrawn(address indexed token, uint256 indexed tokenId, address indexed to);

  /// @notice Emitted when an ERC-1155 token is withdrawn from the vault.
  /// @param token The ERC-1155 contract address.
  /// @param id The token ID being withdrawn.
  /// @param to The recipient address.
  /// @param amount The amount withdrawn.
  /// @param data Additional data forwarded to the token contract.
  event ERC1155Withdrawn(address indexed token, uint256 indexed id, address indexed to, uint256 amount, bytes data);

  /// @notice Emitted when multiple ERC-1155 tokens are withdrawn from the vault.
  /// @param token The ERC-1155 contract address.
  /// @param to The recipient address.
  /// @param ids The token IDs being withdrawn.
  /// @param amounts The amounts withdrawn for each token ID.
  /// @param data Additional data forwarded to the token contract.
  event ERC1155BatchWithdrawn(address indexed token, address indexed to, uint256[] ids, uint256[] amounts, bytes data);

  /// @notice Withdraw an ERC-721 token held by the vault to a recipient.
  /// @param token The ERC-721 contract address.
  /// @param tokenId The token ID to withdraw.
  /// @param to The recipient address; must be nonzero.
  function withdrawERC721(
    address token,
    uint256 tokenId,
    address to
  ) external virtual onlyOwner nonReentrant whenNotPaused {
    if (to == address(0)) revert LilNounsEnsErrors.ZeroAddress();
    IERC721(token).safeTransferFrom(address(this), to, tokenId);
    emit ERC721Withdrawn(token, tokenId, to);
  }

  /// @notice Withdraw a specific amount of an ERC-1155 token held by the vault to a recipient.
  /// @param token The ERC-1155 contract address.
  /// @param id The token ID to withdraw.
  /// @param amount The amount to withdraw; must be > 0.
  /// @param to The recipient address; must be nonzero.
  /// @param data Additional data to pass to the token contract.
  function withdrawERC1155(
    address token,
    uint256 id,
    uint256 amount,
    address to,
    bytes calldata data
  ) external virtual onlyOwner nonReentrant whenNotPaused {
    if (to == address(0)) revert LilNounsEnsErrors.ZeroAddress();
    if (amount == 0) revert LilNounsEnsErrors.InvalidAmount();
    IERC1155(token).safeTransferFrom(address(this), to, id, amount, data);
    emit ERC1155Withdrawn(token, id, to, amount, data);
  }

  /// @notice Withdraw multiple ERC-1155 token IDs in a single operation.
  /// @param token The ERC-1155 contract address.
  /// @param ids The token IDs to withdraw.
  /// @param amounts The amounts to withdraw for each token ID.
  /// @param to The recipient address; must be nonzero.
  /// @param data Additional data to pass to the token contract.
  function withdrawERC1155Batch(
    address token,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    address to,
    bytes calldata data
  ) external virtual onlyOwner nonReentrant whenNotPaused {
    if (to == address(0)) revert LilNounsEnsErrors.ZeroAddress();
    if (ids.length != amounts.length) revert LilNounsEnsErrors.LengthMismatch();
    IERC1155(token).safeBatchTransferFrom(address(this), to, ids, amounts, data);
    emit ERC1155BatchWithdrawn(token, to, ids, amounts, data);
  }

  // Storage gap preserved for future extensions in this child
  // slither-disable-next-line naming-convention
  uint256[50] private __gapHolder;
}
