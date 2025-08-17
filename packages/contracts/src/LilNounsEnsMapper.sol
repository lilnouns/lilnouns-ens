// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { LilNounsEnsHolder } from "./LilNounsEnsHolder.sol";
import { LilNounsEnsWrapper } from "./LilNounsEnsWrapper.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ENS } from "@ensdomains/ens-contracts/registry/ENS.sol";
import { INameWrapper } from "@ensdomains/ens-contracts/wrapper/INameWrapper.sol";
import { IBaseRegistrar } from "@ensdomains/ens-contracts/ethregistrar/IBaseRegistrar.sol";

contract LilNounsEnsMapper is LilNounsEnsHolder, LilNounsEnsWrapper, UUPSUpgradeable {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice Initializes the contract
  /// @dev Use this instead of the constructor when deploying with a proxy
  function initialize(
    address initialOwner,
    ENS _ens,
    IBaseRegistrar _baseRegistrar,
    INameWrapper _nameWrapper
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
