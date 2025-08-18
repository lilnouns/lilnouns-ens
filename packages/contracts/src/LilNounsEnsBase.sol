// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { ERC721HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import { ERC1155HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { ENS } from "@ensdomains/ens-contracts/registry/ENS.sol";
import { INameWrapper } from "@ensdomains/ens-contracts/wrapper/INameWrapper.sol";
import { IBaseRegistrar } from "@ensdomains/ens-contracts/ethregistrar/IBaseRegistrar.sol";
import { ILilNounsEnsMapperV1 } from "./interfaces/ILilNounsEnsMapperV1.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { LilNounsEnsErrors } from "./LilNounsEnsErrors.sol";

/// @title LilNounsEnsBase
/// @notice Abstract upgradeable base that centralizes shared modules, storage, access control, pausing, and ENS config.
/// @dev Aggregates OZ upgradeable modules once to keep children thin and avoid bytecode bloat.
abstract contract LilNounsEnsBase is
  Initializable,
  Ownable2StepUpgradeable,
  UUPSUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable
{
  /// @notice Common configuration for ENS components and project references
  struct Config {
    address ens; // ENS registry
    address baseRegistrar; // .eth registrar
    address nameWrapper; // ENS NameWrapper
    address legacy; // legacy V1 mapper for reads
    address nft; // Lil Nouns ERC721
    bytes32 rootNode; // namehash(rootLabel.eth)
    string rootLabel; // ASCII label (e.g., "lilnouns")
  }

  /// @notice Current configuration
  ENS public ens;
  IBaseRegistrar public baseRegistrar;
  INameWrapper public nameWrapper;
  ILilNounsEnsMapperV1 public legacy;
  IERC721 internal nft; // internal to keep children thin but accessible
  bytes32 internal rootNode;
  string internal rootLabel;

  /// @notice Scheduled pause window
  uint64 public pauseStart;
  uint64 public pauseEnd;

  /// @notice Emitted when configuration is updated
  event ConfigUpdated(
    address indexed ens,
    address indexed baseRegistrar,
    address indexed nameWrapper,
    address legacy,
    address nft,
    bytes32 rootNode,
    string rootLabel
  );

  /// @notice Emitted when a pause window is scheduled
  event PauseWindowScheduled(uint64 indexed start, uint64 indexed end, address indexed scheduler);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice Initialize base modules and ownership, then set full configuration
  /// @param initialOwner New owner for Ownable2StepUpgradeable
  /// @param cfg Config struct values; zero addresses (except legacy optional?) will revert
  function __LilNounsEnsBase_init(address initialOwner, Config memory cfg) internal onlyInitializing {
    if (initialOwner == address(0)) revert LilNounsEnsErrors.ZeroAddress();

    __Ownable_init(initialOwner);
    __Ownable2Step_init();
    __UUPSUpgradeable_init();
    __Pausable_init();
    __ReentrancyGuard_init();

    _setConfig(cfg);
  }

  /// @notice Update configuration for ENS/NFT/legacy/root details
  /// @dev onlyOwner; validates wiring where possible
  function setConfig(Config calldata cfg) external onlyOwner {
    _setConfig(cfg);
  }

  /// @dev Internal config setter with sanity checks
  function _setConfig(Config memory cfg) internal {
    if (
      cfg.ens == address(0) || cfg.baseRegistrar == address(0) || cfg.nameWrapper == address(0) || cfg.nft == address(0)
    ) {
      revert LilNounsEnsErrors.ZeroAddress();
    }
    if (cfg.rootNode == bytes32(0) || bytes(cfg.rootLabel).length == 0) revert LilNounsEnsErrors.InvalidParams();

    ens = ENS(cfg.ens);
    baseRegistrar = IBaseRegistrar(cfg.baseRegistrar);
    nameWrapper = INameWrapper(cfg.nameWrapper);
    legacy = ILilNounsEnsMapperV1(cfg.legacy);
    nft = IERC721(cfg.nft);
    rootNode = cfg.rootNode;
    rootLabel = cfg.rootLabel;

    // Defensive sanity check: ensure NameWrapper is connected to provided ENS and registrar
    try nameWrapper.ens() returns (ENS reportedEns) {
      if (address(reportedEns) != cfg.ens) revert LilNounsEnsErrors.MisconfiguredENS();
    } catch {
      revert LilNounsEnsErrors.MisconfiguredENS();
    }
    try nameWrapper.registrar() returns (IBaseRegistrar reportedRegistrar) {
      if (address(reportedRegistrar) != cfg.baseRegistrar) revert LilNounsEnsErrors.MisconfiguredENS();
    } catch {
      revert LilNounsEnsErrors.MisconfiguredENS();
    }
    emit ConfigUpdated(cfg.ens, cfg.baseRegistrar, cfg.nameWrapper, cfg.legacy, cfg.nft, cfg.rootNode, cfg.rootLabel);
  }

  /// @notice Schedule a pause window. During an active window, unpause cannot occur before end.
  /// @param start Unix timestamp when pause becomes active (can be in the past to pause immediately)
  /// @param end Unix timestamp when pause window ends (must be > start)
  function schedulePause(uint64 start, uint64 end) external onlyOwner {
    if (end == 0 || end <= start) revert LilNounsEnsErrors.InvalidParams();
    pauseStart = start;
    pauseEnd = end;
    emit PauseWindowScheduled(start, end, msg.sender);

    // If start already reached and not paused, pause now
    if (block.timestamp >= start && !paused()) {
      _pause();
    }
  }

  /// @notice Pause by owner (outside scheduler flow)
  function pause() external virtual onlyOwner {
    _pause();
  }

  /// @notice Unpause if allowed (not within active pause window)
  function unpause() external virtual onlyOwner {
    _requirePauseLiftable();
    _unpause();
  }

  /// @dev Ensure we're not in an active pause window when unpausing
  function _requirePauseLiftable() internal view {
    if (_isPauseWindowActive()) revert LilNounsEnsErrors.PauseWindowActive();
  }

  /// @dev True when current time is within [pauseStart, pauseEnd)
  function _isPauseWindowActive() internal view returns (bool) {
    uint64 s = pauseStart;
    uint64 e = pauseEnd;
    return (s != 0 && block.timestamp >= s && (e == 0 || block.timestamp < e));
  }

  /// @dev Override OZ Pausable hook used by whenNotPaused modifier to also honor scheduled window
  function _requireNotPaused() internal view virtual override {
    super._requireNotPaused();
    if (_isPauseWindowActive()) revert LilNounsEnsErrors.PauseWindowActive();
  }

  /// @dev UUPS authorization: restrict to owner
  function _authorizeUpgrade(address) internal view override onlyOwner {}

  /// @notice Helper to compute keccak256(label)
  function _labelHash(string memory label) internal pure returns (bytes32) {
    return keccak256(bytes(label));
  }

  /// @notice Helper to compute node for a label under rootNode
  function _nodeForLabel(string memory label) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(rootNode, _labelHash(label)));
  }

  /// @notice Expose root info to children
  function _rootInfo() internal view returns (bytes32, string memory) {
    return (rootNode, rootLabel);
  }

  // slither-disable-next-line naming-convention
  uint256[46] private __gap;
}
