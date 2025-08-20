// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

// Foundry script base
import { Script } from "forge-std/Script.sol";
import { console2 as console } from "forge-std/console2.sol";

// OpenZeppelin Foundry Upgrades utilities
import { Upgrades } from "@openzeppelin/foundry-upgrades/Upgrades.sol";

// Target contract (for type info in abi.encodeCall)
import { LilNounsEnsMapperV2 } from "../src/LilNounsEnsMapperV2.sol";

/// @title LilNounsEnsMapperV2Script
/// @notice Foundry script to deploy LilNounsEnsMapperV2 behind a UUPS proxy using OpenZeppelin foundry-upgrades.
/// @dev This script uses Upgrades.deployUUPSProxy to deploy a UUPS proxy + implementation and calls the initializer.
///      Variables are loaded from env with a network prefix inferred from the RPC endpoint:
///        - MAINNET_* for Ethereum mainnet (chainid 1)
///        - SEPOLIA_* for Sepolia (chainid 11155111)
///      For backward compatibility, if a prefixed variable is missing it falls back to the unprefixed name.
///      Required variables (per-network):
///       - <PREFIX>_LEGACY_MAPPER   (address)
///       - <PREFIX>_ENS_REGISTRY    (address)
///       - <PREFIX>_ENS_ROOT_NODE   (bytes32)
///       - <PREFIX>_ROOT_LABEL      (string)
///       - <PREFIX>_INITIAL_OWNER   (address)
///
/// Example:
///   forge script script/LilNounsEnsMapperV2.s.sol:LilNounsEnsMapperV2Script \
///     --rpc-url $SEPOLIA_RPC_URL \
///     --broadcast \
///     --sender $DEPLOYER_ADDRESS \
///     -vvvv
contract LilNounsEnsMapperV2Script is Script {
  error UnsupportedNetwork(uint256 chainId);
  error MissingEnv(string expectedPrefixedKey, string fallbackKey);

  function _networkPrefix() internal view returns (string memory) {
    // Detect network by chainid derived from the provided --rpc-url
    if (block.chainid == 1) return "MAINNET";
    if (block.chainid == 11155111) return "SEPOLIA";
    revert UnsupportedNetwork(block.chainid);
  }

  function _envAddress(
    string memory prefix,
    string memory baseKey,
    bool fallbackToUnprefixed
  ) internal view returns (address) {
    string memory key = string.concat(prefix, "_", baseKey);
    try vm.envAddress(key) returns (address v) {
      return v;
    } catch {
      if (fallbackToUnprefixed) {
        try vm.envAddress(baseKey) returns (address v2) {
          return v2;
        } catch {
          revert MissingEnv(key, baseKey);
        }
      }
      revert MissingEnv(key, baseKey);
    }
  }

  function _envBytes32(
    string memory prefix,
    string memory baseKey,
    bool fallbackToUnprefixed
  ) internal view returns (bytes32) {
    string memory key = string.concat(prefix, "_", baseKey);
    try vm.envBytes32(key) returns (bytes32 v) {
      return v;
    } catch {
      if (fallbackToUnprefixed) {
        try vm.envBytes32(baseKey) returns (bytes32 v2) {
          return v2;
        } catch {
          revert MissingEnv(key, baseKey);
        }
      }
      revert MissingEnv(key, baseKey);
    }
  }

  function _envString(
    string memory prefix,
    string memory baseKey,
    bool fallbackToUnprefixed
  ) internal view returns (string memory) {
    string memory key = string.concat(prefix, "_", baseKey);
    try vm.envString(key) returns (string memory v) {
      return v;
    } catch {
      if (fallbackToUnprefixed) {
        try vm.envString(baseKey) returns (string memory v2) {
          return v2;
        } catch {
          revert MissingEnv(key, baseKey);
        }
      }
      revert MissingEnv(key, baseKey);
    }
  }

  function run() external {
    // Determine network from the RPC endpoint (via chainid) and compute env var prefix
    string memory prefix = _networkPrefix();
    console.log("Detected network prefix:", prefix);

    // Load deployment parameters, preferring prefixed keys and falling back to unprefixed for compatibility
    address legacy = _envAddress(prefix, "LEGACY_MAPPER", true);
    address ensRegistry = _envAddress(prefix, "ENS_REGISTRY", true);
    bytes32 rootNode = _envBytes32(prefix, "ENS_ROOT_NODE", true);
    string memory rootLabel = _envString(prefix, "ROOT_LABEL", true);
    address initialOwner = _envAddress(prefix, "INITIAL_OWNER", true);

    // Validate values with clear errors
    require(legacy != address(0), string.concat(prefix, "_LEGACY_MAPPER is zero"));
    require(ensRegistry != address(0), string.concat(prefix, "_ENS_REGISTRY is zero"));
    require(rootNode != bytes32(0), string.concat(prefix, "_ENS_ROOT_NODE is zero"));
    require(bytes(rootLabel).length > 0, string.concat(prefix, "_ROOT_LABEL empty"));
    require(initialOwner != address(0), string.concat(prefix, "_INITIAL_OWNER is zero"));

    // Prepare initializer calldata for the proxy. This will invoke:
    // initialize(address initialOwner, address legacyAddr, address ensRegistry, bytes32 ensRoot, string calldata labelRoot)
    bytes memory initData = abi.encodeCall(
      LilNounsEnsMapperV2.initialize,
      (initialOwner, legacy, ensRegistry, rootNode, rootLabel)
    );

    vm.startBroadcast();

    // Deploy the UUPS proxy with OZ Upgrades.
    address proxy = Upgrades.deployUUPSProxy("LilNounsEnsMapperV2.sol:LilNounsEnsMapperV2", initData);

    vm.stopBroadcast();

    // Log resulting addresses for convenience.
    console.log("LilNounsEnsMapperV2 UUPS proxy deployed at:", proxy);
  }
}
