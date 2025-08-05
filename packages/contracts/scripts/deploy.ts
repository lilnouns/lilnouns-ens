import { ethers, upgrades, network } from "hardhat";
import { Contract } from "ethers";
import * as fs from "fs";
import * as path from "path";

interface NetworkConfig {
  nftContract: string;
  nameWrapper: string;
  legacyMapper: string;
  ensRegistry: string;
  ensResolver: string;
  baseNode: string;
}

interface DeploymentResult {
  proxy: string;
  implementation: string;
  network: string;
  chainId: number;
  blockNumber: number;
  transactionHash: string;
}

/**
 * Network-specific configurations for LilNounsEnsMapperV2 deployment
 */
const networkConfigs: Record<string, NetworkConfig> = {
  // Mainnet configuration
  mainnet: {
    nftContract: "0x4b10701Bfd7BFEdc47d50562b76b436fbB5BdB3B", // LilNouns NFT
    nameWrapper: "0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401", // ENS NameWrapper
    legacyMapper: "0x0000000000000000000000000000000000000000", // No legacy mapper initially
    ensRegistry: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e", // ENS Registry
    ensResolver: "0x231b0Ee14048e9dCcD1d247744d114a4EB5E8E63", // Public Resolver
    baseNode: ethers.keccak256(
      ethers.concat([
        ethers.keccak256(ethers.concat([ethers.ZeroHash, ethers.keccak256(ethers.toUtf8Bytes("eth"))])),
        ethers.keccak256(ethers.toUtf8Bytes("lilnouns"))
      ])
    )
  },

  // Sepolia testnet configuration
  sepolia: {
    nftContract: "0x4b10701Bfd7BFEdc47d50562b76b436fbB5BdB3B", // Mock/Test LilNouns NFT
    nameWrapper: "0x0635513f179D50A207757E05759CbD106d7dFcE8", // ENS NameWrapper on Sepolia
    legacyMapper: "0x0000000000000000000000000000000000000000", // No legacy mapper initially
    ensRegistry: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e", // ENS Registry on Sepolia
    ensResolver: "0x8FADE66B79cC9f707aB26799354482EB93a5B7dD", // Public Resolver on Sepolia
    baseNode: ethers.keccak256(
      ethers.concat([
        ethers.keccak256(ethers.concat([ethers.ZeroHash, ethers.keccak256(ethers.toUtf8Bytes("eth"))])),
        ethers.keccak256(ethers.toUtf8Bytes("lilnouns"))
      ])
    )
  },

  // Goerli testnet configuration (deprecated but kept for compatibility)
  goerli: {
    nftContract: "0x4b10701Bfd7BFEdc47d50562b76b436fbB5BdB3B", // Mock/Test LilNouns NFT
    nameWrapper: "0x114D4603199df73e7D157787f8778E21fCd13066", // ENS NameWrapper on Goerli
    legacyMapper: "0x0000000000000000000000000000000000000000", // No legacy mapper initially
    ensRegistry: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e", // ENS Registry on Goerli
    ensResolver: "0x4B1488B7a6B320d2D721406204aBc3eeAa9AD329", // Public Resolver on Goerli
    baseNode: ethers.keccak256(
      ethers.concat([
        ethers.keccak256(ethers.concat([ethers.ZeroHash, ethers.keccak256(ethers.toUtf8Bytes("eth"))])),
        ethers.keccak256(ethers.toUtf8Bytes("lilnouns"))
      ])
    )
  },

  // Local development configuration
  localhost: {
    nftContract: "0x0000000000000000000000000000000000000001", // Mock address for local testing
    nameWrapper: "0x0000000000000000000000000000000000000002", // Mock address for local testing
    legacyMapper: "0x0000000000000000000000000000000000000000", // No legacy mapper initially
    ensRegistry: "0x0000000000000000000000000000000000000003", // Mock address for local testing
    ensResolver: "0x0000000000000000000000000000000000000004", // Mock address for local testing
    baseNode: ethers.keccak256(
      ethers.concat([
        ethers.keccak256(ethers.concat([ethers.ZeroHash, ethers.keccak256(ethers.toUtf8Bytes("eth"))])),
        ethers.keccak256(ethers.toUtf8Bytes("lilnouns"))
      ])
    )
  },

  // Hardhat network configuration
  hardhat: {
    nftContract: "0x0000000000000000000000000000000000000001", // Mock address for testing
    nameWrapper: "0x0000000000000000000000000000000000000002", // Mock address for testing
    legacyMapper: "0x0000000000000000000000000000000000000000", // No legacy mapper initially
    ensRegistry: "0x0000000000000000000000000000000000000003", // Mock address for testing
    ensResolver: "0x0000000000000000000000000000000000000004", // Mock address for testing
    baseNode: ethers.keccak256(
      ethers.concat([
        ethers.keccak256(ethers.concat([ethers.ZeroHash, ethers.keccak256(ethers.toUtf8Bytes("eth"))])),
        ethers.keccak256(ethers.toUtf8Bytes("lilnouns"))
      ])
    )
  }
};

/**
 * Deploy LilNounsEnsMapperV2 contract using UUPS proxy pattern
 */
async function deployLilNounsEnsMapperV2(): Promise<DeploymentResult> {
  const networkName = network.name;
  const config = networkConfigs[networkName];

  if (!config) {
    throw new Error(`Network configuration not found for: ${networkName}`);
  }

  console.log(`\n🚀 Deploying LilNounsEnsMapperV2 on ${networkName}...`);
  console.log(`📋 Configuration:`);
  console.log(`   NFT Contract: ${config.nftContract}`);
  console.log(`   Name Wrapper: ${config.nameWrapper}`);
  console.log(`   Legacy Mapper: ${config.legacyMapper}`);
  console.log(`   ENS Registry: ${config.ensRegistry}`);
  console.log(`   ENS Resolver: ${config.ensResolver}`);
  console.log(`   Base Node: ${config.baseNode}`);

  // Get contract factory
  const LilNounsEnsMapperV2 = await ethers.getContractFactory("LilNounsEnsMapperV2");

  // Deploy using OpenZeppelin upgrades plugin
  console.log("\n📦 Deploying implementation and proxy...");
  const proxy = await upgrades.deployProxy(
    LilNounsEnsMapperV2,
    [
      config.nftContract,
      config.nameWrapper,
      config.legacyMapper,
      config.ensRegistry,
      config.ensResolver,
      config.baseNode
    ],
    {
      kind: "uups",
      initializer: "initialize"
    }
  );

  await proxy.waitForDeployment();
  const proxyAddress = await proxy.getAddress();
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);

  // Get deployment transaction details
  const deploymentTx = proxy.deploymentTransaction();
  const chainId = (await ethers.provider.getNetwork()).chainId;
  const blockNumber = deploymentTx?.blockNumber || 0;
  const transactionHash = deploymentTx?.hash || "";

  console.log(`\n✅ Deployment successful!`);
  console.log(`   Proxy Address: ${proxyAddress}`);
  console.log(`   Implementation Address: ${implementationAddress}`);
  console.log(`   Transaction Hash: ${transactionHash}`);
  console.log(`   Block Number: ${blockNumber}`);

  // Verify deployment
  await verifyDeployment(proxy, config);

  // Save deployment information
  const deploymentResult: DeploymentResult = {
    proxy: proxyAddress,
    implementation: implementationAddress,
    network: networkName,
    chainId: Number(chainId),
    blockNumber,
    transactionHash
  };

  await saveDeploymentInfo(deploymentResult);

  return deploymentResult;
}

/**
 * Verify the deployment by checking contract state
 */
async function verifyDeployment(contract: Contract, config: NetworkConfig): Promise<void> {
  console.log("\n🔍 Verifying deployment...");

  try {
    // Check initialization
    const nftContract = await contract.nftContract();
    const nameWrapper = await contract.nameWrapper();
    const ensRegistry = await contract.ensRegistry();
    const ensResolver = await contract.ensResolver();
    const baseNode = await contract.baseNode();
    const owner = await contract.owner();
    const paused = await contract.paused();

    // Verify configuration
    if (nftContract !== config.nftContract) {
      throw new Error(`NFT contract mismatch: expected ${config.nftContract}, got ${nftContract}`);
    }
    if (nameWrapper !== config.nameWrapper) {
      throw new Error(`Name wrapper mismatch: expected ${config.nameWrapper}, got ${nameWrapper}`);
    }
    if (ensRegistry !== config.ensRegistry) {
      throw new Error(`ENS registry mismatch: expected ${config.ensRegistry}, got ${ensRegistry}`);
    }
    if (ensResolver !== config.ensResolver) {
      throw new Error(`ENS resolver mismatch: expected ${config.ensResolver}, got ${ensResolver}`);
    }
    if (baseNode !== config.baseNode) {
      throw new Error(`Base node mismatch: expected ${config.baseNode}, got ${baseNode}`);
    }

    console.log(`✅ Deployment verification successful!`);
    console.log(`   Contract Owner: ${owner}`);
    console.log(`   Contract Paused: ${paused}`);
  } catch (error) {
    console.error(`❌ Deployment verification failed:`, error);
    throw error;
  }
}

/**
 * Save deployment information to file
 */
async function saveDeploymentInfo(deployment: DeploymentResult): Promise<void> {
  const deploymentsDir = path.join(__dirname, "..", "deployments");
  const networkDir = path.join(deploymentsDir, deployment.network);

  // Create directories if they don't exist
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir);
  }
  if (!fs.existsSync(networkDir)) {
    fs.mkdirSync(networkDir);
  }

  // Save deployment info
  const deploymentFile = path.join(networkDir, "LilNounsEnsMapperV2.json");
  const deploymentData = {
    ...deployment,
    timestamp: new Date().toISOString(),
    deployer: await (await ethers.getSigners())[0].getAddress()
  };

  fs.writeFileSync(deploymentFile, JSON.stringify(deploymentData, null, 2));
  console.log(`\n💾 Deployment info saved to: ${deploymentFile}`);
}

/**
 * Deploy with custom configuration
 */
async function deployWithCustomConfig(
  nftContract: string,
  nameWrapper: string,
  legacyMapper: string,
  ensRegistry: string,
  ensResolver: string,
  baseNode: string
): Promise<DeploymentResult> {
  console.log(`\n🚀 Deploying LilNounsEnsMapperV2 with custom configuration...`);

  // Validate addresses
  if (!ethers.isAddress(nftContract)) throw new Error("Invalid NFT contract address");
  if (!ethers.isAddress(nameWrapper)) throw new Error("Invalid name wrapper address");
  if (legacyMapper !== ethers.ZeroAddress && !ethers.isAddress(legacyMapper)) {
    throw new Error("Invalid legacy mapper address");
  }
  if (!ethers.isAddress(ensRegistry)) throw new Error("Invalid ENS registry address");
  if (!ethers.isAddress(ensResolver)) throw new Error("Invalid ENS resolver address");

  // Get contract factory
  const LilNounsEnsMapperV2 = await ethers.getContractFactory("LilNounsEnsMapperV2");

  // Deploy using OpenZeppelin upgrades plugin
  const proxy = await upgrades.deployProxy(
    LilNounsEnsMapperV2,
    [nftContract, nameWrapper, legacyMapper, ensRegistry, ensResolver, baseNode],
    {
      kind: "uups",
      initializer: "initialize"
    }
  );

  await proxy.waitForDeployment();
  const proxyAddress = await proxy.getAddress();
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);

  // Get deployment transaction details
  const deploymentTx = proxy.deploymentTransaction();
  const chainId = (await ethers.provider.getNetwork()).chainId;
  const blockNumber = deploymentTx?.blockNumber || 0;
  const transactionHash = deploymentTx?.hash || "";

  console.log(`\n✅ Custom deployment successful!`);
  console.log(`   Proxy Address: ${proxyAddress}`);
  console.log(`   Implementation Address: ${implementationAddress}`);

  return {
    proxy: proxyAddress,
    implementation: implementationAddress,
    network: network.name,
    chainId: Number(chainId),
    blockNumber,
    transactionHash
  };
}

// Main deployment function
async function main() {
  try {
    const deployment = await deployLilNounsEnsMapperV2();
    console.log(`\n🎉 Deployment completed successfully on ${deployment.network}!`);
    process.exit(0);
  } catch (error) {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  }
}

// Export functions for use in other scripts
export {
  deployLilNounsEnsMapperV2,
  deployWithCustomConfig,
  verifyDeployment,
  saveDeploymentInfo,
  networkConfigs
};

// Run deployment if this script is executed directly
if (require.main === module) {
  main();
}
