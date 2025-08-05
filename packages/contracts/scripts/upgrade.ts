import { ethers, upgrades, network } from "hardhat";
import { Contract } from "ethers";
import * as fs from "fs";
import * as path from "path";

interface UpgradeResult {
  oldImplementation: string;
  newImplementation: string;
  proxy: string;
  network: string;
  chainId: number;
  blockNumber: number;
  transactionHash: string;
}

/**
 * Load deployment information from file
 */
function loadDeploymentInfo(networkName: string): any {
  const deploymentFile = path.join(__dirname, "..", "deployments", networkName, "LilNounsEnsMapperV2.json");

  if (!fs.existsSync(deploymentFile)) {
    throw new Error(`Deployment file not found: ${deploymentFile}`);
  }

  return JSON.parse(fs.readFileSync(deploymentFile, "utf8"));
}

/**
 * Save upgrade information to file
 */
async function saveUpgradeInfo(upgrade: UpgradeResult): Promise<void> {
  const upgradesDir = path.join(__dirname, "..", "upgrades");
  const networkDir = path.join(upgradesDir, upgrade.network);

  // Create directories if they don't exist
  if (!fs.existsSync(upgradesDir)) {
    fs.mkdirSync(upgradesDir);
  }
  if (!fs.existsSync(networkDir)) {
    fs.mkdirSync(networkDir);
  }

  // Save upgrade info
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const upgradeFile = path.join(networkDir, `upgrade-${timestamp}.json`);
  const upgradeData = {
    ...upgrade,
    timestamp: new Date().toISOString(),
    upgrader: await (await ethers.getSigners())[0].getAddress()
  };

  fs.writeFileSync(upgradeFile, JSON.stringify(upgradeData, null, 2));
  console.log(`\n💾 Upgrade info saved to: ${upgradeFile}`);
}

/**
 * Verify contract state before upgrade
 */
async function verifyPreUpgradeState(proxy: Contract): Promise<any> {
  console.log("\n🔍 Verifying pre-upgrade state...");

  const state = {
    owner: await proxy.owner(),
    paused: await proxy.paused(),
    nftContract: await proxy.nftContract(),
    nameWrapper: await proxy.nameWrapper(),
    ensRegistry: await proxy.ensRegistry(),
    ensResolver: await proxy.ensResolver(),
    baseNode: await proxy.baseNode(),
    // Add more state variables as needed
  };

  console.log("Pre-upgrade state:", state);
  return state;
}

/**
 * Verify contract state after upgrade
 */
async function verifyPostUpgradeState(proxy: Contract, preUpgradeState: any): Promise<void> {
  console.log("\n🔍 Verifying post-upgrade state...");

  const postState = {
    owner: await proxy.owner(),
    paused: await proxy.paused(),
    nftContract: await proxy.nftContract(),
    nameWrapper: await proxy.nameWrapper(),
    ensRegistry: await proxy.ensRegistry(),
    ensResolver: await proxy.ensResolver(),
    baseNode: await proxy.baseNode(),
  };

  console.log("Post-upgrade state:", postState);

  // Verify critical state is preserved
  if (postState.owner !== preUpgradeState.owner) {
    throw new Error(`Owner changed during upgrade: ${preUpgradeState.owner} -> ${postState.owner}`);
  }
  if (postState.nftContract !== preUpgradeState.nftContract) {
    throw new Error(`NFT contract changed during upgrade: ${preUpgradeState.nftContract} -> ${postState.nftContract}`);
  }
  if (postState.nameWrapper !== preUpgradeState.nameWrapper) {
    throw new Error(`Name wrapper changed during upgrade: ${preUpgradeState.nameWrapper} -> ${postState.nameWrapper}`);
  }
  if (postState.ensRegistry !== preUpgradeState.ensRegistry) {
    throw new Error(`ENS registry changed during upgrade: ${preUpgradeState.ensRegistry} -> ${postState.ensRegistry}`);
  }
  if (postState.ensResolver !== preUpgradeState.ensResolver) {
    throw new Error(`ENS resolver changed during upgrade: ${preUpgradeState.ensResolver} -> ${postState.ensResolver}`);
  }
  if (postState.baseNode !== preUpgradeState.baseNode) {
    throw new Error(`Base node changed during upgrade: ${preUpgradeState.baseNode} -> ${postState.baseNode}`);
  }

  console.log("✅ State verification successful - all critical state preserved!");
}

/**
 * Test upgrade functionality
 */
async function testUpgradeFunctionality(proxy: Contract): Promise<void> {
  console.log("\n🧪 Testing upgrade functionality...");

  try {
    // Test basic functionality still works
    const owner = await proxy.owner();
    const paused = await proxy.paused();

    console.log(`Contract owner: ${owner}`);
    console.log(`Contract paused: ${paused}`);

    // Test that the contract is still upgradeable
    const implementationSlot = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc";
    const implementation = await ethers.provider.getStorage(await proxy.getAddress(), implementationSlot);
    console.log(`Current implementation: ${ethers.getAddress("0x" + implementation.slice(-40))}`);

    console.log("✅ Upgrade functionality test passed!");
  } catch (error) {
    console.error("❌ Upgrade functionality test failed:", error);
    throw error;
  }
}

/**
 * Upgrade LilNounsEnsMapperV2 contract
 */
async function upgradeLilNounsEnsMapperV2(proxyAddress?: string): Promise<UpgradeResult> {
  const networkName = network.name;

  // Load existing deployment if proxy address not provided
  if (!proxyAddress) {
    const deployment = loadDeploymentInfo(networkName);
    proxyAddress = deployment.proxy;
  }

  if (!ethers.isAddress(proxyAddress)) {
    throw new Error(`Invalid proxy address: ${proxyAddress}`);
  }

  console.log(`\n🚀 Upgrading LilNounsEnsMapperV2 on ${networkName}...`);
  console.log(`📋 Proxy Address: ${proxyAddress}`);

  // Get current implementation address
  const oldImplementation = await upgrades.erc1967.getImplementationAddress(proxyAddress);
  console.log(`Current Implementation: ${oldImplementation}`);

  // Get existing proxy contract
  const existingProxy = await ethers.getContractAt("LilNounsEnsMapperV2", proxyAddress);

  // Verify pre-upgrade state
  const preUpgradeState = await verifyPreUpgradeState(existingProxy);

  // Get new contract factory
  const LilNounsEnsMapperV2 = await ethers.getContractFactory("LilNounsEnsMapperV2");

  // Perform upgrade
  console.log("\n📦 Upgrading to new implementation...");
  const upgradedProxy = await upgrades.upgradeProxy(proxyAddress, LilNounsEnsMapperV2);
  await upgradedProxy.waitForDeployment();

  // Get new implementation address
  const newImplementation = await upgrades.erc1967.getImplementationAddress(proxyAddress);
  console.log(`New Implementation: ${newImplementation}`);

  // Get upgrade transaction details
  const upgradeTx = upgradedProxy.deploymentTransaction();
  const chainId = (await ethers.provider.getNetwork()).chainId;
  const blockNumber = upgradeTx?.blockNumber || 0;
  const transactionHash = upgradeTx?.hash || "";

  console.log(`\n✅ Upgrade successful!`);
  console.log(`   Transaction Hash: ${transactionHash}`);
  console.log(`   Block Number: ${blockNumber}`);

  // Verify post-upgrade state
  await verifyPostUpgradeState(upgradedProxy, preUpgradeState);

  // Test upgrade functionality
  await testUpgradeFunctionality(upgradedProxy);

  // Save upgrade information
  const upgradeResult: UpgradeResult = {
    oldImplementation,
    newImplementation,
    proxy: proxyAddress,
    network: networkName,
    chainId: Number(chainId),
    blockNumber,
    transactionHash
  };

  await saveUpgradeInfo(upgradeResult);

  return upgradeResult;
}

/**
 * Prepare upgrade (deploy new implementation without upgrading)
 */
async function prepareUpgrade(proxyAddress?: string): Promise<string> {
  const networkName = network.name;

  // Load existing deployment if proxy address not provided
  if (!proxyAddress) {
    const deployment = loadDeploymentInfo(networkName);
    proxyAddress = deployment.proxy;
  }

  if (!ethers.isAddress(proxyAddress)) {
    throw new Error(`Invalid proxy address: ${proxyAddress}`);
  }

  console.log(`\n🔧 Preparing upgrade for LilNounsEnsMapperV2 on ${networkName}...`);
  console.log(`📋 Proxy Address: ${proxyAddress}`);

  // Get contract factory
  const LilNounsEnsMapperV2 = await ethers.getContractFactory("LilNounsEnsMapperV2");

  // Prepare upgrade (deploy new implementation)
  console.log("\n📦 Deploying new implementation...");
  const newImplementationAddress = await upgrades.prepareUpgrade(proxyAddress, LilNounsEnsMapperV2);

  console.log(`\n✅ New implementation prepared!`);
  console.log(`   Implementation Address: ${newImplementationAddress}`);
  console.log(`   Ready for upgrade when needed.`);

  return newImplementationAddress as string;
}

/**
 * Validate upgrade compatibility
 */
async function validateUpgrade(proxyAddress?: string): Promise<void> {
  const networkName = network.name;

  // Load existing deployment if proxy address not provided
  if (!proxyAddress) {
    const deployment = loadDeploymentInfo(networkName);
    proxyAddress = deployment.proxy;
  }

  if (!ethers.isAddress(proxyAddress)) {
    throw new Error(`Invalid proxy address: ${proxyAddress}`);
  }

  console.log(`\n🔍 Validating upgrade compatibility for ${proxyAddress}...`);

  try {
    // Get contract factory
    const LilNounsEnsMapperV2 = await ethers.getContractFactory("LilNounsEnsMapperV2");

    // Validate upgrade
    await upgrades.validateUpgrade(proxyAddress, LilNounsEnsMapperV2);

    console.log("✅ Upgrade validation successful - no compatibility issues found!");
  } catch (error) {
    console.error("❌ Upgrade validation failed:", error);
    throw error;
  }
}

/**
 * Force import existing proxy for upgrades management
 */
async function forceImport(proxyAddress: string): Promise<void> {
  if (!ethers.isAddress(proxyAddress)) {
    throw new Error(`Invalid proxy address: ${proxyAddress}`);
  }

  console.log(`\n🔧 Force importing proxy for upgrades management: ${proxyAddress}`);

  try {
    // Get contract factory
    const LilNounsEnsMapperV2 = await ethers.getContractFactory("LilNounsEnsMapperV2");

    // Force import
    await upgrades.forceImport(proxyAddress, LilNounsEnsMapperV2);

    console.log("✅ Proxy successfully imported for upgrades management!");
  } catch (error) {
    console.error("❌ Force import failed:", error);
    throw error;
  }
}

// Main upgrade function
async function main() {
  const args = process.argv.slice(2);
  const command = args[0];
  const proxyAddress = args[1];

  try {
    switch (command) {
      case "upgrade":
        const upgrade = await upgradeLilNounsEnsMapperV2(proxyAddress);
        console.log(`\n🎉 Upgrade completed successfully on ${upgrade.network}!`);
        break;

      case "prepare":
        const newImpl = await prepareUpgrade(proxyAddress);
        console.log(`\n🎉 New implementation prepared: ${newImpl}`);
        break;

      case "validate":
        await validateUpgrade(proxyAddress);
        console.log(`\n🎉 Upgrade validation completed successfully!`);
        break;

      case "import":
        if (!proxyAddress) {
          throw new Error("Proxy address required for import command");
        }
        await forceImport(proxyAddress);
        console.log(`\n🎉 Proxy import completed successfully!`);
        break;

      default:
        console.log(`
Usage: npx hardhat run scripts/upgrade.ts -- <command> [proxyAddress]

Commands:
  upgrade [proxyAddress]  - Upgrade the contract to new implementation
  prepare [proxyAddress]  - Prepare upgrade (deploy new implementation only)
  validate [proxyAddress] - Validate upgrade compatibility
  import <proxyAddress>   - Force import existing proxy for management

If proxyAddress is not provided, it will be loaded from deployment files.
        `);
        process.exit(1);
    }

    process.exit(0);
  } catch (error) {
    console.error(`❌ ${command} failed:`, error);
    process.exit(1);
  }
}

// Export functions for use in other scripts
export {
  upgradeLilNounsEnsMapperV2,
  prepareUpgrade,
  validateUpgrade,
  forceImport,
  verifyPreUpgradeState,
  verifyPostUpgradeState,
  testUpgradeFunctionality,
  loadDeploymentInfo,
  saveUpgradeInfo
};

// Run upgrade if this script is executed directly
if (require.main === module) {
  main();
}
