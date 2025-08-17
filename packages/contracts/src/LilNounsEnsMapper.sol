// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { LilNounsEnsHolder } from "./LilNounsEnsHolder.sol";
import { LilNounsEnsWrapper } from "./LilNounsEnsWrapper.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

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
    __LilNounsEnsVault_init(initialOwner);
    __LilNounsEnsWrapper_init(_ens, _baseRegistrar, _nameWrapper);
  }

  // UUPS authorization hook
  function _authorizeUpgrade(address) internal override onlyOwner {}

  // Resolve multiple inheritance for ERC165 support
  function supportsInterface(
    bytes4 interfaceId
  ) public view override(LilNounsEnsHolder, LilNounsEnsWrapper) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // Storage gap for future upgrades
  uint256[50] private __gap;
}
