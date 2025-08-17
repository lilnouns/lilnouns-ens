// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { ERC721HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import { ERC1155HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { ENS } from "@ensdomains/ens-contracts/registry/ENS.sol";
import { INameWrapper } from "@ensdomains/ens-contracts/wrapper/INameWrapper.sol";
import { IBaseRegistrar } from "@ensdomains/ens-contracts/ethregistrar/IBaseRegistrar.sol";
import { LilNounsEnsErrors } from "./LilNounsEnsErrors.sol";

/// @title LilNounsEnsWrapper
/// @notice Abstract, upgradeable base to expose ENS NameWrapper flows for inheriting NFT-holding contracts.
/// @dev
/// - Uses OZ upgradeable modules and an internal initializer so children can initialize ENS addresses.
/// - Callable by other contracts; avoids EOA-only assumptions.
/// - Exposes wrap and unwrap flows for .eth 2LDs via the official NameWrapper/Base Registrar.
/// - Provides a helper to set Base Registrar approvals.
/**
 * @author LilNouns ENS Authors
 */
abstract contract LilNounsEnsWrapper is
  Initializable,
  Ownable2StepUpgradeable,
  ReentrancyGuardUpgradeable,
  ERC721HolderUpgradeable,
  ERC1155HolderUpgradeable
{
  /// @notice Emitted after a successful wrap of a .eth second-level domain.
  /// @param label The ASCII label used to wrap (not indexed).
  /// @param labelhash The keccak256 of the label (indexed).
  /// @param tokenId The ERC-721 tokenId in the Base Registrar (indexed).
  /// @param fuses The fuse configuration applied in the NameWrapper.
  /// @param expiry The expiry returned by NameWrapper.
  event EnsWrapped(string label, bytes32 indexed labelhash, uint256 indexed tokenId, uint32 fuses, uint64 expiry);

  /// @notice Emitted after unwrapping a .eth name back to the Base Registrar ERC-721.
  /// @param labelhash The keccak256 of the label (indexed).
  /// @param newRegistrant The new ERC-721 registrant in the Base Registrar (indexed).
  /// @param newController The controller to set for the name.
  event EnsUnwrapped(bytes32 indexed labelhash, address indexed newRegistrant, address newController);

  /// @notice Emitted when the ENS-related contract addresses are rotated by the owner.
  /// @param ens The ENS registry address.
  /// @param baseRegistrar The Base Registrar address.
  /// @param nameWrapper The NameWrapper address.
  event EnsContractsUpdated(address indexed ens, address indexed baseRegistrar, address indexed nameWrapper);

  /// @notice Emitted when an approval is set on the Base Registrar tokenId.
  /// @param tokenId The ERC-721 token id (indexed).
  /// @param approved The approved operator address (indexed).
  event EnsApprovalSet(uint256 indexed tokenId, address indexed approved);

  /// @notice ENS registry reference.
  ENS public ens;
  /// @notice Base Registrar reference.
  IBaseRegistrar public baseRegistrar;
  /// @notice NameWrapper reference.
  INameWrapper public nameWrapper;

  /// @notice Internal initializer. Must be called by inheriting contract's initializer.
  /// @param ensAddress ENS registry address (nonzero)
  /// @param baseRegistrarAddress Base Registrar address (nonzero)
  /// @param nameWrapperAddress NameWrapper address (nonzero)
  // solhint-disable-next-line func-name-mixedcase
  function __LilNounsEnsWrapper_init(
    address ensAddress,
    address baseRegistrarAddress,
    address nameWrapperAddress
  ) internal onlyInitializing {
    if (
      address(ensAddress) == address(0) ||
      address(baseRegistrarAddress) == address(0) ||
      address(nameWrapperAddress) == address(0)
    ) {
      revert LilNounsEnsErrors.ZeroAddress();
    }

    ens = ENS(ensAddress);
    baseRegistrar = IBaseRegistrar(baseRegistrarAddress);
    nameWrapper = INameWrapper(nameWrapperAddress);

    // Sanity check that the NameWrapper is wired to the provided ENS and Base Registrar.
    // If the implementation doesn't expose these getters, we consider it misconfigured for this system.
    // Using try/catch to defensively handle unexpected implementations.
    try nameWrapper.ens() returns (ENS reportedEns) {
      if (address(reportedEns) == address(0) || address(reportedEns) != address(ensAddress)) {
        revert LilNounsEnsErrors.MisconfiguredENS();
      }
    } catch {
      revert LilNounsEnsErrors.MisconfiguredENS();
    }
    try nameWrapper.registrar() returns (IBaseRegistrar reportedRegistrar) {
      if (address(reportedRegistrar) == address(0) || address(reportedRegistrar) != address(baseRegistrarAddress)) {
        revert LilNounsEnsErrors.MisconfiguredENS();
      }
    } catch {
      revert LilNounsEnsErrors.MisconfiguredENS();
    }
  }

  /// @notice Rotate ENS-related contract addresses after validating consistency.
  /// @dev Owner-only. Performs sanity checks on NameWrapper relations via try/catch.
  /// @param _ens New ENS registry address.
  /// @param _baseRegistrar New Base Registrar address.
  /// @param _nameWrapper New NameWrapper address.
  function setEnsContracts(ENS _ens, IBaseRegistrar _baseRegistrar, INameWrapper _nameWrapper) external onlyOwner {
    if (address(_ens) == address(0) || address(_baseRegistrar) == address(0) || address(_nameWrapper) == address(0)) {
      revert LilNounsEnsErrors.ZeroAddress();
    }

    // Re-run sanity checks against the provided NameWrapper
    try _nameWrapper.ens() returns (ENS reportedEns) {
      if (address(reportedEns) == address(0) || address(reportedEns) != address(_ens)) {
        revert LilNounsEnsErrors.MisconfiguredENS();
      }
    } catch {
      revert LilNounsEnsErrors.MisconfiguredENS();
    }
    try _nameWrapper.registrar() returns (IBaseRegistrar reportedRegistrar) {
      if (address(reportedRegistrar) == address(0) || address(reportedRegistrar) != address(_baseRegistrar)) {
        revert LilNounsEnsErrors.MisconfiguredENS();
      }
    } catch {
      revert LilNounsEnsErrors.MisconfiguredENS();
    }
    ens = _ens;
    baseRegistrar = _baseRegistrar;
    nameWrapper = _nameWrapper;

    emit EnsContractsUpdated(address(_ens), address(_baseRegistrar), address(_nameWrapper));
  }

  /// @notice Wrap a .eth second-level domain held in the Base Registrar so the ERC-1155 is minted to this contract.
  /// @dev
  /// - Computes tokenId via keccak256(label), as used by the .eth Base Registrar.
  /// - Checks approvals for NameWrapper to transfer the ERC-721; reverts if not approved.
  /// - Emits EnsWrapped and calls the internal _afterWrap hook; reentrancy-protected.
  /// @param label The ASCII label to wrap (e.g., "lilnouns").
  /// @param resolver The resolver address to set at wrap time.
  /// @param fuses NameWrapper fuse settings to apply (will be cast to uint16 as per INameWrapper).
  function wrapEnsName(string calldata label, address resolver, uint32 fuses) external virtual onlyOwner nonReentrant {
    if (bytes(label).length == 0) revert LilNounsEnsErrors.InvalidParams();

    bytes32 labelhash = keccak256(bytes(label));
    uint256 tokenId = uint256(labelhash);

    // Optional preflight: ensure NameWrapper is approved for this tokenId by the current owner.
    address currentOwner = address(0);
    try baseRegistrar.ownerOf(tokenId) returns (address o) {
      currentOwner = o;
    } catch {
      revert LilNounsEnsErrors.NotApproved(tokenId);
    }
    bool ok = false;
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

    if (!ok) revert LilNounsEnsErrors.NotApproved(tokenId);

    // Perform the wrap: mint ERC-1155 to this contract
    uint64 expiry = nameWrapper.wrapETH2LD(label, address(this), uint16(fuses), resolver);

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
      revert LilNounsEnsErrors.InvalidParams();
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
    if (operator == address(0)) revert LilNounsEnsErrors.ZeroAddress();

    baseRegistrar.approve(operator, tokenId);

    emit EnsApprovalSet(tokenId, operator);
    _afterApprove(tokenId, operator);
  }

  /// @inheritdoc ERC1155HolderUpgradeable
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC1155HolderUpgradeable, ERC721HolderUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // Storage gap for upgrade ability
  uint256[47] private __gap;
}
