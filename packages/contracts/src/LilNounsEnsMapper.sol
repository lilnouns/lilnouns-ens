// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { LilNounsEnsHolder } from "./LilNounsEnsHolder.sol";
import { LilNounsEnsWrapper } from "./LilNounsEnsWrapper.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { ENS } from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import { INameWrapper } from "@ensdomains/ens-contracts/contracts/wrapper/INameWrapper.sol";
import { IBaseRegistrar } from "@ensdomains/ens-contracts/contracts/ethregistrar/IBaseRegistrar.sol";

contract LilNounsEnsMapper is
  LilNounsEnsHolder,
  LilNounsEnsWrapper,
  Initializable,
  UUPSUpgradeable,
  Ownable2StepUpgradeable
{
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

    __LilNounsEnsWrapper_init(ens, _baseRegistrar, _nameWrapper);
  }
}
