import {
  createUseReadContract,
  createUseWriteContract,
  createUseSimulateContract,
  createUseWatchContractEvent,
} from 'wagmi/codegen'

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LilNounsEnsMapper
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const lilNounsEnsMapperAbi = [
  {
    type: 'error',
    inputs: [{ name: 'target', internalType: 'address', type: 'address' }],
    name: 'AddressEmptyCode',
  },
  {
    type: 'error',
    inputs: [{ name: 'tokenId', internalType: 'uint256', type: 'uint256' }],
    name: 'AlreadyClaimed',
  },
  {
    type: 'error',
    inputs: [
      { name: 'implementation', internalType: 'address', type: 'address' },
    ],
    name: 'ERC1967InvalidImplementation',
  },
  { type: 'error', inputs: [], name: 'ERC1967NonPayable' },
  { type: 'error', inputs: [], name: 'FailedCall' },
  { type: 'error', inputs: [], name: 'InvalidENSRegistry' },
  { type: 'error', inputs: [], name: 'InvalidInitialization' },
  { type: 'error', inputs: [], name: 'InvalidLabel' },
  { type: 'error', inputs: [], name: 'InvalidLegacyAddress' },
  {
    type: 'error',
    inputs: [{ name: 'tokenId', internalType: 'uint256', type: 'uint256' }],
    name: 'NotAuthorised',
  },
  { type: 'error', inputs: [], name: 'NotInitializing' },
  {
    type: 'error',
    inputs: [{ name: 'tokenId', internalType: 'uint256', type: 'uint256' }],
    name: 'NotTokenOwner',
  },
  { type: 'error', inputs: [], name: 'OverrideAvatarKey' },
  {
    type: 'error',
    inputs: [{ name: 'owner', internalType: 'address', type: 'address' }],
    name: 'OwnableInvalidOwner',
  },
  {
    type: 'error',
    inputs: [{ name: 'account', internalType: 'address', type: 'address' }],
    name: 'OwnableUnauthorizedAccount',
  },
  {
    type: 'error',
    inputs: [{ name: 'node', internalType: 'bytes32', type: 'bytes32' }],
    name: 'PreexistingENSRecord',
  },
  { type: 'error', inputs: [], name: 'ReentrancyGuardReentrantCall' },
  { type: 'error', inputs: [], name: 'UUPSUnauthorizedCallContext' },
  {
    type: 'error',
    inputs: [{ name: 'slot', internalType: 'bytes32', type: 'bytes32' }],
    name: 'UUPSUnsupportedProxiableUUID',
  },
  {
    type: 'error',
    inputs: [{ name: 'node', internalType: 'bytes32', type: 'bytes32' }],
    name: 'UnregisteredNode',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'node', internalType: 'bytes32', type: 'bytes32', indexed: true },
      { name: 'a', internalType: 'address', type: 'address', indexed: false },
    ],
    name: 'AddrChanged',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'version',
        internalType: 'uint64',
        type: 'uint64',
        indexed: false,
      },
    ],
    name: 'Initialized',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'node', internalType: 'bytes32', type: 'bytes32', indexed: true },
      { name: 'name', internalType: 'string', type: 'string', indexed: false },
    ],
    name: 'NameChanged',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'previousOwner',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'newOwner',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'OwnershipTransferStarted',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'previousOwner',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'newOwner',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'OwnershipTransferred',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'registrar',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'tokenId',
        internalType: 'uint256',
        type: 'uint256',
        indexed: true,
      },
      { name: 'node', internalType: 'bytes32', type: 'bytes32', indexed: true },
      { name: 'label', internalType: 'string', type: 'string', indexed: false },
    ],
    name: 'SubnameClaimed',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'node', internalType: 'bytes32', type: 'bytes32', indexed: true },
      {
        name: 'indexedKey',
        internalType: 'string',
        type: 'string',
        indexed: true,
      },
      { name: 'key', internalType: 'string', type: 'string', indexed: false },
      { name: 'value', internalType: 'string', type: 'string', indexed: false },
    ],
    name: 'TextChanged',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'node', internalType: 'bytes32', type: 'bytes32', indexed: true },
      {
        name: 'indexedKey',
        internalType: 'string',
        type: 'string',
        indexed: true,
      },
      { name: 'key', internalType: 'string', type: 'string', indexed: false },
    ],
    name: 'TextChanged',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'implementation',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'Upgraded',
  },
  {
    type: 'function',
    inputs: [],
    name: 'UPGRADE_INTERFACE_VERSION',
    outputs: [{ name: '', internalType: 'string', type: 'string' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'acceptOwnership',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'node', internalType: 'bytes32', type: 'bytes32' }],
    name: 'addr',
    outputs: [{ name: '', internalType: 'address payable', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'label', internalType: 'string', type: 'string' },
      { name: 'tokenId', internalType: 'uint256', type: 'uint256' },
    ],
    name: 'claimSubname',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'tokenIds', internalType: 'uint256[]', type: 'uint256[]' },
    ],
    name: 'emitAddrEvents',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'tokenIds', internalType: 'uint256[]', type: 'uint256[]' },
      { name: 'key', internalType: 'string', type: 'string' },
    ],
    name: 'emitTextEvents',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'ens',
    outputs: [{ name: '', internalType: 'contract ENS', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'tokenId', internalType: 'uint256', type: 'uint256' }],
    name: 'ensNameOf',
    outputs: [{ name: '', internalType: 'string', type: 'string' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'tokenId', internalType: 'uint256', type: 'uint256' }],
    name: 'ensNodeOf',
    outputs: [{ name: 'node', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'initialOwner', internalType: 'address', type: 'address' },
      { name: 'legacyAddr', internalType: 'address', type: 'address' },
      { name: 'ensRegistry', internalType: 'address', type: 'address' },
      { name: 'ensRoot', internalType: 'bytes32', type: 'bytes32' },
      { name: 'labelRoot', internalType: 'string', type: 'string' },
    ],
    name: 'initialize',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'node', internalType: 'bytes32', type: 'bytes32' }],
    name: 'isLegacyNode',
    outputs: [{ name: 'isLegacy', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'legacy',
    outputs: [
      {
        name: '',
        internalType: 'contract ILilNounsEnsMapperV1',
        type: 'address',
      },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'tokenId', internalType: 'uint256', type: 'uint256' }],
    name: 'migrateLegacySubname',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'node', internalType: 'bytes32', type: 'bytes32' }],
    name: 'name',
    outputs: [{ name: '', internalType: 'string', type: 'string' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'nft',
    outputs: [{ name: '', internalType: 'contract IERC721', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'owner',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'pendingOwner',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'proxiableUUID',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'tokenId', internalType: 'uint256', type: 'uint256' }],
    name: 'releaseLegacySubname',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'tokenId', internalType: 'uint256', type: 'uint256' }],
    name: 'relinquishSubname',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'renounceOwnership',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'tokenId', internalType: 'uint256', type: 'uint256' }],
    name: 'restoreResolver',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'rootLabel',
    outputs: [{ name: '', internalType: 'string', type: 'string' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'rootNode',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'node', internalType: 'bytes32', type: 'bytes32' },
      { name: 'key', internalType: 'string', type: 'string' },
      { name: 'value', internalType: 'string', type: 'string' },
    ],
    name: 'setText',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'interfaceId', internalType: 'bytes4', type: 'bytes4' }],
    name: 'supportsInterface',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'pure',
  },
  {
    type: 'function',
    inputs: [
      { name: 'node', internalType: 'bytes32', type: 'bytes32' },
      { name: 'key', internalType: 'string', type: 'string' },
    ],
    name: 'text',
    outputs: [{ name: '', internalType: 'string', type: 'string' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'newOwner', internalType: 'address', type: 'address' }],
    name: 'transferOwnership',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'newImplementation', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'upgradeToAndCall',
    outputs: [],
    stateMutability: 'payable',
  },
] as const

/**
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const lilNounsEnsMapperAddress = {
  11155111: '0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc',
} as const

/**
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const lilNounsEnsMapperConfig = {
  address: lilNounsEnsMapperAddress,
  abi: lilNounsEnsMapperAbi,
} as const

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// React
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapper = /*#__PURE__*/ createUseReadContract({
  abi: lilNounsEnsMapperAbi,
  address: lilNounsEnsMapperAddress,
})

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"UPGRADE_INTERFACE_VERSION"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperUpgradeInterfaceVersion =
  /*#__PURE__*/ createUseReadContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'UPGRADE_INTERFACE_VERSION',
  })

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"addr"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperAddr = /*#__PURE__*/ createUseReadContract(
  {
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'addr',
  },
)

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"ens"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperEns = /*#__PURE__*/ createUseReadContract({
  abi: lilNounsEnsMapperAbi,
  address: lilNounsEnsMapperAddress,
  functionName: 'ens',
})

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"ensNameOf"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperEnsNameOf =
  /*#__PURE__*/ createUseReadContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'ensNameOf',
  })

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"ensNodeOf"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperEnsNodeOf =
  /*#__PURE__*/ createUseReadContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'ensNodeOf',
  })

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"isLegacyNode"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperIsLegacyNode =
  /*#__PURE__*/ createUseReadContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'isLegacyNode',
  })

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"legacy"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperLegacy =
  /*#__PURE__*/ createUseReadContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'legacy',
  })

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"name"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperName = /*#__PURE__*/ createUseReadContract(
  {
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'name',
  },
)

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"nft"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperNft = /*#__PURE__*/ createUseReadContract({
  abi: lilNounsEnsMapperAbi,
  address: lilNounsEnsMapperAddress,
  functionName: 'nft',
})

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"owner"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperOwner =
  /*#__PURE__*/ createUseReadContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'owner',
  })

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"pendingOwner"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperPendingOwner =
  /*#__PURE__*/ createUseReadContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'pendingOwner',
  })

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"proxiableUUID"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperProxiableUuid =
  /*#__PURE__*/ createUseReadContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'proxiableUUID',
  })

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"rootLabel"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperRootLabel =
  /*#__PURE__*/ createUseReadContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'rootLabel',
  })

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"rootNode"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperRootNode =
  /*#__PURE__*/ createUseReadContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'rootNode',
  })

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"supportsInterface"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperSupportsInterface =
  /*#__PURE__*/ createUseReadContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'supportsInterface',
  })

/**
 * Wraps __{@link useReadContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"text"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useReadLilNounsEnsMapperText = /*#__PURE__*/ createUseReadContract(
  {
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'text',
  },
)

/**
 * Wraps __{@link useWriteContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWriteLilNounsEnsMapper = /*#__PURE__*/ createUseWriteContract({
  abi: lilNounsEnsMapperAbi,
  address: lilNounsEnsMapperAddress,
})

/**
 * Wraps __{@link useWriteContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"acceptOwnership"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWriteLilNounsEnsMapperAcceptOwnership =
  /*#__PURE__*/ createUseWriteContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'acceptOwnership',
  })

/**
 * Wraps __{@link useWriteContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"claimSubname"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWriteLilNounsEnsMapperClaimSubname =
  /*#__PURE__*/ createUseWriteContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'claimSubname',
  })

/**
 * Wraps __{@link useWriteContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"emitAddrEvents"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWriteLilNounsEnsMapperEmitAddrEvents =
  /*#__PURE__*/ createUseWriteContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'emitAddrEvents',
  })

/**
 * Wraps __{@link useWriteContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"emitTextEvents"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWriteLilNounsEnsMapperEmitTextEvents =
  /*#__PURE__*/ createUseWriteContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'emitTextEvents',
  })

/**
 * Wraps __{@link useWriteContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"initialize"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWriteLilNounsEnsMapperInitialize =
  /*#__PURE__*/ createUseWriteContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'initialize',
  })

/**
 * Wraps __{@link useWriteContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"migrateLegacySubname"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWriteLilNounsEnsMapperMigrateLegacySubname =
  /*#__PURE__*/ createUseWriteContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'migrateLegacySubname',
  })

/**
 * Wraps __{@link useWriteContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"releaseLegacySubname"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWriteLilNounsEnsMapperReleaseLegacySubname =
  /*#__PURE__*/ createUseWriteContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'releaseLegacySubname',
  })

/**
 * Wraps __{@link useWriteContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"relinquishSubname"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWriteLilNounsEnsMapperRelinquishSubname =
  /*#__PURE__*/ createUseWriteContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'relinquishSubname',
  })

/**
 * Wraps __{@link useWriteContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"renounceOwnership"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWriteLilNounsEnsMapperRenounceOwnership =
  /*#__PURE__*/ createUseWriteContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'renounceOwnership',
  })

/**
 * Wraps __{@link useWriteContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"restoreResolver"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWriteLilNounsEnsMapperRestoreResolver =
  /*#__PURE__*/ createUseWriteContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'restoreResolver',
  })

/**
 * Wraps __{@link useWriteContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"setText"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWriteLilNounsEnsMapperSetText =
  /*#__PURE__*/ createUseWriteContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'setText',
  })

/**
 * Wraps __{@link useWriteContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"transferOwnership"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWriteLilNounsEnsMapperTransferOwnership =
  /*#__PURE__*/ createUseWriteContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'transferOwnership',
  })

/**
 * Wraps __{@link useWriteContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"upgradeToAndCall"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWriteLilNounsEnsMapperUpgradeToAndCall =
  /*#__PURE__*/ createUseWriteContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'upgradeToAndCall',
  })

/**
 * Wraps __{@link useSimulateContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useSimulateLilNounsEnsMapper =
  /*#__PURE__*/ createUseSimulateContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
  })

/**
 * Wraps __{@link useSimulateContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"acceptOwnership"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useSimulateLilNounsEnsMapperAcceptOwnership =
  /*#__PURE__*/ createUseSimulateContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'acceptOwnership',
  })

/**
 * Wraps __{@link useSimulateContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"claimSubname"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useSimulateLilNounsEnsMapperClaimSubname =
  /*#__PURE__*/ createUseSimulateContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'claimSubname',
  })

/**
 * Wraps __{@link useSimulateContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"emitAddrEvents"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useSimulateLilNounsEnsMapperEmitAddrEvents =
  /*#__PURE__*/ createUseSimulateContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'emitAddrEvents',
  })

/**
 * Wraps __{@link useSimulateContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"emitTextEvents"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useSimulateLilNounsEnsMapperEmitTextEvents =
  /*#__PURE__*/ createUseSimulateContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'emitTextEvents',
  })

/**
 * Wraps __{@link useSimulateContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"initialize"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useSimulateLilNounsEnsMapperInitialize =
  /*#__PURE__*/ createUseSimulateContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'initialize',
  })

/**
 * Wraps __{@link useSimulateContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"migrateLegacySubname"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useSimulateLilNounsEnsMapperMigrateLegacySubname =
  /*#__PURE__*/ createUseSimulateContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'migrateLegacySubname',
  })

/**
 * Wraps __{@link useSimulateContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"releaseLegacySubname"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useSimulateLilNounsEnsMapperReleaseLegacySubname =
  /*#__PURE__*/ createUseSimulateContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'releaseLegacySubname',
  })

/**
 * Wraps __{@link useSimulateContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"relinquishSubname"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useSimulateLilNounsEnsMapperRelinquishSubname =
  /*#__PURE__*/ createUseSimulateContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'relinquishSubname',
  })

/**
 * Wraps __{@link useSimulateContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"renounceOwnership"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useSimulateLilNounsEnsMapperRenounceOwnership =
  /*#__PURE__*/ createUseSimulateContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'renounceOwnership',
  })

/**
 * Wraps __{@link useSimulateContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"restoreResolver"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useSimulateLilNounsEnsMapperRestoreResolver =
  /*#__PURE__*/ createUseSimulateContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'restoreResolver',
  })

/**
 * Wraps __{@link useSimulateContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"setText"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useSimulateLilNounsEnsMapperSetText =
  /*#__PURE__*/ createUseSimulateContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'setText',
  })

/**
 * Wraps __{@link useSimulateContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"transferOwnership"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useSimulateLilNounsEnsMapperTransferOwnership =
  /*#__PURE__*/ createUseSimulateContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'transferOwnership',
  })

/**
 * Wraps __{@link useSimulateContract}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `functionName` set to `"upgradeToAndCall"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useSimulateLilNounsEnsMapperUpgradeToAndCall =
  /*#__PURE__*/ createUseSimulateContract({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    functionName: 'upgradeToAndCall',
  })

/**
 * Wraps __{@link useWatchContractEvent}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWatchLilNounsEnsMapperEvent =
  /*#__PURE__*/ createUseWatchContractEvent({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
  })

/**
 * Wraps __{@link useWatchContractEvent}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `eventName` set to `"AddrChanged"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWatchLilNounsEnsMapperAddrChangedEvent =
  /*#__PURE__*/ createUseWatchContractEvent({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    eventName: 'AddrChanged',
  })

/**
 * Wraps __{@link useWatchContractEvent}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `eventName` set to `"Initialized"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWatchLilNounsEnsMapperInitializedEvent =
  /*#__PURE__*/ createUseWatchContractEvent({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    eventName: 'Initialized',
  })

/**
 * Wraps __{@link useWatchContractEvent}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `eventName` set to `"NameChanged"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWatchLilNounsEnsMapperNameChangedEvent =
  /*#__PURE__*/ createUseWatchContractEvent({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    eventName: 'NameChanged',
  })

/**
 * Wraps __{@link useWatchContractEvent}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `eventName` set to `"OwnershipTransferStarted"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWatchLilNounsEnsMapperOwnershipTransferStartedEvent =
  /*#__PURE__*/ createUseWatchContractEvent({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    eventName: 'OwnershipTransferStarted',
  })

/**
 * Wraps __{@link useWatchContractEvent}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `eventName` set to `"OwnershipTransferred"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWatchLilNounsEnsMapperOwnershipTransferredEvent =
  /*#__PURE__*/ createUseWatchContractEvent({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    eventName: 'OwnershipTransferred',
  })

/**
 * Wraps __{@link useWatchContractEvent}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `eventName` set to `"SubnameClaimed"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWatchLilNounsEnsMapperSubnameClaimedEvent =
  /*#__PURE__*/ createUseWatchContractEvent({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    eventName: 'SubnameClaimed',
  })

/**
 * Wraps __{@link useWatchContractEvent}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `eventName` set to `"TextChanged"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWatchLilNounsEnsMapperTextChangedEvent =
  /*#__PURE__*/ createUseWatchContractEvent({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    eventName: 'TextChanged',
  })

/**
 * Wraps __{@link useWatchContractEvent}__ with `abi` set to __{@link lilNounsEnsMapperAbi}__ and `eventName` set to `"Upgraded"`
 *
 * [__View Contract on Sepolia Etherscan__](https://sepolia.etherscan.io/address/0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc)
 */
export const useWatchLilNounsEnsMapperUpgradedEvent =
  /*#__PURE__*/ createUseWatchContractEvent({
    abi: lilNounsEnsMapperAbi,
    address: lilNounsEnsMapperAddress,
    eventName: 'Upgraded',
  })
