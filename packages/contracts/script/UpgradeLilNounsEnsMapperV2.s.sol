// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { Script, console } from "forge-std/Script.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { LilNounsEnsMapperV2 } from "../src/LilNounsEnsMapperV2.sol";

/**
 * @title UpgradeLilNounsEnsMapperV2
 * @notice Upgrade script for LilNounsEnsMapperV2 contract using UUPS proxy pattern
 * @dev This script handles upgrading the implementation while preserving proxy state
 */
contract UpgradeLilNounsEnsMapperV2 is Script {
    // State variables to track upgrade
    struct UpgradeInfo {
        address proxy;
        address oldImplementation;
        address newImplementation;
        uint256 blockNumber;
        bytes32 transactionHash;
    }

    // Events for upgrade tracking
    event UpgradeStarted(address indexed proxy, address indexed oldImplementation);
    event UpgradeCompleted(address indexed proxy, address indexed newImplementation);
    event StateVerified(address indexed proxy, bool success);

    function run() public returns (UpgradeInfo memory) {
        // Get proxy address from environment or command line
        address proxyAddress = vm.envOr("PROXY_ADDRESS", address(0));

        if (proxyAddress == address(0)) {
            // Try to read from deployment artifacts
            string memory deploymentPath = string.concat("./deployments/", vm.toString(block.chainid), "/LilNounsEnsMapperV2.json");
            try vm.readFile(deploymentPath) returns (string memory deploymentData) {
                // Parse JSON to get proxy address (simplified - in practice would use JSON parsing)
                console.log("Loading proxy address from deployment file:", deploymentPath);
                // For now, require manual specification
                revert("PROXY_ADDRESS environment variable required");
            } catch {
                revert("PROXY_ADDRESS environment variable required and no deployment file found");
            }
        }

        return upgradeContract(proxyAddress);
    }

    /**
     * @notice Upgrade the contract implementation
     * @param proxyAddress Address of the existing proxy contract
     */
    function upgradeContract(address proxyAddress) public returns (UpgradeInfo memory) {
        require(proxyAddress != address(0), "Invalid proxy address");

        console.log("Starting upgrade for proxy:", proxyAddress);

        // Get current implementation
        address oldImplementation = _getImplementation(proxyAddress);
        console.log("Current implementation:", oldImplementation);

        // Verify pre-upgrade state
        _verifyPreUpgradeState(proxyAddress);

        vm.startBroadcast();

        // Deploy new implementation
        address newImplementation = address(new LilNounsEnsMapperV2());
        console.log("New implementation deployed:", newImplementation);

        // Perform upgrade
        LilNounsEnsMapperV2 proxy = LilNounsEnsMapperV2(proxyAddress);
        proxy.upgradeToAndCall(newImplementation, "");

        vm.stopBroadcast();

        // Verify post-upgrade state
        _verifyPostUpgradeState(proxyAddress, oldImplementation, newImplementation);

        // Create upgrade info
        UpgradeInfo memory upgradeInfo = UpgradeInfo({
            proxy: proxyAddress,
            oldImplementation: oldImplementation,
            newImplementation: newImplementation,
            blockNumber: block.number,
            transactionHash: bytes32(0) // Will be filled by transaction
        });

        console.log("Upgrade completed successfully!");
        console.log("Old implementation:", oldImplementation);
        console.log("New implementation:", newImplementation);

        return upgradeInfo;
    }

    /**
     * @notice Prepare upgrade by deploying new implementation without upgrading
     * @param proxyAddress Address of the existing proxy contract
     */
    function prepareUpgrade(address proxyAddress) public returns (address newImplementation) {
        require(proxyAddress != address(0), "Invalid proxy address");

        console.log("Preparing upgrade for proxy:", proxyAddress);

        // Get current implementation for comparison
        address currentImplementation = _getImplementation(proxyAddress);
        console.log("Current implementation:", currentImplementation);

        vm.startBroadcast();

        // Deploy new implementation
        newImplementation = address(new LilNounsEnsMapperV2());

        vm.stopBroadcast();

        console.log("New implementation prepared:", newImplementation);
        console.log("Ready for upgrade when needed");

        return newImplementation;
    }

    /**
     * @notice Validate upgrade compatibility
     * @param proxyAddress Address of the existing proxy contract
     */
    function validateUpgrade(address proxyAddress) public view returns (bool) {
        require(proxyAddress != address(0), "Invalid proxy address");

        console.log("Validating upgrade compatibility for:", proxyAddress);

        // Check if proxy exists and is a valid UUPS proxy
        if (proxyAddress.code.length == 0) {
            console.log("ERROR: Proxy address has no code");
            return false;
        }

        // Try to get current implementation
        try this._getImplementation(proxyAddress) returns (address impl) {
            if (impl == address(0)) {
                console.log("ERROR: Invalid implementation address");
                return false;
            }
            console.log("Current implementation:", impl);
        } catch {
            console.log("ERROR: Failed to get implementation address");
            return false;
        }

        // Check if proxy is owned by the caller (for upgrade authorization)
        try LilNounsEnsMapperV2(proxyAddress).owner() returns (address owner) {
            console.log("Proxy owner:", owner);
            console.log("Caller:", msg.sender);
            if (owner != msg.sender) {
                console.log("WARNING: Caller is not the owner - upgrade will fail");
                return false;
            }
        } catch {
            console.log("ERROR: Failed to get proxy owner");
            return false;
        }

        console.log("Upgrade validation successful");
        return true;
    }

    /**
     * @notice Get implementation address from proxy
     */
    function _getImplementation(address proxy) internal view returns (address) {
        // ERC1967 implementation slot
        bytes32 slot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        bytes32 impl = vm.load(proxy, slot);
        return address(uint160(uint256(impl)));
    }

    /**
     * @notice Verify contract state before upgrade
     */
    function _verifyPreUpgradeState(address proxyAddress) internal view {
        console.log("Verifying pre-upgrade state...");

        LilNounsEnsMapperV2 proxy = LilNounsEnsMapperV2(proxyAddress);

        try proxy.owner() returns (address owner) {
            console.log("Owner:", owner);
        } catch {
            console.log("WARNING: Failed to get owner");
        }

        try proxy.paused() returns (bool paused) {
            console.log("Paused:", paused);
        } catch {
            console.log("WARNING: Failed to get paused state");
        }

        try proxy.nftContract() returns (address nftContract) {
            console.log("NFT Contract:", nftContract);
        } catch {
            console.log("WARNING: Failed to get NFT contract");
        }

        try proxy.nameWrapper() returns (address nameWrapper) {
            console.log("Name Wrapper:", nameWrapper);
        } catch {
            console.log("WARNING: Failed to get name wrapper");
        }

        console.log("Pre-upgrade state verification completed");
    }

    /**
     * @notice Verify contract state after upgrade
     */
    function _verifyPostUpgradeState(
        address proxyAddress,
        address oldImplementation,
        address newImplementation
    ) internal view {
        console.log("Verifying post-upgrade state...");

        // Verify implementation was updated
        address currentImplementation = _getImplementation(proxyAddress);
        require(currentImplementation == newImplementation, "Implementation not updated");
        require(currentImplementation != oldImplementation, "Implementation unchanged");

        console.log("Implementation successfully updated");

        // Verify contract is still functional
        LilNounsEnsMapperV2 proxy = LilNounsEnsMapperV2(proxyAddress);

        try proxy.owner() returns (address owner) {
            console.log("Owner (post-upgrade):", owner);
        } catch {
            console.log("ERROR: Failed to get owner after upgrade");
            revert("Post-upgrade state verification failed");
        }

        try proxy.paused() returns (bool paused) {
            console.log("Paused (post-upgrade):", paused);
        } catch {
            console.log("ERROR: Failed to get paused state after upgrade");
            revert("Post-upgrade state verification failed");
        }

        console.log("Post-upgrade state verification successful");
    }

    /**
     * @notice Test upgrade with a specific proxy address
     * @dev This is a dry-run function for testing
     */
    function testUpgrade(address proxyAddress) public {
        console.log("Testing upgrade process (dry run)...");

        // Validate upgrade compatibility
        bool isValid = validateUpgrade(proxyAddress);
        require(isValid, "Upgrade validation failed");

        // Verify pre-upgrade state
        _verifyPreUpgradeState(proxyAddress);

        console.log("Upgrade test completed successfully");
        console.log("Ready to perform actual upgrade");
    }

    /**
     * @notice Emergency function to check proxy status
     */
    function checkProxyStatus(address proxyAddress) public view {
        console.log("Checking proxy status for:", proxyAddress);

        if (proxyAddress.code.length == 0) {
            console.log("ERROR: No code at proxy address");
            return;
        }

        address implementation = _getImplementation(proxyAddress);
        console.log("Implementation:", implementation);

        if (implementation.code.length == 0) {
            console.log("ERROR: No code at implementation address");
            return;
        }

        try LilNounsEnsMapperV2(proxyAddress).owner() returns (address owner) {
            console.log("Owner:", owner);
        } catch {
            console.log("ERROR: Failed to call owner()");
        }

        try LilNounsEnsMapperV2(proxyAddress).paused() returns (bool paused) {
            console.log("Paused:", paused);
        } catch {
            console.log("ERROR: Failed to call paused()");
        }

        console.log("Proxy status check completed");
    }
}
