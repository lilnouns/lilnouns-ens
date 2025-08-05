# Contributing to LilNouns ENS

Thank you for your interest in contributing to the LilNouns ENS project! This guide will help you understand our development process, coding standards, and how to submit contributions effectively.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Code Standards](#code-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Security Considerations](#security-considerations)
- [Documentation Standards](#documentation-standards)
- [Community Guidelines](#community-guidelines)

## Getting Started

### Prerequisites

Before contributing, ensure you have the following installed:

- **Node.js**: Exactly version 22.x (NOT 23.x - Hardhat incompatible)
- **pnpm**: Version 10.0.0+ (required package manager)
- **Foundry**: Required for both Forge and Hardhat tests
- **Python**: Required for Slither security analysis
- **Git**: For version control

### Environment Setup

1. **Fork and Clone the Repository**
   ```bash
   git clone https://github.com/your-username/lilnouns-ens.git
   cd lilnouns-ens
   ```

2. **Install Dependencies**
   ```bash
   pnpm install
   ```

3. **Verify Setup**
   ```bash
   # Test Forge compilation
   cd packages/contracts && pnpm build:forge
   
   # Test Hardhat compilation
   cd packages/contracts && pnpm build:hardhat
   
   # Run tests
   pnpm test
   ```

## Development Environment

### Project Structure

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

### Available Scripts

```bash
# Development mode (with hot reload)
pnpm dev

# Build all packages
pnpm build

# Run all tests
pnpm test

# Run linting
pnpm lint

# Format code
pnpm format

# Run specific tests
cd packages/contracts && pnpm test:forge    # Forge tests only
cd packages/contracts && pnpm test:hardhat  # Hardhat tests only
```

## Code Standards

### Solidity Code Standards

#### Style Guidelines
- **Solidity Version**: Use exactly `^0.8.29`
- **Line Length**: Maximum 120 characters
- **Indentation**: 2 spaces (no tabs)
- **Quotes**: Use double quotes for strings
- **Function Visibility**: Always explicit (public, external, internal, private)

#### Naming Conventions
- **Contracts**: PascalCase (e.g., `LilNounsEnsMapperV2`)
- **Functions**: camelCase (e.g., `claimSubdomain`)
- **Variables**: camelCase (e.g., `tokenId`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `MAX_BATCH_SIZE`)
- **Events**: PascalCase (e.g., `SubdomainClaimed`)
- **Modifiers**: camelCase (e.g., `onlyOwner`)

#### Code Organization
```solidity
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

// External imports first
import "@openzeppelin/contracts/...";

// Internal imports second
import "./interfaces/...";

/**
 * @title ContractName
 * @notice Brief description of contract purpose
 * @dev Detailed technical description
 */
contract ContractName {
    // State variables
    uint256 public constant MAX_VALUE = 1000;
    mapping(uint256 => address) private _owners;
    
    // Events
    event SomethingHappened(uint256 indexed tokenId, address indexed user);
    
    // Modifiers
    modifier onlyValidToken(uint256 tokenId) {
        require(tokenId > 0, "Invalid token ID");
        _;
    }
    
    // Constructor
    constructor() {}
    
    // External functions
    // Public functions
    // Internal functions
    // Private functions
}
```

#### Documentation Requirements
All public and external functions must include comprehensive NatSpec documentation:

```solidity
/**
 * @notice Claims a subdomain for a specific LilNoun token
 * @dev Validates token ownership and creates ENS subdomain mapping
 * @param label The subdomain label to claim (e.g., "mynoun")
 * @param tokenId The LilNoun token ID
 * @return success True if the claim was successful
 * @custom:security Validates token ownership before claiming
 */
function claimSubdomain(string calldata label, uint256 tokenId) 
    external 
    returns (bool success) {
    // Implementation
}
```

### TypeScript Code Standards

#### Style Guidelines
- **TypeScript**: Use strict mode
- **Line Length**: Maximum 120 characters
- **Indentation**: 2 spaces
- **Quotes**: Use double quotes for strings
- **Semicolons**: Always use semicolons

#### Naming Conventions
- **Variables/Functions**: camelCase
- **Types/Interfaces**: PascalCase
- **Constants**: SCREAMING_SNAKE_CASE
- **Files**: kebab-case

### Linting and Formatting

The project uses automated code formatting and linting:

- **Prettier**: Automatic code formatting
- **Solhint**: Solidity linting with custom rules
- **ESLint**: TypeScript/JavaScript linting

Before committing, run:
```bash
pnpm format  # Format all files
pnpm lint    # Check for linting issues
```

## Testing Requirements

### Test Coverage Standards

All contributions must maintain or improve test coverage:
- **Minimum Coverage**: 90% for new code
- **Function Coverage**: All public/external functions must be tested
- **Edge Cases**: Include tests for error conditions and edge cases
- **Integration Tests**: Test interactions with external contracts

### Testing Frameworks

The project uses dual testing frameworks:

#### Forge Tests (Solidity)
```solidity
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { Test, console } from "forge-std/Test.sol";
import { YourContract } from "../src/YourContract.sol";

contract YourContractTest is Test {
    YourContract public yourContract;

    function setUp() public {
        yourContract = new YourContract();
    }

    function test_FunctionName() public {
        // Test implementation
        uint256 result = yourContract.someFunction(42);
        assertEq(result, 42);
    }

    function testFuzz_FunctionName(uint256 randomValue) public {
        // Fuzz test implementation
        vm.assume(randomValue > 0);
        yourContract.someFunction(randomValue);
        // Assertions
    }
}
```

#### Hardhat Tests (TypeScript)
```typescript
import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe("YourContract", function () {
    async function deployFixture() {
        const YourContract = await ethers.getContractFactory("YourContract");
        const yourContract = await YourContract.deploy();
        return { yourContract };
    }

    it("Should handle function correctly", async function () {
        const { yourContract } = await loadFixture(deployFixture);
        
        await yourContract.someFunction(42);
        expect(await yourContract.getValue()).to.equal(42);
    });
});
```

### Running Tests

```bash
# Run all tests
pnpm test

# Run specific test suites
forge test --match-contract YourContractTest -vv
npx hardhat test test/YourContract.t.ts

# Run with coverage
forge coverage
npx hardhat coverage
```

### Test Requirements for PRs

1. **New Features**: Must include comprehensive tests
2. **Bug Fixes**: Must include regression tests
3. **Refactoring**: Must maintain existing test coverage
4. **Breaking Changes**: Must update affected tests

## Pull Request Process

### Before Submitting

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Follow code standards
   - Add comprehensive tests
   - Update documentation

3. **Pre-submission Checklist**
   ```bash
   pnpm format     # Format code
   pnpm lint       # Check linting
   pnpm test       # Run all tests
   pnpm build      # Verify build passes
   ```

### PR Requirements

#### Title and Description
- **Title**: Clear, descriptive summary (e.g., "Add batch claiming functionality")
- **Description**: Include:
  - What changes were made
  - Why the changes were necessary
  - How to test the changes
  - Any breaking changes
  - Related issues/tasks

#### Code Quality
- [ ] Code follows project style guidelines
- [ ] All tests pass
- [ ] Test coverage maintained or improved
- [ ] Documentation updated
- [ ] No linting errors
- [ ] Security considerations addressed

#### Review Process
1. **Automated Checks**: CI/CD pipeline must pass
2. **Code Review**: At least one maintainer approval required
3. **Security Review**: Required for contract changes
4. **Testing**: Manual testing for complex features

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed
- [ ] All tests pass

## Security
- [ ] Security implications considered
- [ ] No new security vulnerabilities introduced
- [ ] Slither analysis passes

## Documentation
- [ ] Code comments updated
- [ ] README updated (if applicable)
- [ ] API documentation updated (if applicable)
```

## Security Considerations

### Security-First Development

Security is paramount in smart contract development. All contributors must:

1. **Follow Security Best Practices**
   - Use OpenZeppelin contracts when possible
   - Implement proper access controls
   - Validate all inputs
   - Handle edge cases gracefully

2. **Security Review Process**
   - All contract changes require security review
   - Use static analysis tools (Slither, Mythril)
   - Consider economic incentives and attack vectors
   - Document security assumptions

3. **Common Security Patterns**
   ```solidity
   // Input validation
   require(tokenId > 0, "Invalid token ID");
   
   // Reentrancy protection
   modifier nonReentrant() {
       require(!_locked, "Reentrant call");
       _locked = true;
       _;
       _locked = false;
   }
   
   // Access control
   modifier onlyOwner() {
       require(msg.sender == owner, "Not authorized");
       _;
   }
   ```

### Vulnerability Reporting

If you discover a security vulnerability:

1. **DO NOT** create a public issue
2. **DO** email security concerns to [security contact]
3. **DO** provide detailed information about the vulnerability
4. **DO** allow reasonable time for response before disclosure

## Documentation Standards

### Code Documentation

- **NatSpec**: All public/external functions must have complete NatSpec
- **Inline Comments**: Complex logic should be explained
- **Architecture Docs**: Update architecture documentation for significant changes

### Commit Messages

Use conventional commit format:
```
type(scope): description

feat(contracts): add batch claiming functionality
fix(tests): resolve integration test flakiness
docs(readme): update installation instructions
refactor(mapper): optimize gas usage in claim function
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### Documentation Updates

When making changes, update relevant documentation:
- README.md for setup/usage changes
- API documentation for interface changes
- Architecture docs for design changes
- Deployment guides for operational changes

## Community Guidelines

### Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Maintain professional communication

### Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Discord**: For real-time community interaction

### Recognition

Contributors will be recognized in:
- CHANGELOG.md for significant contributions
- README.md contributors section
- Release notes for major features

## Development Workflow

### Issue Lifecycle

1. **Issue Creation**: Clear description with acceptance criteria
2. **Triage**: Labeled and prioritized by maintainers
3. **Assignment**: Self-assign or request assignment
4. **Development**: Create feature branch and implement
5. **Review**: Submit PR and address feedback
6. **Merge**: Maintainer merges after approval

### Release Process

1. **Feature Freeze**: No new features for release
2. **Testing**: Comprehensive testing and security review
3. **Documentation**: Update all relevant documentation
4. **Deployment**: Deploy to testnet for validation
5. **Release**: Tag release and deploy to mainnet

## Questions?

If you have questions about contributing:

1. Check existing documentation
2. Search GitHub issues and discussions
3. Create a new discussion for general questions
4. Create an issue for specific bugs or feature requests

Thank you for contributing to LilNouns ENS! 🎩
