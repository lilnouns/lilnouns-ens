# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0-alpha.19] - 2025-09-05

### 🐛 Bug Fixes

- Solve some minor issues and update dependencies

## [1.0.0-alpha.18] - 2025-09-05

### 🚜 Refactor

- *(web)* Remove unused environment variables
- *(web)* Unify environment variables
- *(web)* Centralize runtime environment configuration
- *(web)* Simplify environment variable examples

## [1.0.0-alpha.17] - 2025-09-05

### 📚 Documentation

- *(root)* Add project README file

### 🎨 Styling

- *(web)* Remove redundant margin in subnames list

## [1.0.0-alpha.16] - 2025-09-05

### 🚀 Features

- *(contracts)* Add network-specific env var handling
- *(web)* Add subdomain claim functionality with UI updates
- *(web)* Add `ThemeToggle` for theme switching
- *(web)* Add Google Fonts integration
- *(ui)* Add `DropdownMenu` component
- *(web)* Add `WalletConnectButton` component
- *(web)* Extend `ImportMetaEnv` with custom env vars
- *(web)* Add chain resolution with environment variables
- *(web)* Extend `ImportMetaEnv` with `VITE_SUBGRAPH_URL`
- *(web)* Add example `.env` with `VITE_SUBGRAPH_URL`
- *(web)* Dedupe dependencies in Vite config
- *(web)* Add support for injected wallet detection
- *(web)* Add chain configuration options and update hooks
- *(web)* Add chain-specific RPC and subgraph URL support
- *(web)* Integrate on-chain Lil Nouns balance handling
- *(ui)* Add `Skeleton` component
- *(web)* Improve loading states for subdomain claim card
- *(web)* Add `SubdomainInstructions` component
- *(web)* Replace header text with logo and link
- *(web)* Replace inline logo with `Logo` component
- *(web)* Update `Logo` dimensions for consistency
- *(web)* Add distinct RPC URL environment variables
- *(web)* Add `NetworkGuard` component to handle networks
- *(config)* Add linting for JavaScript and TypeScript files
- *(config)* Add eslint auto-fix to lint-staged
- *(web)* Wrap `App` with `NetworkGuard`
- *(ui)* Add reusable `Dialog` component
- *(ui)* Add reusable `Input` component
- *(ui)* Add reusable `Label` component
- *(web)* Enhance subname claiming UX
- *(subdomain-claim-card)* Improve subdomain claim logic
- *(web)* Extract availability logic to separate hook
- *(web)* Integrate Lil Nouns data fetching
- *(web)* Enhance type safety and string handling
- *(web)* Add `OwnedSubnamesList` component to display user subnames
- *(ui)* Add `Tabs` component with flexible structure
- *(ui)* Add `Toaster` component for notifications
- *(web)* Integrate `Tabs` for subname management UI
- *(web)* Adjust `Tabs` container width for better layout
- *(web)* Enhance subname management with contextual actions
- *(web)* Display ENS subnames in NFT gallery dialog
- *(web)* Replace badge with dropdown for subnames
- *(web)* Add confirmation dialog for subname actions
- *(web)* Add tab behavior and claim confirmation dialog

### 🐛 Bug Fixes

- *(contracts)* Resolve `_ROOT_LABEL` naming inconsistency
- *(web)* Update subdomain placeholder text
- *(web)* Improve `SubdomainClaimCard` state handling
- *(web)* Handle undefined `tokenId` in `useReadLilNounsTokenTokenUri`

### 🚜 Refactor

- *(web)* Remove `WalletConnectButton` from claim card
- *(contracts)* Rename `ROOT_LABEL` to `ENS_ROOT_LABEL`
- *(web)* Update contract address and rename contract
- *(web)* Implement `LilNounsEnsMapper` contract hooks
- *(web)* Remove `CounterCard` component
- *(web)* Rename `subdomain` to `subname` in UI texts
- *(web)* Remove `registrarAbi` constant
- *(web)* Replace `useWriteContract` with generated hook
- *(web)* Replace `sepolia` with custom `chain` config
- *(web)* Update `toast`, `theme-toggle`, and `nft-gallery-dialog`
- *(web)* Replace `useContext` with `use` in `useTheme`
- *(web)* Update TS target to ES2021
- *(web)* Update app header title to `Lil Nouns`
- *(web)* Update `fetchOwnedLilNouns` for graphql-request
- *(web)* Improve typings and code readability
- *(web)* Update `fetchOwnedLilNouns` for address handling
- *(web)* Simplify subdomain claim states
- *(web)* Enforce chain validation in wallet actions
- *(web)* Extract `useSubdomainClaim` hook from claim card
- *(web)* Update `resolveRpcHttpUrl` for clarity
- *(web)* Improve variable naming and type usage
- *(config)* Centralize ESLint configuration
- *(web)* Integrate `Dialog` into `NftGalleryDialog` and `NetworkGuard`
- *(web)* Replace custom `ToastProvider` with `AppToaster`
- *(web)* Update `SubdomainClaimCard` to use `Input`, `Label`, and `sonner`
- *(web)* Improve `NetworkGuard` readability and maintainability
- *(web)* Rename subdomain to subname across components
- *(contracts)* Rename `subdomain` to `subname` in tests
- *(web)* Extract `title` for consistent NFT labeling
- *(web)* Simplify subname claim logic
- *(web)* Modularize subname claim logic
- *(web)* Modularize `useSubnameClaim` logic
- *(web-utils)* Improve typing in `shortenAddress`
- *(web)* Reorganize and modularize `subname-claim-card`
- *(web)* Use `pipe` and `map` for cleaner data processing
- *(web)* Replace array methods with remeda utilities
- *(web)* Replace array methods with `remeda` utilities
- *(web)* Enforce immutability in `appConfig`
- *(web)* Use `NonEmptyString` for stricter type safety
- *(web)* Use `fileURLToPath` for resolving paths
- *(web)* Remove `NonEmptyString` from `OwnedNft` types
- *(web)* Add type-safe handling for `chain` parsing
- *(web)* Improve type safety and refactor wallet logic
- *(web)* Update `toast` API usage for consistency
- *(web)* Improve readability with consistent formatting
- *(web)* Enhance `useRootName` fallback logic
- *(web)* Improve clipboard handling in buttons
- *(web)* Replace `map` with `remeda` utility
- *(web)* Use `remeda``s `isTruthy` for truthy checks
- *(web)* Extract and modularize subname claim logic
- *(web)* Update `ownedCount` to use `bigint`
- *(web)* Improve code consistency
- *(web)* Enhance nft gallery skeletons and item keys
- *(web)* Inline `TokenRowSkeleton` for cleaner structure
- *(web)* Reorder `owner` prop in `NftGalleryDialog`
- *(web)* Improve `ownedCount` nullish checks
- *(web)* Remove `contractHref` from `HeaderDescription`
- *(web)* Remove `ownedCount` from `useSubnameClaim`
- *(web)* Remove unused `useQuery` from `useOwnershipState`
- *(web)* Remove `subgraph-client` and unused `OwnedNft` type
- *(web)* Modularize `subname-claim` components
- *(web)* Enhance `subname` validation with `remeda`
- *(web)* Use specific hook for subname simulation
- *(web)* Improve `args` and query validation logic
- *(web)* Replace custom hook with `useQuery` for claims
- *(web)* Extract `getEnsNameHref` utility function
- *(ui)* Update component structure and clean code

### 🎨 Styling

- *(web)* Improve responsive layout and spacing
- *(ui)* Update theme variables and improve consistency
- *(ui)* Update font-family declarations
- *(ui)* Update `data-slot` attribute in `separator`
- *(web)* Reorder imports for improved readability
- *(web)* Adjust code style for consistency

## [1.0.0-alpha.15] - 2025-09-04

### 📚 Documentation

- *(web)* Add README with setup and usage instructions

## [1.0.0-alpha.14] - 2025-08-20

### 🐛 Bug Fixes

- *(contracts)* Prevent claiming existing ENS subnodes
- *(contracts)* Enhance error handling for ENS subnodes

### 🧪 Testing

- *(contracts)* Add test for claiming new label after relinquishing
- *(contracts)* Add test for pre-existing ENS subnodes
- *(contracts)* Disable lint on unsafe typecast in test

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
