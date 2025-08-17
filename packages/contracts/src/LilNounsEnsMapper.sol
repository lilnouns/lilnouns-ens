// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { LilNounsEnsHolder } from "./LilNounsEnsHolder.sol";
import { LilNounsEnsWrapper } from "./LilNounsEnsWrapper.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title LilNounsEnsMapper
/// @notice UUPS-upgradeable orchestrator combining the Holder and ENS Wrapper capabilities.
/// @dev
/// - Uses initializer pattern; constructor disables initializers for proxies.
/// - Authorizes upgrades via onlyOwner from Ownable2StepUpgradeable inherited through Holder/Wrapper.
/**
 * @author LilNouns ENS Authors
 */
contract LilNounsEnsMapper is LilNounsEnsHolder, LilNounsEnsWrapper, UUPSUpgradeable {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice Initialize the mapper with owner and ENS-related contracts.
  /// @dev Calls internal initializers of Holder and Wrapper. Reverts on zero addresses or misconfiguration.
  /// @param initialOwner The initial owner/admin of the contract.
  /// @param _ens ENS registry contract.
  /// @param _baseRegistrar .eth Base Registrar contract.
  /// @param _nameWrapper ENS NameWrapper contract.
  function initialize(
    address initialOwner,
    address _ens,
    address _baseRegistrar,
    address _nameWrapper
  ) public initializer {
    __LilNounsEnsHolder_init(initialOwner);
    __LilNounsEnsWrapper_init(_ens, _baseRegistrar, _nameWrapper);
  }

  /// @dev UUPS authorization hook: restrict to owner.
  function _authorizeUpgrade(address) internal override onlyOwner {}

  /// @inheritdoc LilNounsEnsHolder
  function supportsInterface(
    bytes4 interfaceId
  ) public view override(LilNounsEnsHolder, LilNounsEnsWrapper) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // Storage gap for future upgrades
  uint256[50] private __gap;
}
