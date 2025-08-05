import { ethers, network } from "hardhat";
import * as fs from "fs";
import * as path from "path";

interface ContractInfo {
  address: string;
  network: string;
  owner: string;
  paused: boolean;
  nftContract: string;
  nameWrapper: string;
  ensRegistry: string;
  ensResolver: string;
  baseNode: string;
  implementation: string;
}

interface InteractionResult {
  success: boolean;
  transactionHash?: string;
  blockNumber?: number;
  gasUsed?: bigint;
  error?: string;
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
 * Save interaction results to file
 */
async function saveInteractionResult(
  operation: string,
  result: InteractionResult,
  contractAddress: string
): Promise<void> {
  const interactionsDir = path.join(__dirname, "..", "interactions");
  const networkDir = path.join(interactionsDir, network.name);

  // Create directories if they don't exist
  if (!fs.existsSync(interactionsDir)) {
    fs.mkdirSync(interactionsDir);
  }
  if (!fs.existsSync(networkDir)) {
    fs.mkdirSync(networkDir);
  }

  // Save interaction result
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const interactionFile = path.join(networkDir, `${operation}-${timestamp}.json`);
  const interactionData = {
    operation,
    contractAddress,
    network: network.name,
    result,
    timestamp: new Date().toISOString(),
    operator: await (await ethers.getSigners())[0].getAddress()
  };

  fs.writeFileSync(interactionFile, JSON.stringify(interactionData, null, 2));
  console.log(`\n💾 Interaction result saved to: ${interactionFile}`);
}

/**
 * Get comprehensive contract information
 */
async function getContractInfo(contractAddress: string): Promise<ContractInfo> {
  console.log(`\n📋 Getting contract information for: ${contractAddress}`);

  const contract = await ethers.getContractAt("LilNounsEnsMapperV2", contractAddress);

  // Get implementation address
  const implementationSlot = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc";
  const implementation = await ethers.provider.getStorage(contractAddress, implementationSlot);
  const implementationAddress = ethers.getAddress("0x" + implementation.slice(-40));

  const info: ContractInfo = {
    address: contractAddress,
    network: network.name,
    owner: await contract.owner(),
    paused: await contract.paused(),
    nftContract: await contract.nftContract(),
    nameWrapper: await contract.nameWrapper(),
    ensRegistry: await contract.ensRegistry(),
    ensResolver: await contract.ensResolver(),
    baseNode: await contract.baseNode(),
    implementation: implementationAddress
  };

  console.log(`📊 Contract Information:`);
  console.log(`   Address: ${info.address}`);
  console.log(`   Network: ${info.network}`);
  console.log(`   Owner: ${info.owner}`);
  console.log(`   Paused: ${info.paused}`);
  console.log(`   NFT Contract: ${info.nftContract}`);
  console.log(`   Name Wrapper: ${info.nameWrapper}`);
  console.log(`   ENS Registry: ${info.ensRegistry}`);
  console.log(`   ENS Resolver: ${info.ensResolver}`);
  console.log(`   Base Node: ${info.baseNode}`);
  console.log(`   Implementation: ${info.implementation}`);

  return info;
}

/**
 * Pause the contract
 */
async function pauseContract(contractAddress: string): Promise<InteractionResult> {
  console.log(`\n⏸️  Pausing contract: ${contractAddress}`);

  try {
    const contract = await ethers.getContractAt("LilNounsEnsMapperV2", contractAddress);

    // Check if already paused
    const isPaused = await contract.paused();
    if (isPaused) {
      console.log(`⚠️  Contract is already paused`);
      return { success: true, error: "Contract already paused" };
    }

    // Check if caller is owner
    const owner = await contract.owner();
    const signer = await ethers.getSigners();
    const caller = await signer[0].getAddress();

    if (owner !== caller) {
      throw new Error(`Only owner can pause contract. Owner: ${owner}, Caller: ${caller}`);
    }

    // Pause the contract
    const tx = await contract.pause();
    const receipt = await tx.wait();

    console.log(`✅ Contract paused successfully`);
    console.log(`   Transaction Hash: ${receipt?.hash}`);
    console.log(`   Block Number: ${receipt?.blockNumber}`);
    console.log(`   Gas Used: ${receipt?.gasUsed}`);

    const result: InteractionResult = {
      success: true,
      transactionHash: receipt?.hash,
      blockNumber: receipt?.blockNumber,
      gasUsed: receipt?.gasUsed
    };

    await saveInteractionResult("pause", result, contractAddress);
    return result;

  } catch (error: any) {
    console.error(`❌ Failed to pause contract:`, error.message);
    const result: InteractionResult = {
      success: false,
      error: error.message
    };
    await saveInteractionResult("pause", result, contractAddress);
    return result;
  }
}

/**
 * Unpause the contract
 */
async function unpauseContract(contractAddress: string): Promise<InteractionResult> {
  console.log(`\n▶️  Unpausing contract: ${contractAddress}`);

  try {
    const contract = await ethers.getContractAt("LilNounsEnsMapperV2", contractAddress);

    // Check if already unpaused
    const isPaused = await contract.paused();
    if (!isPaused) {
      console.log(`⚠️  Contract is already unpaused`);
      return { success: true, error: "Contract already unpaused" };
    }

    // Check if caller is owner
    const owner = await contract.owner();
    const signer = await ethers.getSigners();
    const caller = await signer[0].getAddress();

    if (owner !== caller) {
      throw new Error(`Only owner can unpause contract. Owner: ${owner}, Caller: ${caller}`);
    }

    // Unpause the contract
    const tx = await contract.unpause();
    const receipt = await tx.wait();

    console.log(`✅ Contract unpaused successfully`);
    console.log(`   Transaction Hash: ${receipt?.hash}`);
    console.log(`   Block Number: ${receipt?.blockNumber}`);
    console.log(`   Gas Used: ${receipt?.gasUsed}`);

    const result: InteractionResult = {
      success: true,
      transactionHash: receipt?.hash,
      blockNumber: receipt?.blockNumber,
      gasUsed: receipt?.gasUsed
    };

    await saveInteractionResult("unpause", result, contractAddress);
    return result;

  } catch (error: any) {
    console.error(`❌ Failed to unpause contract:`, error.message);
    const result: InteractionResult = {
      success: false,
      error: error.message
    };
    await saveInteractionResult("unpause", result, contractAddress);
    return result;
  }
}

/**
 * Transfer ownership of the contract
 */
async function transferOwnership(contractAddress: string, newOwner: string): Promise<InteractionResult> {
  console.log(`\n👑 Transferring ownership of contract: ${contractAddress}`);
  console.log(`   New Owner: ${newOwner}`);

  try {
    if (!ethers.isAddress(newOwner)) {
      throw new Error(`Invalid new owner address: ${newOwner}`);
    }

    const contract = await ethers.getContractAt("LilNounsEnsMapperV2", contractAddress);

    // Check current owner
    const currentOwner = await contract.owner();
    const signer = await ethers.getSigners();
    const caller = await signer[0].getAddress();

    if (currentOwner !== caller) {
      throw new Error(`Only current owner can transfer ownership. Owner: ${currentOwner}, Caller: ${caller}`);
    }

    if (currentOwner === newOwner) {
      console.log(`⚠️  New owner is the same as current owner`);
      return { success: true, error: "New owner is the same as current owner" };
    }

    // Transfer ownership
    const tx = await contract.transferOwnership(newOwner);
    const receipt = await tx.wait();

    console.log(`✅ Ownership transferred successfully`);
    console.log(`   From: ${currentOwner}`);
    console.log(`   To: ${newOwner}`);
    console.log(`   Transaction Hash: ${receipt?.hash}`);
    console.log(`   Block Number: ${receipt?.blockNumber}`);
    console.log(`   Gas Used: ${receipt?.gasUsed}`);

    const result: InteractionResult = {
      success: true,
      transactionHash: receipt?.hash,
      blockNumber: receipt?.blockNumber,
      gasUsed: receipt?.gasUsed
    };

    await saveInteractionResult("transfer-ownership", result, contractAddress);
    return result;

  } catch (error: any) {
    console.error(`❌ Failed to transfer ownership:`, error.message);
    const result: InteractionResult = {
      success: false,
      error: error.message
    };
    await saveInteractionResult("transfer-ownership", result, contractAddress);
    return result;
  }
}

/**
 * Renounce ownership of the contract
 */
async function renounceOwnership(contractAddress: string): Promise<InteractionResult> {
  console.log(`\n🚫 Renouncing ownership of contract: ${contractAddress}`);
  console.log(`⚠️  WARNING: This will permanently remove the owner and make the contract non-upgradeable!`);

  try {
    const contract = await ethers.getContractAt("LilNounsEnsMapperV2", contractAddress);

    // Check current owner
    const currentOwner = await contract.owner();
    const signer = await ethers.getSigners();
    const caller = await signer[0].getAddress();

    if (currentOwner !== caller) {
      throw new Error(`Only current owner can renounce ownership. Owner: ${currentOwner}, Caller: ${caller}`);
    }

    if (currentOwner === ethers.ZeroAddress) {
      console.log(`⚠️  Ownership already renounced`);
      return { success: true, error: "Ownership already renounced" };
    }

    // Renounce ownership
    const tx = await contract.renounceOwnership();
    const receipt = await tx.wait();

    console.log(`✅ Ownership renounced successfully`);
    console.log(`   Previous Owner: ${currentOwner}`);
    console.log(`   New Owner: ${ethers.ZeroAddress}`);
    console.log(`   Transaction Hash: ${receipt?.hash}`);
    console.log(`   Block Number: ${receipt?.blockNumber}`);
    console.log(`   Gas Used: ${receipt?.gasUsed}`);

    const result: InteractionResult = {
      success: true,
      transactionHash: receipt?.hash,
      blockNumber: receipt?.blockNumber,
      gasUsed: receipt?.gasUsed
    };

    await saveInteractionResult("renounce-ownership", result, contractAddress);
    return result;

  } catch (error: any) {
    console.error(`❌ Failed to renounce ownership:`, error.message);
    const result: InteractionResult = {
      success: false,
      error: error.message
    };
    await saveInteractionResult("renounce-ownership", result, contractAddress);
    return result;
  }
}

/**
 * Check contract health and status
 */
async function healthCheck(contractAddress: string): Promise<void> {
  console.log(`\n🏥 Performing health check for contract: ${contractAddress}`);

  try {
    const contract = await ethers.getContractAt("LilNounsEnsMapperV2", contractAddress);

    // Basic connectivity test
    console.log(`\n🔌 Connectivity Test:`);
    const code = await ethers.provider.getCode(contractAddress);
    if (code === "0x") {
      console.log(`❌ No code at contract address`);
      return;
    } else {
      console.log(`✅ Contract has bytecode (${code.length} characters)`);
    }

    // Contract state checks
    console.log(`\n📊 Contract State:`);
    try {
      const owner = await contract.owner();
      console.log(`✅ Owner: ${owner}`);
    } catch (error) {
      console.log(`❌ Failed to get owner: ${error}`);
    }

    try {
      const paused = await contract.paused();
      console.log(`${paused ? '⏸️' : '▶️'} Paused: ${paused}`);
    } catch (error) {
      console.log(`❌ Failed to get paused state: ${error}`);
    }

    // Configuration checks
    console.log(`\n⚙️  Configuration:`);
    try {
      const nftContract = await contract.nftContract();
      console.log(`${nftContract !== ethers.ZeroAddress ? '✅' : '❌'} NFT Contract: ${nftContract}`);
    } catch (error) {
      console.log(`❌ Failed to get NFT contract: ${error}`);
    }

    try {
      const nameWrapper = await contract.nameWrapper();
      console.log(`${nameWrapper !== ethers.ZeroAddress ? '✅' : '❌'} Name Wrapper: ${nameWrapper}`);
    } catch (error) {
      console.log(`❌ Failed to get name wrapper: ${error}`);
    }

    try {
      const ensRegistry = await contract.ensRegistry();
      console.log(`${ensRegistry !== ethers.ZeroAddress ? '✅' : '❌'} ENS Registry: ${ensRegistry}`);
    } catch (error) {
      console.log(`❌ Failed to get ENS registry: ${error}`);
    }

    try {
      const ensResolver = await contract.ensResolver();
      console.log(`${ensResolver !== ethers.ZeroAddress ? '✅' : '❌'} ENS Resolver: ${ensResolver}`);
    } catch (error) {
      console.log(`❌ Failed to get ENS resolver: ${error}`);
    }

    // Interface support checks
    console.log(`\n🔌 Interface Support:`);
    try {
      const supportsERC165 = await contract.supportsInterface("0x01ffc9a7");
      console.log(`${supportsERC165 ? '✅' : '❌'} ERC165: ${supportsERC165}`);

      const supportsResolver = await contract.supportsInterface("0x3b3b57de");
      console.log(`${supportsResolver ? '✅' : '❌'} ENS Resolver: ${supportsResolver}`);
    } catch (error) {
      console.log(`❌ Failed to check interface support: ${error}`);
    }

    // Proxy checks
    console.log(`\n🔄 Proxy Status:`);
    try {
      const implementationSlot = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc";
      const implementation = await ethers.provider.getStorage(contractAddress, implementationSlot);
      const implementationAddress = ethers.getAddress("0x" + implementation.slice(-40));
      console.log(`${implementationAddress !== ethers.ZeroAddress ? '✅' : '❌'} Implementation: ${implementationAddress}`);

      if (implementationAddress !== ethers.ZeroAddress) {
        const implCode = await ethers.provider.getCode(implementationAddress);
        console.log(`${implCode !== "0x" ? '✅' : '❌'} Implementation has code: ${implCode !== "0x"}`);
      }
    } catch (error) {
      console.log(`❌ Failed to check proxy status: ${error}`);
    }

    console.log(`\n🎉 Health check completed!`);

  } catch (error) {
    console.error(`❌ Health check failed:`, error);
  }
}

/**
 * Emergency pause (for critical situations)
 */
async function emergencyPause(contractAddress: string, reason: string): Promise<InteractionResult> {
  console.log(`\n🚨 EMERGENCY PAUSE for contract: ${contractAddress}`);
  console.log(`   Reason: ${reason}`);

  const result = await pauseContract(contractAddress);

  if (result.success) {
    console.log(`\n🚨 EMERGENCY PAUSE ACTIVATED`);
    console.log(`   Contract: ${contractAddress}`);
    console.log(`   Reason: ${reason}`);
    console.log(`   Transaction: ${result.transactionHash}`);

    // Log emergency action
    await saveInteractionResult("emergency-pause", {
      ...result,
      error: reason
    }, contractAddress);
  }

  return result;
}

// Main interaction function
async function main() {
  const args = process.argv.slice(2);
  const command = args[0];
  const contractAddress = args[1];
  const additionalArg = args[2];

  // Load contract address from deployment if not provided
  let targetAddress = contractAddress;
  if (!targetAddress) {
    try {
      const deployment = loadDeploymentInfo(network.name);
      targetAddress = deployment.proxy;
      console.log(`📋 Using deployed contract address: ${targetAddress}`);
    } catch (error) {
      console.error(`❌ No contract address provided and no deployment found for ${network.name}`);
      process.exit(1);
    }
  }

  try {
    switch (command) {
      case "info":
        await getContractInfo(targetAddress);
        break;

      case "pause":
        const pauseResult = await pauseContract(targetAddress);
        console.log(`\n🎉 Pause operation ${pauseResult.success ? 'successful' : 'failed'}!`);
        break;

      case "unpause":
        const unpauseResult = await unpauseContract(targetAddress);
        console.log(`\n🎉 Unpause operation ${unpauseResult.success ? 'successful' : 'failed'}!`);
        break;

      case "transfer-ownership":
        if (!additionalArg) {
          throw new Error("New owner address required for ownership transfer");
        }
        const transferResult = await transferOwnership(targetAddress, additionalArg);
        console.log(`\n🎉 Ownership transfer ${transferResult.success ? 'successful' : 'failed'}!`);
        break;

      case "renounce-ownership":
        const renounceResult = await renounceOwnership(targetAddress);
        console.log(`\n🎉 Ownership renouncement ${renounceResult.success ? 'successful' : 'failed'}!`);
        break;

      case "health":
        await healthCheck(targetAddress);
        break;

      case "emergency-pause":
        if (!additionalArg) {
          throw new Error("Reason required for emergency pause");
        }
        const emergencyResult = await emergencyPause(targetAddress, additionalArg);
        console.log(`\n🚨 Emergency pause ${emergencyResult.success ? 'activated' : 'failed'}!`);
        break;

      default:
        console.log(`
Usage: npx hardhat run scripts/interact.ts -- <command> [contractAddress] [additionalArg]

Commands:
  info [contractAddress]                    - Get comprehensive contract information
  pause [contractAddress]                   - Pause the contract
  unpause [contractAddress]                 - Unpause the contract
  transfer-ownership [contractAddress] <newOwner> - Transfer contract ownership
  renounce-ownership [contractAddress]      - Renounce contract ownership (DANGEROUS!)
  health [contractAddress]                  - Perform comprehensive health check
  emergency-pause [contractAddress] <reason> - Emergency pause with reason

If contractAddress is not provided, it will be loaded from deployment files.

Examples:
  npx hardhat run scripts/interact.ts -- info
  npx hardhat run scripts/interact.ts -- pause 0x123...
  npx hardhat run scripts/interact.ts -- transfer-ownership 0x123... 0x456...
  npx hardhat run scripts/interact.ts -- emergency-pause 0x123... "Security incident detected"
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
  getContractInfo,
  pauseContract,
  unpauseContract,
  transferOwnership,
  renounceOwnership,
  healthCheck,
  emergencyPause,
  loadDeploymentInfo,
  saveInteractionResult
};

// Run interaction if this script is executed directly
if (require.main === module) {
  main();
}
