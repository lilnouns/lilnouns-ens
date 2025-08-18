// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { LilNounsEnsBase } from "./LilNounsEnsBase.sol";
import { LilNounsEnsErrors } from "./LilNounsEnsErrors.sol";

/// @title LilNounsEnsWrapper
/// @notice Thin ENS NameWrapper helper using shared storage and modules from LilNounsEnsBase.
/// @author LilNouns ENS Contributors
import { ERC1155HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

abstract contract LilNounsEnsWrapper is LilNounsEnsBase, ERC1155HolderUpgradeable {
  /// @notice Emitted after a successful wrap of a .eth second-level domain.
  /// @param label The ASCII label used to wrap (not indexed).
  /// @param labelHash The keccak256 of the label (indexed).
  /// @param tokenId The ERC-721 tokenId in the Base Registrar (indexed).
  /// @param fuses The fuse configuration applied in the NameWrapper.
  /// @param expiry The expiry returned by NameWrapper.
  event EnsWrapped(string label, bytes32 indexed labelHash, uint256 indexed tokenId, uint32 fuses, uint64 expiry);

  /// @notice Emitted after unwrapping a .eth name back to the Base Registrar ERC-721.
  /// @param labelHash The keccak256 of the label (indexed).
  /// @param newRegistrant The new ERC-721 registrant in the Base Registrar (indexed).
  /// @param newController The controller to set for the name.
  event EnsUnwrapped(bytes32 indexed labelHash, address indexed newRegistrant, address newController);

  /// @notice Emitted when an approval is set on the Base Registrar tokenId.
  /// @param tokenId The ERC-721 token id (indexed).
  /// @param approved The approved operator address (indexed).
  event EnsApprovalSet(uint256 indexed tokenId, address indexed approved);

  /// @notice Wrap a .eth second-level domain held in the Base Registrar so the ERC-1155 is minted to this contract.
  /// @param label The ASCII label to wrap (e.g., "lilnouns").
  /// @param resolver The resolver address to set at wrap time.
  /// @param fuses NameWrapper fuse settings to apply (will be cast to uint16 as per INameWrapper).
  function wrapEnsName(
    string calldata label,
    address resolver,
    uint32 fuses
  ) external virtual onlyOwner nonReentrant whenNotPaused {
    if (bytes(label).length == 0) revert LilNounsEnsErrors.InvalidParams();

    bytes32 labelHash = keccak256(bytes(label));
    uint256 tokenId = uint256(labelHash);

    // Ensure NameWrapper is approved to transfer the ERC-721
    address currentOwner = address(0);
    try baseRegistrar.ownerOf(tokenId) returns (address o) {
      currentOwner = o;
    } catch {
      revert LilNounsEnsErrors.NotApproved(tokenId);
    }
    bool ok = false;
    if (currentOwner != address(0)) {
      try baseRegistrar.getApproved(tokenId) returns (address a) {
        if (a == address(nameWrapper)) ok = true;
      } catch {}
      if (!ok) {
        try baseRegistrar.isApprovedForAll(currentOwner, address(nameWrapper)) returns (bool isAll) {
          if (isAll) ok = true;
        } catch {}
      }
    }
    if (!ok) revert LilNounsEnsErrors.NotApproved(tokenId);

    uint64 expiry = nameWrapper.wrapETH2LD(label, address(this), uint16(fuses), resolver);
    emit EnsWrapped(label, labelHash, tokenId, fuses, expiry);
  }

  /// @notice Unwrap a previously wrapped .eth name back to the Base Registrar ERC-721.
  /// @param labelHash The keccak256 of the label being unwrapped.
  /// @param newRegistrant Address to receive the ERC-721 ownership in the Base Registrar.
  /// @param newController Address to be set as controller for the name.
  function unwrapEnsName(
    bytes32 labelHash,
    address newRegistrant,
    address newController
  ) external virtual onlyOwner nonReentrant whenNotPaused {
    if (labelHash == bytes32(0) || newRegistrant == address(0) || newController == address(0)) {
      revert LilNounsEnsErrors.InvalidParams();
    }
    nameWrapper.unwrapETH2LD(labelHash, newRegistrant, newController);
    emit EnsUnwrapped(labelHash, newRegistrant, newController);
  }

  /// @notice Approve an operator (e.g., NameWrapper) to manage the ERC-721 token in the Base Registrar.
  /// @param tokenId The .eth tokenId (uint256(keccak256(bytes(label)))).
  /// @param operator The operator to approve (commonly the NameWrapper address).
  function approveEnsName(uint256 tokenId, address operator) external virtual onlyOwner nonReentrant whenNotPaused {
    if (operator == address(0)) revert LilNounsEnsErrors.ZeroAddress();
    baseRegistrar.approve(operator, tokenId);
    emit EnsApprovalSet(tokenId, operator);
  }

  // slither-disable-next-line naming-convention
  uint256[47] private __gapWrapper;
}
