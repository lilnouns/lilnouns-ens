// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { Script, console } from "forge-std/Script.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { LilNounsEnsMapperV2 } from "../src/LilNounsEnsMapperV2.sol";

/**
 * @title DeployLilNounsEnsMapperV2
 * @notice Deployment script for LilNounsEnsMapperV2 contract using UUPS proxy pattern
 * @dev This script deploys the implementation contract and proxy with proper initialization
 */
contract DeployLilNounsEnsMapperV2 is Script {
    // Network-specific contract addresses
    struct NetworkConfig {
        address nftContract;
        address nameWrapper;
        address legacyMapper;
        address ensRegistry;
        address ensResolver;
        bytes32 baseNode;
    }

    // Network configurations
    mapping(uint256 => NetworkConfig) public networkConfigs;

    function setUp() public {
        // Mainnet configuration
        networkConfigs[1] = NetworkConfig({
            nftContract: 0x4b10701Bfd7BFEdc47d50562b76b436fbB5BdB3B, // LilNouns NFT
            nameWrapper: 0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401, // ENS NameWrapper
            legacyMapper: address(0), // No legacy mapper on mainnet initially
            ensRegistry: 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e, // ENS Registry
            ensResolver: 0x231b0Ee14048e9dCcD1d247744d114a4EB5E8E63, // Public Resolver
            baseNode: keccak256(abi.encodePacked(keccak256(abi.encodePacked(bytes32(0), keccak256("eth"))), keccak256("lilnouns")))
        });

        // Sepolia testnet configuration
        networkConfigs[11155111] = NetworkConfig({
            nftContract: 0x4b10701Bfd7BFEdc47d50562b76b436fbB5BdB3B, // Mock/Test LilNouns NFT
            nameWrapper: 0x0635513f179D50A207757E05759CbD106d7dFcE8, // ENS NameWrapper on Sepolia
            legacyMapper: address(0), // No legacy mapper initially
            ensRegistry: 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e, // ENS Registry on Sepolia
            ensResolver: 0x8FADE66B79cC9f707aB26799354482EB93a5B7dD, // Public Resolver on Sepolia
            baseNode: keccak256(abi.encodePacked(keccak256(abi.encodePacked(bytes32(0), keccak256("eth"))), keccak256("lilnouns")))
        });

        // Goerli testnet configuration (deprecated but kept for compatibility)
        networkConfigs[5] = NetworkConfig({
            nftContract: 0x4b10701Bfd7BFEdc47d50562b76b436fbB5BdB3B, // Mock/Test LilNouns NFT
            nameWrapper: 0x114D4603199df73e7D157787f8778E21fCd13066, // ENS NameWrapper on Goerli
            legacyMapper: address(0), // No legacy mapper initially
            ensRegistry: 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e, // ENS Registry on Goerli
            ensResolver: 0x4B1488B7a6B320d2D721406204aBc3eeAa9AD329, // Public Resolver on Goerli
            baseNode: keccak256(abi.encodePacked(keccak256(abi.encodePacked(bytes32(0), keccak256("eth"))), keccak256("lilnouns")))
        });

        // Local development configuration
        networkConfigs[31337] = NetworkConfig({
            nftContract: address(0x1), // Mock address for local testing
            nameWrapper: address(0x2), // Mock address for local testing
            legacyMapper: address(0), // No legacy mapper initially
            ensRegistry: address(0x3), // Mock address for local testing
            ensResolver: address(0x4), // Mock address for local testing
            baseNode: keccak256(abi.encodePacked(keccak256(abi.encodePacked(bytes32(0), keccak256("eth"))), keccak256("lilnouns")))
        });
    }

    function run() public returns (address proxy, address implementation) {
        uint256 chainId = block.chainid;
        NetworkConfig memory config = networkConfigs[chainId];

        require(config.nftContract != address(0), "Network not configured");

        console.log("Deploying LilNounsEnsMapperV2 on chain ID:", chainId);
        console.log("NFT Contract:", config.nftContract);
        console.log("Name Wrapper:", config.nameWrapper);
        console.log("ENS Registry:", config.ensRegistry);
        console.log("ENS Resolver:", config.ensResolver);

        vm.startBroadcast();

        // Deploy implementation contract
        implementation = address(new LilNounsEnsMapperV2());
        console.log("Implementation deployed at:", implementation);

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            LilNounsEnsMapperV2.initialize.selector,
            config.nftContract,
            config.nameWrapper,
            config.legacyMapper,
            config.ensRegistry,
            config.ensResolver,
            config.baseNode
        );

        // Deploy proxy contract
        proxy = address(new ERC1967Proxy(implementation, initData));
        console.log("Proxy deployed at:", proxy);

        vm.stopBroadcast();

        // Verify deployment
        _verifyDeployment(proxy, config);

        return (proxy, implementation);
    }

    function _verifyDeployment(address proxy, NetworkConfig memory config) internal view {
        LilNounsEnsMapperV2 mapper = LilNounsEnsMapperV2(proxy);

        // Verify initialization
        require(mapper.nftContract() == config.nftContract, "NFT contract mismatch");
        require(mapper.nameWrapper() == config.nameWrapper, "Name wrapper mismatch");
        require(mapper.ensRegistry() == config.ensRegistry, "ENS registry mismatch");
        require(mapper.ensResolver() == config.ensResolver, "ENS resolver mismatch");
        require(mapper.baseNode() == config.baseNode, "Base node mismatch");

        console.log("Deployment verification successful!");
        console.log("Contract owner:", mapper.owner());
        console.log("Contract paused:", mapper.paused());
    }

    /**
     * @notice Deploy to specific network with custom configuration
     * @param nftContract Address of the LilNouns NFT contract
     * @param nameWrapper Address of the ENS NameWrapper contract
     * @param legacyMapper Address of the legacy mapper (can be zero)
     * @param ensRegistry Address of the ENS Registry
     * @param ensResolver Address of the ENS Resolver
     * @param baseNode Base node for lilnouns.eth domain
     */
    function deployWithConfig(
        address nftContract,
        address nameWrapper,
        address legacyMapper,
        address ensRegistry,
        address ensResolver,
        bytes32 baseNode
    ) public returns (address proxy, address implementation) {
        require(nftContract != address(0), "Invalid NFT contract");
        require(nameWrapper != address(0), "Invalid name wrapper");
        require(ensRegistry != address(0), "Invalid ENS registry");
        require(ensResolver != address(0), "Invalid ENS resolver");

        console.log("Deploying with custom configuration...");

        vm.startBroadcast();

        // Deploy implementation contract
        implementation = address(new LilNounsEnsMapperV2());
        console.log("Implementation deployed at:", implementation);

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            LilNounsEnsMapperV2.initialize.selector,
            nftContract,
            nameWrapper,
            legacyMapper,
            ensRegistry,
            ensResolver,
            baseNode
        );

        // Deploy proxy contract
        proxy = address(new ERC1967Proxy(implementation, initData));
        console.log("Proxy deployed at:", proxy);

        vm.stopBroadcast();

        console.log("Custom deployment completed successfully!");
        return (proxy, implementation);
    }
}
