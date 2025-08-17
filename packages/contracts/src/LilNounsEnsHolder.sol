// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { ERC721HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import { ERC1155HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { LilNounsEnsErrors } from "./LilNounsEnsErrors.sol";

/// @title LilNounsEnsHolder
/// @notice Abstract, upgrade-friendly holder to safely receive and withdraw ERC-721 and ERC-1155 tokens for Lil Nouns ENS flows.
/// @dev
/// - Uses OZ upgradeable modules with initializer pattern so child contracts can be deployed behind proxies.
/// - Two-step ownership via Ownable2StepUpgradeable; only the owner may withdraw assets.
/// - Accepts safe transfers for ERC-721 and ERC-1155 via Holder helpers.
/**
 * @author LilNouns ENS Authors
 */
abstract contract LilNounsEnsHolder is
  Initializable,
  Ownable2StepUpgradeable,
  ReentrancyGuardUpgradeable,
  ERC721HolderUpgradeable,
  ERC1155HolderUpgradeable
{
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

  /// @notice Initializer to configure ownership and internal modules.
  /// @param initialOwner The initial owner address for the vault.
  // solhint-disable-next-line func-name-mixedcase
  function __LilNounsEnsHolder_init(address initialOwner) internal onlyInitializing {
    if (initialOwner == address(0)) revert LilNounsEnsErrors.ZeroAddress();

    // Initialize parents
    __Ownable_init(initialOwner);
    __Ownable2Step_init();
    __ReentrancyGuard_init();
    __ERC721Holder_init();
    __ERC1155Holder_init();

    __LilNounsEnsHolder_init_unchained();
  }

  /// @notice Optional unchained initializer (no parent initializers).
  // solhint-disable-next-line func-name-mixedcase, no-empty-blocks
  function __LilNounsEnsHolder_init_unchained() internal onlyInitializing {}

  /// @notice Withdraw an ERC-721 token held by the vault to a recipient.
  /// @param token The ERC-721 contract address.
  /// @param tokenId The token ID to withdraw.
  /// @param to The recipient address; must be nonzero.
  function withdrawERC721(address token, uint256 tokenId, address to) external virtual onlyOwner nonReentrant {
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
  ) external virtual onlyOwner nonReentrant {
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
  ) external virtual onlyOwner nonReentrant {
    if (to == address(0)) revert LilNounsEnsErrors.ZeroAddress();
    if (ids.length != amounts.length) revert LilNounsEnsErrors.LengthMismatch();
    IERC1155(token).safeBatchTransferFrom(address(this), to, ids, amounts, data);
    emit ERC1155BatchWithdrawn(token, to, ids, amounts, data);
  }

  /// @inheritdoc ERC1155HolderUpgradeable
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC1155HolderUpgradeable, ERC721HolderUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // Storage gap for upgradeability
  // solhint-disable-next-line var-name-mixedcase
  uint256[50] private __gap;
}
