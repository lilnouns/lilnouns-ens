# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0-alpha.13] - 2025-08-20

### 🚜 Refactor

- *(contracts)* Replace `isLegacySubname` by `isLegacyNode`

### 🧪 Testing

- *(contracts)* Update tests to use `isLegacyNode`
- *(contracts)* Remove unused `ILilNounsEnsMapperV1` import
- *(contracts)* Remove unused `console` import

## [1.0.0-alpha.12] - 2025-08-20

### 🚀 Features

- *(contracts)* Add `isLegacySubname` method
- *(contracts)* Add `relinquishSubname` method
- *(contracts)* Add `releaseLegacySubname` method

### 🚜 Refactor

- *(contracts)* Rename `migrateSubnameFromV1` method

### 🧪 Testing

- *(mocks)* Add mocks for ENS, ERC721, and legacy mappings
- *(contracts)* Add fuzz tests for subname claims and migration
- *(contracts)* Add tests for `relinquishSubname` method
- *(contracts)* Add tests for `releaseLegacySubname` method

## [1.0.0-alpha.11] - 2025-08-19

### 🚀 Features

- *(contracts)* Add deployment script for `LilNounsEnsMapperV2`
- *(contracts)* Add `initialOwner` to `initialize`
- *(contracts)* Update script to support `initialOwner`
- *(contracts)* Add ENS resolution methods to `LilNounsEnsMapperV2`

### 💼 Other

- *(contracts)* Enable additional foundry build options

### 🚜 Refactor

- *(contracts)* Rename subdomain references to subname

### 🧪 Testing

- *(contracts)* Reduce verbosity level in `test:forge`
- *(contracts)* Update `initialize` test to use `owner`
- *(contracts)* Add tests for `ensNameOf` method

## [1.0.0-alpha.10] - 2025-08-18

### 🚀 Features

- *(contracts)* Add `LilNounsEnsVault` for token management
- *(contracts)* Add `LilNounsEnsWrapper` for ENS integration
- *(contracts)* Add `LilNounsEnsMapper` for ENS integrations
- *(contracts)* Make `LilNounsEnsMapper` upgradeable
- *(contracts)* Add `ILilNounsEnsMapperV1` interface
- *(contracts)* Add `LilNounsEnsMapperV2` with enhanced features
- *(contracts)* Add `LilNounsEnsMapperV2` with enhanced features
- *(contracts)* Add `LilNounsEnsBase` and initial tests
- *(contracts)* Introduce `LilNounsEnsMapperV2`

### 🐛 Bug Fixes

- *(contracts)* Validate lengths in batch transfers
- *(web)* Ensure `VITE_WC_PROJECT_ID` defaults to string
- *(web)* Handle missing `#root` element in `main.tsx`
- *(contracts)* Add `view` to `_authorizeUpgrade` modifier

### 🚜 Refactor

- *(contracts)* Rename `LilNounsEnsVault` to `LilNounsEnsHolder`
- *(contracts)* Replace ENS interfaces with concrete imports
- *(contracts)* Use official ENS contract imports
- *(contracts)* Remove `Counter` example contract
- *(contracts)* Add storage gap to `LilNounsEnsHolder`
- *(contracts)* Simplify `LilNounsEnsMapper` inheritance
- *(contracts)* Update ENS contract import paths
- *(contracts)* Simplify `wrapEnsName` parameters
- *(contracts)* Update initializer to use addresses
- *(contracts)* Reorder variable initialization in constructor
- *(contracts)* Use address types in `initialize`
- *(contracts)* Remove section headers for clarity
- *(contracts)* Centralize error definitions in library
- *(contracts)* Disable specific solhint warnings
- *(contracts)* Remove unused ENS imports
- *(contracts)* Clarify `supportsInterface` documentation
- *(contracts)* Clarify `_authorizeUpgrade` docstring
- *(contracts)* Enhance ENS-related documentation
- *(contracts)* Index event parameters for better querying
- *(contracts)* Use typed interfaces in ENS checks
- *(contracts)* Disable solhint warning for init function
- *(contracts)* Rename LilNounsEnsVault to LilNounsEnsHolder
- *(contracts)* Enhance `supportsInterface` overrides
- *(contracts)* Improve variable naming for init function
- *(contracts)* Improve initializer parameter naming
- *(contracts)* Enhance `supportsInterface` logic
- *(contracts)* Remove `supportsInterface` override
- *(contracts)* Remove unused `setEnsContracts` and hooks
- *(contracts)* Rename `labelhash` to `labelHash`
- *(contracts)* Update `LilNounsEnsMapperV2` initializer
- *(contracts)* Update `LilNounsEnsMapperV2` interface handling
- *(contracts)* Revise exception handling in `wrapEnsName`
- *(web)* Remove redundant state in `CounterCard`
- *(web)* Optimize `ThemeProvider` with `useMemo`
- *(contracts)* Simplify test setup and mocks
- *(contracts)* Update test stubs to use `pure` functions
- *(contracts)* Extract reusable ENS resolver logic
- *(contracts)* Simplify parameter naming in `initialize`
- *(contracts)* Remove section headers for clarity
- *(contracts)* Streamline ENS modules with base contract
- *(contracts)* Improve ENS event param documentation
- *(contracts)* Rename `LilNounsEnsMapperV2` to `V3`
- *(contracts)* Remove redundant ENS contracts
- *(contracts)* Expand `ILilNounsEnsMapperV1` interface
- *(contracts)* Add `LilNounsEnsErrors` library
- *(contracts)* Rename initialization params for clarity
- *(contracts)* Ensure reentrancy safety in ENS calls
- *(contracts)* Enhance clarity and modularity in V2
- *(contracts)* Standardize for-loop initializations
- *(contracts)* Simplify comments and align doc style
- *(contracts)* Standardize for-loop and event usage
- *(contracts)* Remove section dividers for clarity
- *(contracts)* Simplify and clarify documentation
- *(contracts)* Add `AddrChanged` event emission
- *(contracts)* Simplify `emitAddrEvents` loop
- *(contracts)* Streamline documentation in error library
- *(contracts)* Enhance NatSpec clarity in V2 comments
- *(contracts)* Relocate `_authorizeUpgrade` definition
- *(contracts)* Enhance NatSpec for `claimSubdomain`
- *(contracts)* Enhance NatSpec for `restoreResolver`
- *(contracts)* Enhance NatSpec for `LilNounsEnsMapperV2`
- *(contracts)* Update `migrateSubdomainFromV1` logic
- *(contracts)* Improve NatSpec documentation in V2
- *(contracts)* Simplify `addr` function logic
- *(contracts)* Update `claimSubdomain` checks
- *(contracts)* Add `AlreadyClaimed` check in `claimSubdomain`
- *(contracts)* Remove redundant `slither-safe` comments
- *(contracts)* Use `bytes32(0)` for node comparison
- *(contracts)* Enhance text resolution and event emission logic
- *(contracts)* Add `InvalidLabel` error in ENS library
- *(contracts)* Add `InvalidLabel` check in `claimSubdomain`
- *(contracts)* Reserve storage space for future updates
- *(contracts)* Improve NatSpec comments and event usage
- *(contracts)* Optimize `for` loops with unchecked increments
- *(contracts)* Add reentrancy protection in key functions
- *(contracts)* Disable specific Slither checks in `__gap`
- *(contracts)* Add Slither checks to `emitAddrEvents`
- *(contracts)* Update NatSpec comments for clarity
- *(contracts)* Clarify `_authorizeUpgrade` implementation

### 📚 Documentation

- *(contracts)* Add `@author` tags to all ENS modules

### 🎨 Styling

- *(contracts)* Add `slither` directives for conventions
- *(web)* Disable `unicorn/prevent-abbreviations` in `vite-env.d.ts`
- *(web)* Reorder imports in `vite.config.ts`

### 🧪 Testing

- *(contracts)* Add tests for `LilNounsEnsMapperV2`
- *(contracts)* Add test stubs for ENS-related contracts
- *(contracts)* Update test stubs to use `pure` functions
- *(contracts)* Add skeleton test for `LilNounsEnsMapperV2`
- *(contracts)* Add comprehensive tests for `LilNounsEnsMapperV2`

## [1.0.0-alpha.9] - 2025-08-17

### 🐛 Bug Fixes

- Solve some minor issues and update dependencies

## [1.0.0-alpha.8] - 2025-08-04

### 🐛 Bug Fixes

- Solve some minor issues and update dependencies

## [1.0.0-alpha.7] - 2025-08-03

### 🐛 Bug Fixes

- Solve some minor issues and update dependencies

## [1.0.0-alpha.5] - 2025-07-31

### 🐛 Bug Fixes

- Solve some minor issues and update dependencies

## [1.0.0-alpha.4] - 2025-07-30

### 🐛 Bug Fixes

- Solve some minor issues and update dependencies

## [1.0.0-alpha.3] - 2025-07-14

### 🐛 Bug Fixes

- Solve some minor issues and update dependencies

## [1.0.0-alpha.2] - 2025-07-13

### 🐛 Bug Fixes

- Solve some minor issues and update dependencies

## [1.0.0-alpha.1] - 2025-07-02

### 🐛 Bug Fixes

- Solve some minor issues and update dependencies

## [1.0.0-alpha.0] - 2025-07-02

<!-- generated by git-cliff -->
