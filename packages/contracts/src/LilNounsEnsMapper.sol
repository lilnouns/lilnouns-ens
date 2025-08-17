// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { LilNounsEnsHolder } from "./LilNounsEnsHolder.sol";
import { LilNounsEnsWrapper } from "./LilNounsEnsWrapper.sol";

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
    IENS _ens,
    IBaseRegistrar _baseRegistrar,
    INameWrapper _nameWrapper
  ) public initializer {
    __LilNounsEnsVault_init(initialOwner);

    __LilNounsEnsWrapper_init(ens, _baseRegistrar, _nameWrapper);
  }
}
