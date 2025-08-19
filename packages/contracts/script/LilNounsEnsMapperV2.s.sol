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
///      Provide configuration via environment variables when running with `forge script`:
///       - LEGACY_MAPPER   (address) : Address of the legacy V1 mapping contract implementing ILilNounsEnsMapperV1
///       - ENS_REGISTRY    (address) : Address of the ENS registry
///       - ENS_ROOT_NODE   (bytes32) : Namehash of the root name (e.g., namehash("lilnouns.eth"))
///       - ROOT_LABEL      (string)  : Human-readable root label (e.g., "lilnouns")
///       - INITIAL_OWNER   (address) : Address to set as the initial owner of the proxy
///
/// Example:
///   forge script script/LilNounsEnsMapperV2.s.sol:LilNounsEnsMapperV2Script \
///     --rpc-url $SEPOLIA_RPC_URL \
///     --broadcast \
///     --sender $DEPLOYER_ADDRESS \
///     -vvvv
contract LilNounsEnsMapperV2Script is Script {
  function run() external {
    // Load deployment parameters from environment for production usage.
    // These env vars should be provided when running the script.
    address legacy = vm.envAddress("LEGACY_MAPPER");
    address ensRegistry = vm.envAddress("ENS_REGISTRY");
    bytes32 rootNode = vm.envBytes32("ENS_ROOT_NODE");
    string memory rootLabel = vm.envString("ROOT_LABEL");
    address initialOwner = vm.envAddress("INITIAL_OWNER");

    require(legacy != address(0), "LEGACY_MAPPER is zero");
    require(ensRegistry != address(0), "ENS_REGISTRY is zero");
    require(rootNode != bytes32(0), "ENS_ROOT_NODE is zero");
    require(bytes(rootLabel).length > 0, "ROOT_LABEL empty");
    require(initialOwner != address(0), "INITIAL_OWNER is zero");

    // Prepare initializer calldata for the proxy. This will invoke:
    // initialize(address initialOwner, address legacyAddr, address ensRegistry, bytes32 ensRoot, string calldata labelRoot)
    bytes memory initData = abi.encodeCall(
      LilNounsEnsMapperV2.initialize,
      (initialOwner, legacy, ensRegistry, rootNode, rootLabel)
    );

    vm.startBroadcast();

    // Deploy the UUPS proxy with OZ Upgrades. The first parameter is the implementation artifact identifier.
    // You can use either "LilNounsEnsMapperV2.sol" or the fully qualified name "LilNounsEnsMapperV2.sol:LilNounsEnsMapperV2".
    // Specifying the fully qualified name is more explicit and robust.
    address proxy = Upgrades.deployUUPSProxy("LilNounsEnsMapperV2.sol:LilNounsEnsMapperV2", initData);

    vm.stopBroadcast();

    // Log resulting addresses for convenience.
    console.log("LilNounsEnsMapperV2 UUPS proxy deployed at:", proxy);
  }
}
