# LilNouns ENS Project

[![Build Status](https://github.com/lilnouns/lilnouns-ens/workflows/CI/badge.svg)](https://github.com/lilnouns/lilnouns-ens/actions)
[![Coverage Status](https://img.shields.io/badge/coverage-check%20latest-brightgreen)](https://github.com/lilnouns/lilnouns-ens/actions)
[![Forge Coverage](https://img.shields.io/badge/forge%20coverage-check%20latest-blue)](https://github.com/lilnouns/lilnouns-ens/actions)
[![Hardhat Coverage](https://img.shields.io/badge/hardhat%20coverage-check%20latest-blue)](https://github.com/lilnouns/lilnouns-ens/actions)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Node.js Version](https://img.shields.io/badge/node.js-22.x-green.svg)](https://nodejs.org/)
[![pnpm Version](https://img.shields.io/badge/pnpm-10.0.0+-orange.svg)](https://pnpm.io/)

An upgradeable ENS resolver and registrar for managing "lilnouns.eth" subdomains, enabling LilNouns NFT holders to claim and manage their personalized ENS domains.

## 🎯 Overview

The LilNouns ENS Project provides a comprehensive solution for LilNouns NFT holders to claim and manage ENS subdomains under the "lilnouns.eth" domain. The project implements an upgradeable smart contract architecture that integrates with the ENS Name Wrapper and maintains backward compatibility with legacy systems.

### Key Features

- **🔄 Upgradeable Architecture**: Uses OpenZeppelin's UUPS proxy pattern for safe contract upgrades
- **🛡️ Security First**: Implements pausable functionality, reentrancy protection, and comprehensive access controls
- **🔗 ENS Integration**: Full integration with ENS Name Wrapper for wrapped domain management
- **📱 Automatic Avatar Records**: Generates EIP-155 compliant NFT avatar URIs automatically
- **🔄 Legacy Compatibility**: Maintains backward compatibility with existing V1 mapper contract
- **⚡ Gas Optimized**: Efficient batch operations with DoS protection mechanisms

## 🏗️ Architecture

### Smart Contract Structure

```
LilNounsEnsMapperV2
├── Upgradeable Proxy (UUPS)
├── Access Control (Ownable)
├── Security (Pausable + ReentrancyGuard)
├── ENS Integration (Name Wrapper)
└── Legacy Compatibility (V1 Mapper)
```

### Core Components

- **LilNounsEnsMapperV2**: Main contract handling ENS domain registration and resolution
- **ENS Name Wrapper**: Official ENS contract for managing wrapped domains
- **LilNouns NFT Contract**: Source of truth for NFT ownership verification
- **Legacy V1 Mapper**: Backward compatibility for existing domain registrations

## 🚀 Quick Start

### Prerequisites

- **Node.js**: Version 22.x (NOT 23.x - Hardhat incompatible)
- **pnpm**: Version 10.0.0+
- **Foundry**: Required for both Forge and Hardhat tests

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/lilnouns/lilnouns-ens.git
   cd lilnouns-ens
   ```

2. **Install dependencies**
   ```bash
   pnpm install
   ```

3. **Set up environment variables**
   ```bash
   cp packages/contracts/.env.example packages/contracts/.env
   # Edit .env with your configuration
   ```

### Development Setup

```bash
# Install dependencies (includes forge install + remappings generation)
pnpm install

# Build all packages
pnpm build

# Run tests
pnpm test

# Start development mode
pnpm dev
```

## 🔧 Usage

### For NFT Holders

#### Claiming a Subdomain

```solidity
// Example: Claim "alice.lilnouns.eth" for token ID 123
mapper.claim("alice", 123);
```

#### Setting Text Records

```solidity
// Set custom text records (avatar is automatically generated)
bytes32 node = mapper.tokenNode(123);
mapper.setText(node, "description", "My awesome LilNoun!");
mapper.setText(node, "url", "https://lilnouns.wtf");
```

#### Importing Legacy Domains

```solidity
// Import existing V1 domain registration
mapper.importLegacy(123);
```

### For Developers

#### Contract Interaction

```typescript
import { ethers } from "hardhat";

// Get contract instance
const mapper = await ethers.getContractAt(
  "LilNounsEnsMapperV2", 
  "0x..." // Contract address
);

// Check if domain is available
const node = await mapper.domainMap("alice");
const isAvailable = node === ethers.constants.HashZero;

// Get domain for token
const domain = await mapper.getTokenDomain(123);
console.log(domain); // "alice.lilnouns.eth"
```

#### Batch Operations

```typescript
// Update multiple address records efficiently
const tokenIds = [1, 2, 3, 4, 5];
await mapper.updateAddresses(tokenIds);

// Get multiple domains at once
const domains = await mapper.getTokensDomains(tokenIds);
```

## 🧪 Testing

The project supports dual testing frameworks for comprehensive coverage:

### Forge Tests (Solidity)

```bash
# Run all Forge tests
cd packages/contracts && pnpm test:forge

# Run specific test with verbose output
forge test --match-contract LilNounsEnsMapperV2Test -vvv

# Run with gas reporting
forge test --gas-report
```

### Hardhat Tests (TypeScript)

```bash
# Run all Hardhat tests
cd packages/contracts && pnpm test:hardhat

# Run specific test file
npx hardhat test test/LilNounsEnsMapperV2.t.ts
```

### Test Coverage

```bash
# Generate coverage report
forge coverage

# View detailed coverage
forge coverage --report lcov
```

## 🚀 Deployment

### Local Development

```bash
# Start local node
npx hardhat node

# Deploy to local network
npx hardhat run scripts/deploy.ts --network localhost
```

### Testnet Deployment

```bash
# Deploy to Sepolia
npx hardhat run scripts/deploy.ts --network sepolia

# Verify contract
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> <CONSTRUCTOR_ARGS>
```

### Mainnet Deployment

```bash
# Deploy to mainnet (requires proper configuration)
npx hardhat run scripts/deploy.ts --network mainnet
```

## 📁 Project Structure

```
lilnouns-ens/
├── apps/
│   └── web/                 # Web application frontend
├── packages/
│   ├── contracts/           # Smart contracts (Foundry + Hardhat)
│   │   ├── src/            # Contract source files
│   │   ├── test/           # Test files (.t.sol and .t.ts)
│   │   ├── foundry.toml    # Foundry configuration
│   │   └── hardhat.config.ts # Hardhat configuration
│   └── ui/                 # Shared UI components
├── docs/                   # Project documentation
├── pnpm-workspace.yaml     # Workspace configuration
└── turbo.json             # Turbo build configuration
```

## 🔒 Security

### Security Features

- **Access Control**: Owner and NFT holder authorization system
- **Reentrancy Protection**: Comprehensive guards on state-changing functions
- **Pausable Operations**: Emergency stop functionality for critical operations
- **Input Validation**: Extensive validation of all user inputs
- **DoS Protection**: Array length limits to prevent gas exhaustion attacks

### Security Analysis

The project uses multiple security analysis tools:

- **Slither**: Static analysis for vulnerability detection
- **Solhint**: Solidity linting for code quality
- **Foundry**: Fuzz testing for edge case discovery

```bash
# Run security analysis
cd packages/contracts && pnpm lint
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

### Code Standards

- **Solidity**: Follow Solhint rules and NatSpec documentation
- **TypeScript**: Use strict mode and comprehensive type definitions
- **Testing**: Maintain high test coverage for all new features
- **Documentation**: Update documentation for any API changes

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **LilNouns DAO**: [lilnouns.wtf](https://lilnouns.wtf)
- **ENS Documentation**: [docs.ens.domains](https://docs.ens.domains)
- **OpenZeppelin**: [openzeppelin.com](https://openzeppelin.com)

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/lilnouns/lilnouns-ens/issues)
- **Discussions**: [GitHub Discussions](https://github.com/lilnouns/lilnouns-ens/discussions)
- **Discord**: [LilNouns Discord](https://discord.gg/lilnouns)

---

Built with ❤️ by the LilNouns community
