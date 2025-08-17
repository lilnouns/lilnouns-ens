// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { ERC721HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import { ERC1155HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { ENS } from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import { INameWrapper } from "@ensdomains/ens-contracts/contracts/wrapper/INameWrapper.sol";
import { IBaseRegistrar } from "@ensdomains/ens-contracts/contracts/ethregistrar/IBaseRegistrar.sol";

/// @title LilNounsEnsWrapper
/// @notice Abstract, upgradeable base to expose ENS NameWrapper flows for inheriting NFT-holding contracts.
/// @dev
/// - Uses OZ upgradeable modules and an internal initializer so children can initialize ENS addresses.
/// - Callable by other contracts; avoids EOA-only assumptions.
/// - Exposes wrap and unwrap flows for .eth 2LDs via the official NameWrapper/Base Registrar.
/// - Provides a helper to set Base Registrar approvals.
abstract contract LilNounsEnsWrapper is
  Initializable,
  Ownable2StepUpgradeable,
  ReentrancyGuardUpgradeable,
  ERC721HolderUpgradeable,
  ERC1155HolderUpgradeable
{
  // ---------------------------
  // Errors
  // ---------------------------
  error ZeroAddress();
  error MisconfiguredENS();
  error NotApproved(uint256 tokenId);
  error InvalidParams();

  // ---------------------------
  // Events
  // ---------------------------
  event EnsWrapped(string label, bytes32 labelhash, uint256 tokenId, uint32 fuses, uint64 expiry);
  event EnsUnwrapped(bytes32 labelhash, address newRegistrant, address newController);
  event EnsContractsUpdated(address ens, address baseRegistrar, address nameWrapper);
  event EnsApprovalSet(uint256 tokenId, address approved);

  // ---------------------------
  // Storage
  // ---------------------------
  ENS public ens;
  IBaseRegistrar public baseRegistrar;
  INameWrapper public nameWrapper;

  // ---------------------------
  // Initializer (internal)
  // ---------------------------
  /// @notice Internal initializer. Must be called by inheriting contract's initializer.
  /// @param _ens ENS registry address (nonzero)
  /// @param _baseRegistrar Base Registrar address (nonzero)
  /// @param _nameWrapper NameWrapper address (nonzero)
  function __LilNounsEnsWrapper_init(
    ENS _ens,
    IBaseRegistrar _baseRegistrar,
    INameWrapper _nameWrapper
  ) internal onlyInitializing {
    if (address(_ens) == address(0) || address(_baseRegistrar) == address(0) || address(_nameWrapper) == address(0)) {
      revert ZeroAddress();
    }

    // Sanity check that the NameWrapper is wired to the provided ENS and Base Registrar.
    // If the implementation doesn't expose these getters, we consider it misconfigured for this system.
    // Using try/catch to defensively handle unexpected implementations.
    try _nameWrapper.ens() returns (address reportedEns) {
      if (reportedEns == address(0) || reportedEns != address(_ens)) revert MisconfiguredENS();
    } catch {
      revert MisconfiguredENS();
    }
    try _nameWrapper.registrar() returns (address reportedRegistrar) {
      if (reportedRegistrar == address(0) || reportedRegistrar != address(_baseRegistrar)) {
        revert MisconfiguredENS();
      }
    } catch {
      revert MisconfiguredENS();
    }
    ens = _ens;
    baseRegistrar = _baseRegistrar;
    nameWrapper = _nameWrapper;
  }

  // ---------------------------
  // Admin setters
  // ---------------------------
  /// @notice Rotate ENS-related contract addresses with sanity checks.
  /// @dev Owner-only to support upgrades or migrations of ENS contracts.
  function setEnsContracts(ENS _ens, IBaseRegistrar _baseRegistrar, INameWrapper _nameWrapper) external onlyOwner {
    if (address(_ens) == address(0) || address(_baseRegistrar) == address(0) || address(_nameWrapper) == address(0)) {
      revert ZeroAddress();
    }

    // Re-run sanity checks against the provided NameWrapper
    try _nameWrapper.ens() returns (address reportedEns) {
      if (reportedEns == address(0) || reportedEns != address(_ens)) revert MisconfiguredENS();
    } catch {
      revert MisconfiguredENS();
    }
    try _nameWrapper.registrar() returns (address reportedRegistrar) {
      if (reportedRegistrar == address(0) || reportedRegistrar != address(_baseRegistrar)) {
        revert MisconfiguredENS();
      }
    } catch {
      revert MisconfiguredENS();
    }
    ens = _ens;
    baseRegistrar = _baseRegistrar;
    nameWrapper = _nameWrapper;

    emit EnsContractsUpdated(address(_ens), address(_baseRegistrar), address(_nameWrapper));
  }

  // ---------------------------
  // Primary external methods
  // ---------------------------
  /// @notice Wrap a .eth second-level domain held in the Base Registrar so the ERC-1155 is minted to this contract.
  /// @dev
  /// - Computes tokenId via keccak256(label), as used by the .eth Base Registrar.
  /// - Performs optional preflight to ensure NameWrapper is properly approved to transfer the token.
  /// - Emits EnsWrapped and calls the internal hook.
  /// @param label The ASCII label to wrap (e.g., "lilnouns").
  /// @param resolver The resolver address to set at wrap time.
  /// @param fuses NameWrapper fuse settings to apply.
  /// @param expiry Expiry timestamp to use respecting NameWrapper rules.
  function wrapEnsName(
    string calldata label,
    address resolver,
    uint32 fuses,
    uint64 expiry
  ) external virtual onlyOwner nonReentrant {
    if (bytes(label).length == 0) revert InvalidParams();

    bytes32 labelhash = keccak256(bytes(label));
    uint256 tokenId = uint256(labelhash);

    // Optional preflight: ensure NameWrapper is approved for this tokenId by the current owner.
    address currentOwner;
    try baseRegistrar.ownerOf(tokenId) returns (address o) {
      currentOwner = o;
    } catch {
      revert NotApproved(tokenId);
    }
    bool ok;
    if (currentOwner != address(0)) {
      // Either explicit token approval to NameWrapper or operator approval should be set.
      try baseRegistrar.getApproved(tokenId) returns (address approved) {
        if (approved == address(nameWrapper)) ok = true;
      } catch {}
      if (!ok) {
        try baseRegistrar.isApprovedForAll(currentOwner, address(nameWrapper)) returns (bool isAll) {
          if (isAll) ok = true;
        } catch {}
      }
    }

    if (!ok) revert NotApproved(tokenId);

    // Perform the wrap: mint ERC-1155 to this contract
    nameWrapper.wrapETH2LD(label, address(this), fuses, expiry, resolver);

    emit EnsWrapped(label, labelhash, tokenId, fuses, expiry);
    _afterWrap(label, labelhash, tokenId, fuses, expiry, resolver);
  }

  /// @notice Unwrap a previously wrapped .eth name back to the Base Registrar ERC-721.
  /// @dev The resulting ERC-721 registrant/controller are forwarded per provided arguments.
  /// @param labelhash The keccak256 of the label being unwrapped.
  /// @param newRegistrant Address to receive the ERC-721 ownership in the Base Registrar.
  /// @param newController Address to be set as controller for the name.
  function unwrapEnsName(
    bytes32 labelhash,
    address newRegistrant,
    address newController
  ) external virtual onlyOwner nonReentrant {
    if (labelhash == bytes32(0) || newRegistrant == address(0) || newController == address(0)) {
      revert InvalidParams();
    }

    nameWrapper.unwrapETH2LD(labelhash, newRegistrant, newController);

    emit EnsUnwrapped(labelhash, newRegistrant, newController);
    _afterUnwrap(labelhash, newRegistrant, newController);
  }

  /// @notice Approve an operator (e.g., NameWrapper) to manage the ERC-721 token in the Base Registrar.
  /// @dev The contract must be authorized (owner or operator) for this to succeed.
  /// @param tokenId The .eth tokenId (uint256(keccak256(bytes(label)))).
  /// @param operator The operator to approve (commonly the NameWrapper address).
  function approveEnsName(uint256 tokenId, address operator) external virtual onlyOwner nonReentrant {
    if (operator == address(0)) revert ZeroAddress();

    baseRegistrar.approve(operator, tokenId);

    emit EnsApprovalSet(tokenId, operator);
    _afterApprove(tokenId, operator);
  }

  // ---------------------------
  // Hooks (optional extension points)
  // ---------------------------
  function _afterWrap(
    string calldata /*label*/,
    bytes32 /*labelhash*/,
    uint256 /*tokenId*/,
    uint32 /*fuses*/,
    uint64 /*expiry*/,
    address /*resolver*/
  ) internal virtual {}

  function _afterUnwrap(bytes32, /*labelhash*/ address, /*newRegistrant*/ address /*newController*/) internal virtual {}

  function _afterApprove(uint256, /*tokenId*/ address /*operator*/) internal virtual {}

  // ---------------------------
  // ERC165 support
  // ---------------------------
  /// @inheritdoc ERC1155HolderUpgradeable
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155HolderUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // ---------------------------
  // Storage gap for upgradeability
  // ---------------------------
  uint256[47] private __gap;
}
