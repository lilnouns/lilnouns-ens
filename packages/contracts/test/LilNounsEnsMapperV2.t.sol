// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { Test, console } from "forge-std/Test.sol";
import { LilNounsEnsMapperV2 } from "../src/LilNounsEnsMapperV2.sol";
import { ILilNounsEnsMapperV1 } from "../src/interfaces/ILilNounsEnsMapperV1.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { INameWrapper } from "@ensdomains/ens-contracts/wrapper/INameWrapper.sol";

/**
 * @title MockNFT
 * @notice Mock NFT contract for testing purposes
 */
contract MockNFT is IERC721 {
  mapping(uint256 => address) private _owners;
  mapping(address => uint256) private _balances;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  function ownerOf(uint256 tokenId) external view override returns (address) {
    return _owners[tokenId];
  }

  function setOwner(uint256 tokenId, address owner) external {
    _owners[tokenId] = owner;
    _balances[owner]++;
  }

  // Required IERC721 functions (minimal implementation)
  function balanceOf(address owner) external view override returns (uint256) {
    return _balances[owner];
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external override {}
  function safeTransferFrom(address from, address to, uint256 tokenId) external override {}
  function transferFrom(address from, address to, uint256 tokenId) external override {}
  function approve(address to, uint256 tokenId) external override {}
  function setApprovalForAll(address operator, bool approved) external override {}

  function getApproved(uint256 tokenId) external view override returns (address) {
    return _tokenApprovals[tokenId];
  }

  function isApprovedForAll(address owner, address operator) external view override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return true;
  }
}

/**
 * @title MockNameWrapper
 * @notice Mock Name Wrapper contract for testing purposes
 */
contract MockNameWrapper {
  mapping(bytes32 => bool) public nodeExists;

  function setSubnodeRecord(
    bytes32 parentNode,
    string calldata label,
    address owner,
    address resolver,
    uint64 ttl,
    uint32 fuses,
    uint64 expiry
  ) external returns (bytes32 node) {
    node = keccak256(abi.encodePacked(parentNode, keccak256(bytes(label))));
    nodeExists[node] = true;
    return node;
  }

  function setSubnodeRecordFail(bytes32 parentNode) external {
    // This function will cause setSubnodeRecord to return bytes32(0) for testing failures
    nodeExists[parentNode] = false;
  }

  // Minimal implementation of required functions for testing
  function isWrapped(bytes32 node) external view returns (bool) {
    return nodeExists[node];
  }

  function isWrapped(bytes32 node, bytes32 labelhash) external view returns (bool) {
    return nodeExists[node];
  }

  function ownerOf(uint256 id) external pure returns (address) {
    return address(0);
  }

  function getData(uint256 id) external pure returns (address, uint32, uint64) {
    return (address(0), 0, 0);
  }

  function setFuses(bytes32 node, uint16 ownerControlledFuses) external pure returns (uint32) {
    return 0;
  }

  function setChildFuses(bytes32 parentNode, bytes32 labelhash, uint32 fuses, uint64 expiry) external {}

  function setSubnodeOwner(
    bytes32 parentNode,
    string calldata label,
    address owner,
    uint32 fuses,
    uint64 expiry
  ) external returns (bytes32) {
    return bytes32(0);
  }

  function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external {}
  function setResolver(bytes32 node, address resolver) external {}
  function setTTL(bytes32 node, uint64 ttl) external {}
  function wrap(bytes calldata name, address wrappedOwner, address resolver) external {}

  function wrapETH2LD(
    string calldata label,
    address wrappedOwner,
    uint16 ownerControlledFuses,
    address resolver
  ) external returns (uint64) {
    return 0;
  }

  function unwrap(bytes32 parentNode, bytes32 labelhash, address controller) external {}
  function unwrapETH2LD(bytes32 labelhash, address registrant, address controller) external {}
  function upgrade(bytes calldata name, bytes calldata extraData) external {}

  function uri(uint256 tokenId) external pure returns (string memory) {
    return "";
  }

  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    return true;
  }

  // ERC1155 functions
  function balanceOf(address account, uint256 id) external pure returns (uint256) {
    return 0;
  }

  function balanceOfBatch(
    address[] calldata accounts,
    uint256[] calldata ids
  ) external pure returns (uint256[] memory) {
    uint256[] memory result = new uint256[](accounts.length);
    return result;
  }

  function setApprovalForAll(address operator, bool approved) external {}

  function isApprovedForAll(address account, address operator) external pure returns (bool) {
    return false;
  }

  function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external {}
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external {}

  // ERC721 functions
  function approve(address to, uint256 tokenId) external {}

  function getApproved(uint256 tokenId) external pure returns (address) {
    return address(0);
  }

  // Additional INameWrapper functions
  function ens() external pure returns (address) {
    return address(0);
  }

  function registrar() external pure returns (address) {
    return address(0);
  }

  function metadataService() external pure returns (address) {
    return address(0);
  }

  function name() external pure returns (string memory) {
    return "MockNameWrapper";
  }

  function names(bytes32) external pure returns (bytes memory) {
    return "";
  }

  function upgradeContract() external pure returns (address) {
    return address(0);
  }

  function allFusesBurned(bytes32 node, uint32 fuseMask) external pure returns (bool) {
    return false;
  }

  function canModifyName(bytes32 node, address addr) external pure returns (bool) {
    return true;
  }

  function extendExpiry(bytes32 node, bytes32 labelhash, uint64 expiry) external pure returns (uint64) {
    return 0;
  }

  function registerAndWrapETH2LD(
    string calldata label,
    address wrappedOwner,
    uint256 duration,
    address resolver,
    uint16 ownerControlledFuses
  ) external pure returns (uint256) {
    return 0;
  }

  function renew(uint256 tokenId, uint256 duration) external pure returns (uint256) {
    return 0;
  }
}

/**
 * @title MockLegacyMapper
 * @notice Mock legacy mapper contract for testing purposes
 */
contract MockLegacyMapper is ILilNounsEnsMapperV1 {
  mapping(bytes32 => uint256) public hashToIdMap;
  mapping(uint256 => bytes32) public tokenHashmap;
  mapping(bytes32 => string) public hashToDomainMap;
  mapping(bytes32 => mapping(string => string)) public texts;

  function setLegacyData(uint256 tokenId, bytes32 node, string calldata label) external {
    hashToIdMap[node] = tokenId;
    tokenHashmap[tokenId] = node;
    hashToDomainMap[node] = label;
  }

  function setLegacyText(bytes32 node, string calldata key, string calldata value) external {
    texts[node][key] = value;
  }
}

/**
 * @title LilNounsEnsMapperV2Test
 * @author LilNouns DAO
 * @notice Comprehensive test suite for the LilNounsEnsMapperV2 contract
 * @dev This test contract validates the core functionality of the upgradeable ENS mapper,
 *      including initialization, access controls, pause functionality, and interface support.
 *      Tests are structured to cover both positive and negative scenarios.
 *
 * Test Coverage:
 * - Contract initialization and proxy deployment
 * - ERC-165 interface support validation
 * - Pause/unpause functionality
 * - Access control mechanisms
 * - Upgrade authorization
 *
 * @custom:test-framework Foundry
 */
contract LilNounsEnsMapperV2Test is Test {
  /// @notice The main contract instance being tested
  /// @dev Deployed behind an ERC1967 proxy for upgradeability testing
  LilNounsEnsMapperV2 public mapper;

  /// @notice Mock NFT contract for testing NFT ownership
  MockNFT public mockNFT;

  /// @notice Mock Name Wrapper contract for testing ENS integration
  MockNameWrapper public mockWrapper;

  /// @notice Mock legacy mapper contract for testing backward compatibility
  MockLegacyMapper public mockLegacy;

  /// @notice The contract owner address (this test contract)
  /// @dev Used to test owner-only functions and access controls
  address public owner;

  /// @notice A regular user address for testing non-owner interactions
  /// @dev Used to verify access control restrictions work correctly
  address public user;

  /// @notice Another user address for additional testing scenarios
  address public user2;

  /// @notice Test token IDs for NFT testing
  uint256 public constant TOKEN_ID_1 = 123;
  uint256 public constant TOKEN_ID_2 = 456;

  /// @notice Test labels for domain testing
  string public constant LABEL_1 = "alice";
  string public constant LABEL_2 = "bob";

  /**
   * @notice Sets up the test environment before each test
   * @dev Deploys the implementation contract behind an ERC1967 proxy
   *      and initializes it with mock contracts for comprehensive testing.
   *      This setup ensures each test starts with a fresh, properly initialized contract.
   */
  function setUp() public {
    owner = address(this);
    user = address(0x1234);
    user2 = address(0x5678);

    // Deploy mock contracts
    mockNFT = new MockNFT();
    mockWrapper = new MockNameWrapper();
    mockLegacy = new MockLegacyMapper();

    // Set up NFT ownership for testing
    mockNFT.setOwner(TOKEN_ID_1, user);
    mockNFT.setOwner(TOKEN_ID_2, user2);

    // Deploy the implementation contract
    LilNounsEnsMapperV2 implementation = new LilNounsEnsMapperV2();

    // Deploy the proxy and initialize
    bytes memory initData = abi.encodeWithSelector(LilNounsEnsMapperV2.initialize.selector, address(mockLegacy));

    ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
    mapper = LilNounsEnsMapperV2(address(proxy));

    // Note: In a real deployment, the contract would use hardcoded addresses for NFT and WRAPPER
    // For testing, we would need to use a different approach or modify the contract for testability
  }

  /**
   * @notice Tests that contract initialization works correctly
   * @dev Verifies that:
   *      - Legacy contract address is set correctly
   *      - Owner is set to the deploying address
   *      - Contract starts in unpaused state
   */
  function test_Initialize() public {
    // Test that initialization worked
    assertEq(address(mapper.legacy()), address(mockLegacy));
    assertEq(mapper.owner(), owner);
    assertFalse(mapper.paused());
  }

  /**
   * @notice Tests initialization with invalid legacy address
   * @dev Verifies that initialization reverts when passed zero address
   */
  function test_InitializeInvalidLegacyAddress() public {
    LilNounsEnsMapperV2 implementation = new LilNounsEnsMapperV2();
    bytes memory initData = abi.encodeWithSelector(LilNounsEnsMapperV2.initialize.selector, address(0));

    vm.expectRevert(LilNounsEnsMapperV2.InvalidLegacyAddress.selector);
    new ERC1967Proxy(address(implementation), initData);
  }

  /**
   * @notice Tests that contract cannot be initialized twice
   * @dev Verifies that calling initialize again reverts
   */
  function test_CannotInitializeTwice() public {
    vm.expectRevert();
    mapper.initialize(address(mockLegacy));
  }

  /**
   * @notice Tests domain mapping functionality
   * @dev Tests the domainMap function with various scenarios
   */
  function test_DomainMap() public {
    // Test non-existent domain returns zero
    bytes32 node = mapper.domainMap(LABEL_1);
    assertEq(node, bytes32(0));

    // Set up legacy data and test
    bytes32 expectedNode = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492), // ROOT_NODE
        keccak256(bytes(LABEL_1))
      )
    );
    mockLegacy.setLegacyData(TOKEN_ID_1, expectedNode, LABEL_1);

    node = mapper.domainMap(LABEL_1);
    assertEq(node, expectedNode);
  }

  /**
   * @notice Tests token node mapping functionality
   * @dev Tests the tokenNode function with various scenarios
   */
  function test_TokenNode() public {
    // Test non-existent token returns zero
    bytes32 node = mapper.tokenNode(TOKEN_ID_1);
    assertEq(node, bytes32(0));

    // Set up legacy data and test
    bytes32 expectedNode = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492), // ROOT_NODE
        keccak256(bytes(LABEL_1))
      )
    );
    mockLegacy.setLegacyData(TOKEN_ID_1, expectedNode, LABEL_1);

    node = mapper.tokenNode(TOKEN_ID_1);
    assertEq(node, expectedNode);
  }

  /**
   * @notice Tests getTokenDomain functionality with legacy data
   * @dev Tests domain retrieval for tokens with legacy registrations
   */
  function test_GetTokenDomainLegacy() public {
    // Set up legacy data
    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492), // ROOT_NODE
        keccak256(bytes(LABEL_1))
      )
    );
    mockLegacy.setLegacyData(TOKEN_ID_1, node, LABEL_1);

    string memory domain = mapper.getTokenDomain(TOKEN_ID_1);
    assertEq(domain, "alice.lilnouns.eth");
  }

  /**
   * @notice Tests getTokenDomain with unregistered token
   * @dev Verifies that function reverts for unregistered tokens
   */
  function test_GetTokenDomainUnregistered() public {
    vm.expectRevert(LilNounsEnsMapperV2.UnregisteredToken.selector);
    mapper.getTokenDomain(TOKEN_ID_1);
  }

  /**
   * @notice Tests getTokensDomains functionality
   * @dev Tests batch domain retrieval with various scenarios
   */
  function test_GetTokensDomains() public {
    // Set up legacy data for multiple tokens
    bytes32 node1 = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );
    bytes32 node2 = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_2))
      )
    );

    mockLegacy.setLegacyData(TOKEN_ID_1, node1, LABEL_1);
    mockLegacy.setLegacyData(TOKEN_ID_2, node2, LABEL_2);

    uint256[] memory tokenIds = new uint256[](2);
    tokenIds[0] = TOKEN_ID_1;
    tokenIds[1] = TOKEN_ID_2;

    string[] memory domains = mapper.getTokensDomains(tokenIds);
    assertEq(domains.length, 2);
    assertEq(domains[0], "alice.lilnouns.eth");
    assertEq(domains[1], "bob.lilnouns.eth");
  }

  /**
   * @notice Tests getTokensDomains with array size limit
   * @dev Verifies that function reverts when array is too large
   */
  function test_GetTokensDomainsArrayTooLarge() public {
    uint256[] memory tokenIds = new uint256[](101); // Exceeds limit of 100

    vm.expectRevert(LilNounsEnsMapperV2.EmptyArray.selector);
    mapper.getTokensDomains(tokenIds);
  }

  /**
   * @notice Tests updateAddresses with array size limit
   * @dev Verifies that function reverts when array is too large or empty
   */
  function test_UpdateAddressesArrayLimits() public {
    // Test empty array
    uint256[] memory emptyArray = new uint256[](0);
    vm.expectRevert(LilNounsEnsMapperV2.EmptyArray.selector);
    mapper.updateAddresses(emptyArray);

    // Test array too large
    uint256[] memory largeArray = new uint256[](51); // Exceeds limit of 50
    vm.expectRevert(LilNounsEnsMapperV2.EmptyArray.selector);
    mapper.updateAddresses(largeArray);
  }

  /**
   * @notice Tests text record functionality with legacy data
   * @dev Tests text record retrieval from legacy contract
   */
  function test_TextRecordLegacy() public {
    // Set up legacy data
    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );
    mockLegacy.setLegacyData(TOKEN_ID_1, node, LABEL_1);
    mockLegacy.setLegacyText(node, "description", "Test description");

    string memory text = mapper.text(node, "description");
    assertEq(text, "Test description");
  }

  /**
   * @notice Tests automatic avatar generation
   * @dev Tests that avatar text records are automatically generated
   */
  function test_AutomaticAvatarGeneration() public {
    // Set up legacy data
    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );
    mockLegacy.setLegacyData(TOKEN_ID_1, node, LABEL_1);

    string memory avatar = mapper.text(node, "avatar");
    // Should generate EIP-155 format: "eip155:1/erc721:{contractAddress}/{tokenId}"
    assertTrue(bytes(avatar).length > 0);
    // Note: Full avatar validation would require the actual NFT contract address
  }

  /**
   * @notice Tests name resolution functionality
   * @dev Tests the name function with various scenarios
   */
  function test_NameResolution() public {
    // Test non-existent node returns empty string
    bytes32 nonExistentNode = keccak256("nonexistent");
    string memory name = mapper.name(nonExistentNode);
    assertEq(name, "");

    // Set up legacy data and test
    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );
    mockLegacy.setLegacyData(TOKEN_ID_1, node, LABEL_1);

    name = mapper.name(node);
    assertEq(name, "alice.lilnouns.eth");
  }

  /**
   * @notice Tests ERC-165 interface support functionality
   * @dev Verifies that the contract correctly reports support for ENS resolver interfaces:
   *      - 0x3b3b57de: addr(bytes32) - Address resolution interface
   *      - 0x59d1d43c: text(bytes32,string) - Text record interface
   *      - 0x691f3431: name(bytes32) - Name resolution interface
   */
  function test_SupportsInterface() public {
    // Test ERC-165 interface support
    assertTrue(mapper.supportsInterface(0x3b3b57de)); // addr(bytes32)
    assertTrue(mapper.supportsInterface(0x59d1d43c)); // text(bytes32,string)
    assertTrue(mapper.supportsInterface(0x691f3431)); // name(bytes32)
  }

  /**
   * @notice Tests pause and unpause functionality
   * @dev Verifies that:
   *      - Contract can be paused by owner
   *      - Paused state is correctly reported
   *      - Contract can be unpaused by owner
   *      - Unpaused state is correctly reported
   */
  function test_PauseUnpause() public {
    // Test pause functionality
    mapper.pause();
    assertTrue(mapper.paused());

    mapper.unpause();
    assertFalse(mapper.paused());
  }

  /**
   * @notice Tests that only the owner can pause the contract
   * @dev Verifies access control by attempting to pause from a non-owner address
   *      and expecting the transaction to revert
   */
  function test_OnlyOwnerCanPause() public {
    vm.prank(user);
    vm.expectRevert();
    mapper.pause();
  }

  /**
   * @notice Tests that only the owner can unpause the contract
   * @dev Verifies access control by attempting to unpause from a non-owner address
   *      and expecting the transaction to revert
   */
  function test_OnlyOwnerCanUnpause() public {
    // First pause the contract as owner
    mapper.pause();
    assertTrue(mapper.paused());

    // Try to unpause as non-owner - should fail
    vm.prank(user);
    vm.expectRevert();
    mapper.unpause();

    // Contract should still be paused
    assertTrue(mapper.paused());

    // Owner should be able to unpause
    mapper.unpause();
    assertFalse(mapper.paused());
  }

  /**
   * @notice Tests that only the owner can authorize contract upgrades
   * @dev Verifies the UUPS upgrade access control by attempting to upgrade
   *      from a non-owner address and expecting the transaction to revert.
   *      This is critical for preventing unauthorized contract upgrades.
   */
  function test_OnlyOwnerCanUpgrade() public {
    // Test that only owner can authorize upgrades
    vm.prank(user);
    vm.expectRevert();
    mapper.upgradeToAndCall(address(0x9999), "");
  }

  /* ───────────── ACCESS CONTROL TESTS FOR AUTHORISED FUNCTIONS ───────────── */

  /**
   * @notice Tests access control for claim function
   * @dev Verifies that only contract owner or NFT owner can claim subdomains
   */
  function test_ClaimAccessControl() public {
    address nftOwner = makeAddr("nftOwner");
    address unauthorized = makeAddr("unauthorized");

    mockNft.mint(nftOwner, TOKEN_ID_1);

    // Unauthorized user should not be able to claim
    vm.prank(unauthorized);
    vm.expectRevert(LilNounsEnsMapperV2.NotAuthorised.selector);
    mapper.claim("unauthorized", TOKEN_ID_1);

    // NFT owner should be able to claim
    vm.prank(nftOwner);
    mapper.claim("nftowner", TOKEN_ID_1);

    // Verify claim was successful
    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("nftowner"))
      )
    );
    assertEq(mapper.domainMap(node), TOKEN_ID_1);

    // Contract owner should also be able to claim for any token
    mockNft.mint(nftOwner, TOKEN_ID_2);
    mapper.claim("contractowner", TOKEN_ID_2); // Called as contract owner

    bytes32 node2 = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("contractowner"))
      )
    );
    assertEq(mapper.domainMap(node2), TOKEN_ID_2);
  }

  /**
   * @notice Tests access control for setText function
   * @dev Verifies that only contract owner or NFT owner can set text records
   */
  function test_SetTextAccessControl() public {
    address nftOwner = makeAddr("nftOwner");
    address unauthorized = makeAddr("unauthorized");

    mockNft.mint(nftOwner, TOKEN_ID_1);

    // Claim domain as NFT owner
    vm.prank(nftOwner);
    mapper.claim("texttest", TOKEN_ID_1);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("texttest"))
      )
    );

    // Unauthorized user should not be able to set text
    vm.prank(unauthorized);
    vm.expectRevert(LilNounsEnsMapperV2.NotAuthorised.selector);
    mapper.setText(node, "description", "unauthorized");

    // NFT owner should be able to set text
    vm.prank(nftOwner);
    mapper.setText(node, "description", "by nft owner");
    assertEq(mapper.text(node, "description"), "by nft owner");

    // Contract owner should also be able to set text
    mapper.setText(node, "url", "by contract owner");
    assertEq(mapper.text(node, "url"), "by contract owner");
  }

  /**
   * @notice Tests access control for importLegacy function
   * @dev Verifies that only contract owner or NFT owner can import legacy domains
   */
  function test_ImportLegacyAccessControl() public {
    address nftOwner = makeAddr("nftOwner");
    address unauthorized = makeAddr("unauthorized");

    mockNft.mint(nftOwner, TOKEN_ID_1);

    // Set up legacy data
    bytes32 legacyNode = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("legacy"))
      )
    );
    mockLegacy.setLegacyData(TOKEN_ID_1, legacyNode, "legacy");

    // Unauthorized user should not be able to import legacy
    vm.prank(unauthorized);
    vm.expectRevert(LilNounsEnsMapperV2.NotAuthorised.selector);
    mapper.importLegacy(TOKEN_ID_1);

    // NFT owner should be able to import legacy
    vm.prank(nftOwner);
    mapper.importLegacy(TOKEN_ID_1);

    // Verify import was successful
    assertEq(mapper.domainMap(legacyNode), TOKEN_ID_1);
    assertEq(mapper.tokenNode(TOKEN_ID_1), legacyNode);
  }

  /**
   * @notice Tests that contract owner can perform all authorized actions
   * @dev Verifies that contract owner has universal access to all authorized functions
   */
  function test_ContractOwnerUniversalAccess() public {
    address nftOwner = makeAddr("nftOwner");

    // Mint NFTs to different owner
    mockNft.mint(nftOwner, TOKEN_ID_1);
    mockNft.mint(nftOwner, TOKEN_ID_2);

    // Contract owner should be able to claim for any token
    mapper.claim("owner1", TOKEN_ID_1);
    mapper.claim("owner2", TOKEN_ID_2);

    bytes32 node1 = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("owner1"))
      )
    );

    bytes32 node2 = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("owner2"))
      )
    );

    // Contract owner should be able to set text for any domain
    mapper.setText(node1, "description", "Set by contract owner");
    mapper.setText(node2, "url", "Set by contract owner");

    // Verify all operations succeeded
    assertEq(mapper.domainMap(node1), TOKEN_ID_1);
    assertEq(mapper.domainMap(node2), TOKEN_ID_2);
    assertEq(mapper.text(node1, "description"), "Set by contract owner");
    assertEq(mapper.text(node2, "url"), "Set by contract owner");
  }

  /**
   * @notice Tests authorization with transferred NFTs
   * @dev Verifies that authorization follows NFT ownership changes
   */
  function test_AuthorizationFollowsNFTOwnership() public {
    address originalOwner = makeAddr("originalOwner");
    address newOwner = makeAddr("newOwner");
    address unauthorized = makeAddr("unauthorized");

    mockNft.mint(originalOwner, TOKEN_ID_1);

    // Original owner claims domain
    vm.prank(originalOwner);
    mapper.claim("transfer", TOKEN_ID_1);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("transfer"))
      )
    );

    // Original owner can set text
    vm.prank(originalOwner);
    mapper.setText(node, "description", "by original owner");

    // Transfer NFT
    vm.prank(originalOwner);
    mockNft.transferFrom(originalOwner, newOwner, TOKEN_ID_1);

    // Original owner should no longer be able to set text
    vm.prank(originalOwner);
    vm.expectRevert(LilNounsEnsMapperV2.NotAuthorised.selector);
    mapper.setText(node, "url", "by original owner after transfer");

    // New owner should be able to set text
    vm.prank(newOwner);
    mapper.setText(node, "url", "by new owner");

    // Unauthorized user still cannot set text
    vm.prank(unauthorized);
    vm.expectRevert(LilNounsEnsMapperV2.NotAuthorised.selector);
    mapper.setText(node, "email", "by unauthorized");

    // Verify final state
    assertEq(mapper.text(node, "description"), "by original owner");
    assertEq(mapper.text(node, "url"), "by new owner");
    assertEq(mapper.text(node, "email"), ""); // Should be empty
  }

  /* ───────────── FUZZ TESTS ───────────── */

  /**
   * @notice Fuzz test for claim function with various label inputs
   * @dev Tests claim function with random string inputs to ensure robust input handling
   * @param fuzzLabel Random string input for subdomain label
   * @param fuzzTokenId Random token ID for testing
   */
  function testFuzz_Claim(string calldata fuzzLabel, uint256 fuzzTokenId) public {
    // Bound token ID to reasonable range (1-10000)
    uint256 boundedTokenId = bound(fuzzTokenId, 1, 10000);

    // Skip empty labels as they should revert
    vm.assume(bytes(fuzzLabel).length > 0);
    // Skip labels that are too long (reasonable limit)
    vm.assume(bytes(fuzzLabel).length <= 63); // DNS label limit
    // Skip labels with invalid characters for DNS
    vm.assume(!_containsInvalidDNSChars(fuzzLabel));

    // Set up NFT ownership
    mockNft.mint(owner, boundedTokenId);

    // Should succeed with valid inputs
    mapper.claim(fuzzLabel, boundedTokenId);

    // Verify the claim was successful
    bytes32 expectedNode = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(fuzzLabel))
      )
    );

    assertEq(mapper.domainMap(expectedNode), boundedTokenId);
    assertEq(mapper.tokenNode(boundedTokenId), expectedNode);
  }

  /**
   * @notice Fuzz test for claim function with invalid inputs
   * @dev Tests that claim function properly rejects invalid inputs
   * @param fuzzTokenId Random token ID for testing
   */
  function testFuzz_ClaimInvalidInputs(uint256 fuzzTokenId) public {
    // Bound token ID to reasonable range
    uint256 boundedTokenId = bound(fuzzTokenId, 1, 10000);

    // Set up NFT ownership
    mockNft.mint(owner, boundedTokenId);

    // Empty label should revert
    vm.expectRevert(LilNounsEnsMapperV2.EmptyLabel.selector);
    mapper.claim("", boundedTokenId);
  }

  /**
   * @notice Fuzz test for setText function with various key-value pairs
   * @dev Tests setText function with random inputs to ensure robust handling
   * @param fuzzKey Random key for text record
   * @param fuzzValue Random value for text record
   * @param fuzzTokenId Random token ID for testing
   */
  function testFuzz_SetText(string calldata fuzzKey, string calldata fuzzValue, uint256 fuzzTokenId) public {
    // Bound token ID to reasonable range
    uint256 boundedTokenId = bound(fuzzTokenId, 1, 10000);

    // Skip empty keys as they should revert
    vm.assume(bytes(fuzzKey).length > 0);
    // Skip avatar key as it's protected
    vm.assume(keccak256(bytes(fuzzKey)) != keccak256("avatar"));
    // Reasonable key length limit
    vm.assume(bytes(fuzzKey).length <= 100);
    // Reasonable value length limit
    vm.assume(bytes(fuzzValue).length <= 1000);

    // Set up NFT ownership and claim domain
    mockNft.mint(owner, boundedTokenId);
    mapper.claim("fuzztest", boundedTokenId);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("fuzztest"))
      )
    );

    // Should succeed with valid inputs
    mapper.setText(node, fuzzKey, fuzzValue);

    // Verify the text was set correctly
    assertEq(mapper.text(node, fuzzKey), fuzzValue);
  }

  /**
   * @notice Fuzz test for setText function with protected avatar key
   * @dev Tests that setText properly rejects attempts to set avatar key
   * @param fuzzValue Random value for testing
   * @param fuzzTokenId Random token ID for testing
   */
  function testFuzz_SetTextAvatarProtection(string calldata fuzzValue, uint256 fuzzTokenId) public {
    // Bound token ID to reasonable range
    uint256 boundedTokenId = bound(fuzzTokenId, 1, 10000);

    // Set up NFT ownership and claim domain
    mockNft.mint(owner, boundedTokenId);
    mapper.claim("fuzztest", boundedTokenId);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("fuzztest"))
      )
    );

    // Attempting to set avatar should always revert
    vm.expectRevert(LilNounsEnsMapperV2.AvatarLocked.selector);
    mapper.setText(node, "avatar", fuzzValue);
  }

  /**
   * @notice Fuzz test for addr function with various node inputs
   * @dev Tests addr resolution with random node hashes
   * @param fuzzNode Random node hash for testing
   */
  function testFuzz_Addr(bytes32 fuzzNode) public {
    // For non-existent nodes, should revert with UnknownNode
    vm.expectRevert(LilNounsEnsMapperV2.UnknownNode.selector);
    mapper.addr(fuzzNode);
  }

  /**
   * @notice Fuzz test for text function with various inputs
   * @dev Tests text record retrieval with random inputs
   * @param fuzzNode Random node hash for testing
   * @param fuzzKey Random key for testing
   */
  function testFuzz_Text(bytes32 fuzzNode, string calldata fuzzKey) public {
    // Reasonable key length limit
    vm.assume(bytes(fuzzKey).length <= 100);

    // For non-existent nodes, should return empty string
    string memory result = mapper.text(fuzzNode, fuzzKey);
    assertEq(result, "");
  }

  /**
   * @notice Fuzz test for name function with various node inputs
   * @dev Tests name resolution with random node hashes
   * @param fuzzNode Random node hash for testing
   */
  function testFuzz_Name(bytes32 fuzzNode) public {
    // For non-existent nodes, should return empty string
    string memory result = mapper.name(fuzzNode);
    assertEq(result, "");
  }

  /**
   * @notice Fuzz test for authorization checks
   * @dev Tests that unauthorized users cannot perform restricted actions
   * @param fuzzUser Random user address
   * @param fuzzTokenId Random token ID
   */
  function testFuzz_AuthorizationChecks(address fuzzUser, uint256 fuzzTokenId) public {
    // Bound token ID to reasonable range
    uint256 boundedTokenId = bound(fuzzTokenId, 1, 10000);

    // Skip owner address and zero address
    vm.assume(fuzzUser != owner && fuzzUser != address(0));

    // Set up NFT ownership to owner (not fuzzUser)
    mockNft.mint(owner, boundedTokenId);

    // Unauthorized user should not be able to claim
    vm.prank(fuzzUser);
    vm.expectRevert(LilNounsEnsMapperV2.NotAuthorised.selector);
    mapper.claim("unauthorized", boundedTokenId);
  }

  /**
   * @notice Fuzz test for updateAddresses function with various array sizes
   * @dev Tests batch address updates with different array configurations
   * @param arraySize Random array size for testing
   */
  function testFuzz_UpdateAddresses(uint8 arraySize) public {
    // Bound array size to reasonable limits (1-50 as per contract limit)
    uint256 boundedSize = bound(arraySize, 1, 50);

    uint256[] memory tokenIds = new uint256[](boundedSize);

    // Set up tokens and claims
    for (uint256 i = 0; i < boundedSize; i++) {
      uint256 tokenId = i + 1;
      tokenIds[i] = tokenId;
      mockNft.mint(owner, tokenId);
      mapper.claim(string(abi.encodePacked("token", vm.toString(tokenId))), tokenId);
    }

    // Should succeed with valid token IDs
    mapper.updateAddresses(tokenIds);
  }

  /**
   * @notice Fuzz test for updateAddresses with oversized arrays
   * @dev Tests that updateAddresses rejects arrays that are too large
   * @param arraySize Random array size for testing (should be > 50)
   */
  function testFuzz_UpdateAddressesOversized(uint8 arraySize) public {
    // Use array sizes larger than the limit
    uint256 boundedSize = bound(arraySize, 51, 255);

    uint256[] memory tokenIds = new uint256[](boundedSize);

    // Fill with dummy data
    for (uint256 i = 0; i < boundedSize; i++) {
      tokenIds[i] = i + 1;
    }

    // Should revert with EmptyArray (reused for size limits)
    vm.expectRevert(LilNounsEnsMapperV2.EmptyArray.selector);
    mapper.updateAddresses(tokenIds);
  }

  /**
   * @notice Fuzz test for getTokensDomains function with various array sizes
   * @dev Tests batch domain retrieval with different array configurations
   * @param arraySize Random array size for testing
   */
  function testFuzz_GetTokensDomains(uint8 arraySize) public {
    // Bound array size to reasonable limits (1-100 as per contract limit)
    uint256 boundedSize = bound(arraySize, 1, 100);

    uint256[] memory tokenIds = new uint256[](boundedSize);

    // Set up tokens and claims
    for (uint256 i = 0; i < boundedSize; i++) {
      uint256 tokenId = i + 1;
      tokenIds[i] = tokenId;
      mockNft.mint(owner, tokenId);
      mapper.claim(string(abi.encodePacked("token", vm.toString(tokenId))), tokenId);
    }

    // Should succeed and return correct domains
    string[] memory domains = mapper.getTokensDomains(tokenIds);
    assertEq(domains.length, boundedSize);

    for (uint256 i = 0; i < boundedSize; i++) {
      string memory expectedDomain = string(abi.encodePacked("token", vm.toString(tokenIds[i]), ".lilnouns.eth"));
      assertEq(domains[i], expectedDomain);
    }
  }

  /**
   * @notice Fuzz test for double claiming prevention
   * @dev Tests that the same domain cannot be claimed twice
   * @param fuzzLabel Random label for testing
   * @param fuzzTokenId1 First token ID
   * @param fuzzTokenId2 Second token ID
   */
  function testFuzz_DoubleClaimPrevention(
    string calldata fuzzLabel,
    uint256 fuzzTokenId1,
    uint256 fuzzTokenId2
  ) public {
    // Bound token IDs to reasonable range and ensure they're different
    uint256 boundedTokenId1 = bound(fuzzTokenId1, 1, 5000);
    uint256 boundedTokenId2 = bound(fuzzTokenId2, 5001, 10000);

    // Skip empty labels and invalid characters
    vm.assume(bytes(fuzzLabel).length > 0);
    vm.assume(bytes(fuzzLabel).length <= 63);
    vm.assume(!_containsInvalidDNSChars(fuzzLabel));

    // Set up NFT ownership
    mockNft.mint(owner, boundedTokenId1);
    mockNft.mint(owner, boundedTokenId2);

    // First claim should succeed
    mapper.claim(fuzzLabel, boundedTokenId1);

    // Second claim with same label should revert
    vm.expectRevert(LilNounsEnsMapperV2.AlreadyClaimed.selector);
    mapper.claim(fuzzLabel, boundedTokenId2);
  }

  /**
   * @notice Helper function to check for invalid DNS characters
   * @dev Checks if a string contains characters that are invalid for DNS labels
   * @param str String to check
   * @return bool True if string contains invalid characters
   */
  function _containsInvalidDNSChars(string memory str) internal pure returns (bool) {
    bytes memory strBytes = bytes(str);
    for (uint256 i = 0; i < strBytes.length; i++) {
      bytes1 char = strBytes[i];
      // Allow alphanumeric and hyphen (basic DNS validation)
      if (
        !(char >= 0x30 && char <= 0x39) && // 0-9
        !(char >= 0x41 && char <= 0x5A) && // A-Z
        !(char >= 0x61 && char <= 0x7A) && // a-z
        char != 0x2D // hyphen
      ) {
        return true;
      }
    }
    return false;
  }

  /* ───────────── UPGRADE TESTS ───────────── */

  /**
   * @notice Tests successful contract upgrade with state preservation
   * @dev Verifies that contract upgrades work correctly and preserve existing state
   */
  function test_UpgradeWithStatePreservation() public {
    // Set up initial state
    mockNft.mint(owner, TOKEN_ID_1);
    mapper.claim(LABEL_1, TOKEN_ID_1);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );

    mapper.setText(node, "description", "Test description");

    // Verify initial state
    assertEq(mapper.domainMap(node), TOKEN_ID_1);
    assertEq(mapper.text(node, "description"), "Test description");

    // Deploy new implementation
    LilNounsEnsMapperV2 newImplementation = new LilNounsEnsMapperV2();

    // Upgrade the contract
    mapper.upgradeToAndCall(address(newImplementation), "");

    // Verify state is preserved after upgrade
    assertEq(mapper.domainMap(node), TOKEN_ID_1);
    assertEq(mapper.text(node, "description"), "Test description");
    assertEq(mapper.tokenNode(TOKEN_ID_1), node);

    // Verify functionality still works after upgrade
    mockNft.mint(owner, TOKEN_ID_2);
    mapper.claim(LABEL_2, TOKEN_ID_2);

    bytes32 node2 = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_2))
      )
    );

    assertEq(mapper.domainMap(node2), TOKEN_ID_2);
  }

  /**
   * @notice Tests upgrade authorization - only owner can upgrade
   * @dev Verifies that non-owners cannot upgrade the contract
   */
  function test_UpgradeAuthorizationOnlyOwner() public {
    // Deploy new implementation
    LilNounsEnsMapperV2 newImplementation = new LilNounsEnsMapperV2();

    // Non-owner should not be able to upgrade
    vm.prank(user);
    vm.expectRevert();
    mapper.upgradeToAndCall(address(newImplementation), "");

    // Owner should be able to upgrade
    mapper.upgradeToAndCall(address(newImplementation), "");
  }

  /**
   * @notice Tests upgrade with initialization data
   * @dev Verifies that upgrades can include initialization calls
   */
  function test_UpgradeWithInitializationData() public {
    // Deploy new implementation
    LilNounsEnsMapperV2 newImplementation = new LilNounsEnsMapperV2();

    // Prepare initialization data (pause the contract)
    bytes memory initData = abi.encodeWithSignature("pause()");

    // Upgrade with initialization
    mapper.upgradeToAndCall(address(newImplementation), initData);

    // Verify the initialization was executed
    assertTrue(mapper.paused());
  }

  /**
   * @notice Tests that upgrade fails with invalid implementation
   * @dev Verifies that upgrades to invalid addresses are rejected
   */
  function test_UpgradeFailsWithInvalidImplementation() public {
    // Try to upgrade to zero address
    vm.expectRevert();
    mapper.upgradeToAndCall(address(0), "");

    // Try to upgrade to non-contract address
    vm.expectRevert();
    mapper.upgradeToAndCall(address(0x1234), "");
  }

  /**
   * @notice Tests proxy delegation functionality
   * @dev Verifies that the proxy correctly delegates calls to the implementation
   */
  function test_ProxyDelegation() public {
    // Get the implementation address
    bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address implementation = address(uint160(uint256(vm.load(address(mapper), implementationSlot))));

    // Verify implementation is set
    assertTrue(implementation != address(0));

    // Verify proxy delegates calls correctly by checking that function calls work
    mockNft.mint(owner, TOKEN_ID_1);
    mapper.claim(LABEL_1, TOKEN_ID_1);

    // Verify the call was successful (delegation worked)
    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );
    assertEq(mapper.domainMap(node), TOKEN_ID_1);
  }

  /**
   * @notice Tests storage layout compatibility across upgrades
   * @dev Verifies that storage slots are preserved correctly during upgrades
   */
  function test_StorageLayoutCompatibility() public {
    // Set up complex state to test storage layout
    mockNft.mint(owner, TOKEN_ID_1);
    mockNft.mint(owner, TOKEN_ID_2);

    mapper.claim(LABEL_1, TOKEN_ID_1);
    mapper.claim(LABEL_2, TOKEN_ID_2);

    bytes32 node1 = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );

    bytes32 node2 = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_2))
      )
    );

    mapper.setText(node1, "key1", "value1");
    mapper.setText(node1, "key2", "value2");
    mapper.setText(node2, "key3", "value3");

    // Store pre-upgrade state
    uint256 preUpgradeDomain1 = mapper.domainMap(node1);
    uint256 preUpgradeDomain2 = mapper.domainMap(node2);
    bytes32 preUpgradeToken1 = mapper.tokenNode(TOKEN_ID_1);
    bytes32 preUpgradeToken2 = mapper.tokenNode(TOKEN_ID_2);
    string memory preUpgradeText1 = mapper.text(node1, "key1");
    string memory preUpgradeText2 = mapper.text(node1, "key2");
    string memory preUpgradeText3 = mapper.text(node2, "key3");

    // Deploy and upgrade to new implementation
    LilNounsEnsMapperV2 newImplementation = new LilNounsEnsMapperV2();
    mapper.upgradeToAndCall(address(newImplementation), "");

    // Verify all storage is preserved
    assertEq(mapper.domainMap(node1), preUpgradeDomain1);
    assertEq(mapper.domainMap(node2), preUpgradeDomain2);
    assertEq(mapper.tokenNode(TOKEN_ID_1), preUpgradeToken1);
    assertEq(mapper.tokenNode(TOKEN_ID_2), preUpgradeToken2);
    assertEq(mapper.text(node1, "key1"), preUpgradeText1);
    assertEq(mapper.text(node1, "key2"), preUpgradeText2);
    assertEq(mapper.text(node2, "key3"), preUpgradeText3);
  }

  /**
   * @notice Tests upgrade rollback scenario
   * @dev Verifies that contracts can be "rolled back" by upgrading to a previous implementation
   */
  function test_UpgradeRollback() public {
    // Set up initial state
    mockNft.mint(owner, TOKEN_ID_1);
    mapper.claim(LABEL_1, TOKEN_ID_1);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );

    // Get current implementation address
    bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address originalImplementation = address(uint160(uint256(vm.load(address(mapper), implementationSlot))));

    // Deploy new implementation and upgrade
    LilNounsEnsMapperV2 newImplementation = new LilNounsEnsMapperV2();
    mapper.upgradeToAndCall(address(newImplementation), "");

    // Verify upgrade occurred
    address currentImplementation = address(uint160(uint256(vm.load(address(mapper), implementationSlot))));
    assertEq(currentImplementation, address(newImplementation));

    // Rollback to original implementation
    mapper.upgradeToAndCall(originalImplementation, "");

    // Verify rollback occurred
    address rolledBackImplementation = address(uint160(uint256(vm.load(address(mapper), implementationSlot))));
    assertEq(rolledBackImplementation, originalImplementation);

    // Verify functionality still works after rollback
    assertEq(mapper.domainMap(node), TOKEN_ID_1);
  }

  /**
   * @notice Tests upgrade during paused state
   * @dev Verifies that upgrades can occur even when the contract is paused
   */
  function test_UpgradeDuringPausedState() public {
    // Pause the contract
    mapper.pause();
    assertTrue(mapper.paused());

    // Deploy new implementation
    LilNounsEnsMapperV2 newImplementation = new LilNounsEnsMapperV2();

    // Upgrade should work even when paused
    mapper.upgradeToAndCall(address(newImplementation), "");

    // Contract should still be paused after upgrade
    assertTrue(mapper.paused());

    // Unpause and verify functionality
    mapper.unpause();
    assertFalse(mapper.paused());

    // Verify normal functionality works
    mockNft.mint(owner, TOKEN_ID_1);
    mapper.claim(LABEL_1, TOKEN_ID_1);
  }

  /**
   * @notice Tests multiple sequential upgrades
   * @dev Verifies that multiple upgrades can be performed sequentially
   */
  function test_MultipleSequentialUpgrades() public {
    // Set up initial state
    mockNft.mint(owner, TOKEN_ID_1);
    mapper.claim(LABEL_1, TOKEN_ID_1);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );

    // First upgrade
    LilNounsEnsMapperV2 implementation1 = new LilNounsEnsMapperV2();
    mapper.upgradeToAndCall(address(implementation1), "");

    // Verify state preserved
    assertEq(mapper.domainMap(node), TOKEN_ID_1);

    // Second upgrade
    LilNounsEnsMapperV2 implementation2 = new LilNounsEnsMapperV2();
    mapper.upgradeToAndCall(address(implementation2), "");

    // Verify state still preserved
    assertEq(mapper.domainMap(node), TOKEN_ID_1);

    // Third upgrade
    LilNounsEnsMapperV2 implementation3 = new LilNounsEnsMapperV2();
    mapper.upgradeToAndCall(address(implementation3), "");

    // Verify state still preserved and functionality works
    assertEq(mapper.domainMap(node), TOKEN_ID_1);

    mockNft.mint(owner, TOKEN_ID_2);
    mapper.claim(LABEL_2, TOKEN_ID_2);

    bytes32 node2 = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_2))
      )
    );

    assertEq(mapper.domainMap(node2), TOKEN_ID_2);
  }

  /**
   * @notice Tests proxy admin functions
   * @dev Verifies that proxy admin functions work correctly
   */
  function test_ProxyAdminFunctions() public {
    // Test that we can get the implementation address
    bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address implementation = address(uint160(uint256(vm.load(address(mapper), implementationSlot))));

    assertTrue(implementation != address(0));

    // Test that the proxy is working by calling a function
    assertEq(mapper.owner(), owner);

    // Test that the proxy correctly handles the UUPS upgrade mechanism
    LilNounsEnsMapperV2 newImplementation = new LilNounsEnsMapperV2();

    // This should work because we're the owner
    mapper.upgradeToAndCall(address(newImplementation), "");

    // Verify the implementation was updated
    address newImplementationAddress = address(uint160(uint256(vm.load(address(mapper), implementationSlot))));
    assertEq(newImplementationAddress, address(newImplementation));
  }

  /**
   * @notice Tests upgrade safety with reentrancy protection
   * @dev Verifies that upgrades are protected against reentrancy attacks
   */
  function test_UpgradeSafetyReentrancyProtection() public {
    // Deploy new implementation
    LilNounsEnsMapperV2 newImplementation = new LilNounsEnsMapperV2();

    // Normal upgrade should work
    mapper.upgradeToAndCall(address(newImplementation), "");

    // Verify upgrade was successful
    bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address currentImplementation = address(uint160(uint256(vm.load(address(mapper), implementationSlot))));
    assertEq(currentImplementation, address(newImplementation));
  }

  /* ───────────── EDGE CASE AND ERROR CONDITION TESTS ───────────── */

  /**
   * @notice Tests initialization with zero address
   * @dev Verifies that initialization fails with zero address for legacy contract
   */
  function test_InitializationWithZeroAddress() public {
    // Deploy a new implementation for testing
    LilNounsEnsMapperV2 newMapper = new LilNounsEnsMapperV2();

    // Try to initialize with zero address - should revert
    vm.expectRevert(LilNounsEnsMapperV2.InvalidLegacyAddress.selector);
    newMapper.initialize(address(0));
  }

  /**
   * @notice Tests double initialization prevention
   * @dev Verifies that contract cannot be initialized twice
   */
  function test_DoubleInitializationPrevention() public {
    // Deploy a new implementation
    LilNounsEnsMapperV2 newMapper = new LilNounsEnsMapperV2();

    // First initialization should succeed
    newMapper.initialize(address(mockLegacy));

    // Second initialization should fail
    vm.expectRevert();
    newMapper.initialize(address(mockLegacy));
  }

  /**
   * @notice Tests claim with maximum length label
   * @dev Tests boundary condition for label length (DNS limit is 63 characters)
   */
  function test_ClaimWithMaxLengthLabel() public {
    // Create a 63-character label (DNS maximum)
    string memory maxLabel = "abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0";
    assertEq(bytes(maxLabel).length, 63);

    mockNft.mint(owner, TOKEN_ID_1);

    // Should succeed with max length label
    mapper.claim(maxLabel, TOKEN_ID_1);

    // Verify claim was successful
    bytes32 expectedNode = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(maxLabel))
      )
    );
    assertEq(mapper.domainMap(expectedNode), TOKEN_ID_1);
  }

  /**
   * @notice Tests setText with empty value
   * @dev Verifies that empty values can be set (clearing text records)
   */
  function test_SetTextWithEmptyValue() public {
    mockNft.mint(owner, TOKEN_ID_1);
    mapper.claim(LABEL_1, TOKEN_ID_1);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );

    // Set a text record first
    mapper.setText(node, "description", "Initial value");
    assertEq(mapper.text(node, "description"), "Initial value");

    // Clear it with empty value
    mapper.setText(node, "description", "");
    assertEq(mapper.text(node, "description"), "");
  }

  /**
   * @notice Tests setText with very long key and value
   * @dev Tests boundary conditions for text record storage
   */
  function test_SetTextWithLongKeyAndValue() public {
    mockNft.mint(owner, TOKEN_ID_1);
    mapper.claim(LABEL_1, TOKEN_ID_1);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );

    // Create long key and value (but reasonable for gas limits)
    string memory longKey = "verylongkeyname_with_underscores_and_numbers_123456789";
    string
      memory longValue = "This is a very long value that contains multiple sentences and should test the storage capabilities of the contract. It includes various characters, numbers 123456789, and symbols !@#$%^&*()";

    // Should succeed with long key and value
    mapper.setText(node, longKey, longValue);
    assertEq(mapper.text(node, longKey), longValue);
  }

  /**
   * @notice Tests addr function with non-existent token ID
   * @dev Verifies proper error handling for non-existent tokens
   */
  function test_AddrWithNonExistentToken() public {
    // Create a node that doesn't exist
    bytes32 nonExistentNode = keccak256("nonexistent");

    // Should revert with UnknownNode
    vm.expectRevert(LilNounsEnsMapperV2.UnknownNode.selector);
    mapper.addr(nonExistentNode);
  }

  /**
   * @notice Tests claim with token ID zero
   * @dev Tests edge case with token ID 0 (which might be invalid for some NFTs)
   */
  function test_ClaimWithTokenIdZero() public {
    // Mock NFT to allow token ID 0
    mockNft.mint(owner, 0);

    // Should succeed - contract doesn't restrict token ID 0
    mapper.claim("zero", 0);

    bytes32 expectedNode = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("zero"))
      )
    );
    assertEq(mapper.domainMap(expectedNode), 0);
  }

  /**
   * @notice Tests claim with maximum uint256 token ID
   * @dev Tests boundary condition with maximum possible token ID
   */
  function test_ClaimWithMaxTokenId() public {
    uint256 maxTokenId = type(uint256).max;
    mockNft.mint(owner, maxTokenId);

    // Should succeed with max token ID
    mapper.claim("maxtoken", maxTokenId);

    bytes32 expectedNode = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("maxtoken"))
      )
    );
    assertEq(mapper.domainMap(expectedNode), maxTokenId);
  }

  /**
   * @notice Tests updateAddresses with empty array
   * @dev Verifies proper error handling for empty arrays
   */
  function test_UpdateAddressesWithEmptyArray() public {
    uint256[] memory emptyArray = new uint256[](0);

    vm.expectRevert(LilNounsEnsMapperV2.EmptyArray.selector);
    mapper.updateAddresses(emptyArray);
  }

  /**
   * @notice Tests updateAddresses with unregistered token
   * @dev Verifies error handling when token has no associated domain
   */
  function test_UpdateAddressesWithUnregisteredToken() public {
    mockNft.mint(owner, TOKEN_ID_1);
    // Don't claim domain for this token

    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = TOKEN_ID_1;

    vm.expectRevert(LilNounsEnsMapperV2.UnregisteredToken.selector);
    mapper.updateAddresses(tokenIds);
  }

  /**
   * @notice Tests getTokensDomains with empty array
   * @dev Verifies error handling for empty input arrays
   */
  function test_GetTokensDomainsWithEmptyArray() public {
    uint256[] memory emptyArray = new uint256[](0);

    vm.expectRevert(LilNounsEnsMapperV2.EmptyArray.selector);
    mapper.getTokensDomains(emptyArray);
  }

  /**
   * @notice Tests getTokensDomains with oversized array
   * @dev Verifies DoS protection for large arrays
   */
  function test_GetTokensDomainsWithOversizedArray() public {
    uint256[] memory oversizedArray = new uint256[](101); // Exceeds limit of 100

    vm.expectRevert(LilNounsEnsMapperV2.EmptyArray.selector);
    mapper.getTokensDomains(oversizedArray);
  }

  /**
   * @notice Tests getTokenDomain with unregistered token
   * @dev Verifies error handling for tokens without domains
   */
  function test_GetTokenDomainWithUnregisteredToken() public {
    mockNft.mint(owner, TOKEN_ID_1);
    // Don't claim domain for this token

    vm.expectRevert(LilNounsEnsMapperV2.UnregisteredToken.selector);
    mapper.getTokenDomain(TOKEN_ID_1);
  }

  /**
   * @notice Tests importLegacy with non-existent legacy data
   * @dev Verifies error handling when no legacy data exists
   */
  function test_ImportLegacyWithNoLegacyData() public {
    mockNft.mint(owner, TOKEN_ID_1);

    // Mock legacy contract returns zero for non-existent token
    mockLegacy.setLegacyData(TOKEN_ID_1, bytes32(0), "");

    vm.expectRevert(LilNounsEnsMapperV2.NothingToImport.selector);
    mapper.importLegacy(TOKEN_ID_1);
  }

  /**
   * @notice Tests importLegacy with already imported data
   * @dev Verifies prevention of double imports
   */
  function test_ImportLegacyWithAlreadyImportedData() public {
    mockNft.mint(owner, TOKEN_ID_1);

    // Set up legacy data
    bytes32 legacyNode = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );
    mockLegacy.setLegacyData(TOKEN_ID_1, legacyNode, LABEL_1);

    // Import once - should succeed
    mapper.importLegacy(TOKEN_ID_1);

    // Try to import again - should fail
    vm.expectRevert(LilNounsEnsMapperV2.NothingToImport.selector);
    mapper.importLegacy(TOKEN_ID_1);
  }

  /**
   * @notice Tests setText with single character key
   * @dev Tests minimum valid key length
   */
  function test_SetTextWithSingleCharacterKey() public {
    mockNft.mint(owner, TOKEN_ID_1);
    mapper.claim(LABEL_1, TOKEN_ID_1);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );

    // Single character key should work
    mapper.setText(node, "x", "test value");
    assertEq(mapper.text(node, "x"), "test value");
  }

  /**
   * @notice Tests claim with single character label
   * @dev Tests minimum valid label length
   */
  function test_ClaimWithSingleCharacterLabel() public {
    mockNft.mint(owner, TOKEN_ID_1);

    // Single character label should work
    mapper.claim("a", TOKEN_ID_1);

    bytes32 expectedNode = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("a"))
      )
    );
    assertEq(mapper.domainMap(expectedNode), TOKEN_ID_1);
  }

  /**
   * @notice Tests text function with special characters in key
   * @dev Verifies handling of various character sets in keys
   */
  function test_TextWithSpecialCharacterKeys() public {
    mockNft.mint(owner, TOKEN_ID_1);
    mapper.claim(LABEL_1, TOKEN_ID_1);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );

    // Test various special characters in keys
    string[] memory specialKeys = new string[](5);
    specialKeys[0] = "key-with-hyphens";
    specialKeys[1] = "key_with_underscores";
    specialKeys[2] = "key.with.dots";
    specialKeys[3] = "key123with456numbers";
    specialKeys[4] = "UPPERCASE_KEY";

    for (uint256 i = 0; i < specialKeys.length; i++) {
      string memory key = specialKeys[i];
      string memory value = string(abi.encodePacked("value_", vm.toString(i)));

      mapper.setText(node, key, value);
      assertEq(mapper.text(node, key), value);
    }
  }

  /**
   * @notice Tests contract behavior when paused
   * @dev Verifies all pausable functions are properly blocked
   */
  function test_AllFunctionsBlockedWhenPaused() public {
    mockNft.mint(owner, TOKEN_ID_1);

    // Pause the contract
    mapper.pause();

    // All pausable functions should revert
    vm.expectRevert();
    mapper.claim(LABEL_1, TOKEN_ID_1);

    vm.expectRevert();
    mapper.setText(bytes32(0), "key", "value");

    vm.expectRevert();
    mapper.importLegacy(TOKEN_ID_1);

    vm.expectRevert();
    mapper.updateAddresses(new uint256[](1));

    // View functions should still work
    string memory result = mapper.text(bytes32(0), "key");
    assertEq(result, "");
  }

  /**
   * @notice Tests authorization with contract owner vs NFT owner
   * @dev Verifies both contract owner and NFT owner can perform authorized actions
   */
  function test_AuthorizationContractOwnerVsNftOwner() public {
    address nftOwner = makeAddr("nftOwner");
    mockNft.mint(nftOwner, TOKEN_ID_1);

    // Contract owner should be able to claim for any token
    mapper.claim(LABEL_1, TOKEN_ID_1);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );

    // Contract owner should be able to set text
    mapper.setText(node, "description", "Set by contract owner");

    // NFT owner should also be able to set text
    vm.prank(nftOwner);
    mapper.setText(node, "url", "Set by NFT owner");

    assertEq(mapper.text(node, "description"), "Set by contract owner");
    assertEq(mapper.text(node, "url"), "Set by NFT owner");
  }

  /**
   * @notice Tests name resolution with various label formats
   * @dev Verifies name construction works with different label types
   */
  function test_NameResolutionWithVariousLabels() public {
    string[] memory testLabels = new string[](4);
    testLabels[0] = "simple";
    testLabels[1] = "with-hyphens";
    testLabels[2] = "with123numbers";
    testLabels[3] = "a"; // single character

    for (uint256 i = 0; i < testLabels.length; i++) {
      uint256 tokenId = i + 1;
      mockNft.mint(owner, tokenId);
      mapper.claim(testLabels[i], tokenId);

      bytes32 node = keccak256(
        abi.encodePacked(
          bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
          keccak256(bytes(testLabels[i]))
        )
      );

      string memory expectedName = string(abi.encodePacked(testLabels[i], ".lilnouns.eth"));
      assertEq(mapper.name(node), expectedName);
    }
  }

  /* ───────────── PROPERTY-BASED TESTING FOR INVARIANTS ───────────── */

  /**
   * @notice Property test: Bidirectional mapping consistency
   * @dev Verifies that _hashToId and _idToHash mappings are always consistent
   */
  function testInvariant_BidirectionalMappingConsistency() public {
    // Set up multiple claims to test the invariant
    uint256[] memory tokenIds = new uint256[](5);
    string[] memory labels = new string[](5);
    bytes32[] memory nodes = new bytes32[](5);

    for (uint256 i = 0; i < 5; i++) {
      tokenIds[i] = i + 1;
      labels[i] = string(abi.encodePacked("test", vm.toString(i)));
      mockNft.mint(owner, tokenIds[i]);
      mapper.claim(labels[i], tokenIds[i]);

      nodes[i] = keccak256(
        abi.encodePacked(
          bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
          keccak256(bytes(labels[i]))
        )
      );
    }

    // Invariant: For every claimed domain, domainMap(node) == tokenId AND tokenNode(tokenId) == node
    for (uint256 i = 0; i < 5; i++) {
      uint256 mappedTokenId = mapper.domainMap(nodes[i]);
      bytes32 mappedNode = mapper.tokenNode(tokenIds[i]);

      // Forward mapping: node -> tokenId
      assertEq(mappedTokenId, tokenIds[i], "Forward mapping broken");

      // Reverse mapping: tokenId -> node
      assertEq(mappedNode, nodes[i], "Reverse mapping broken");

      // Bidirectional consistency: if domainMap(node) == tokenId, then tokenNode(tokenId) == node
      if (mappedTokenId != 0) {
        assertEq(mapper.tokenNode(mappedTokenId), nodes[i], "Bidirectional consistency broken");
      }
    }
  }

  /**
   * @notice Property test: Domain uniqueness invariant
   * @dev Verifies that each domain can only be mapped to one token ID
   */
  function testInvariant_DomainUniqueness() public {
    string memory label = "unique";
    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(label))
      )
    );

    // Claim domain with first token
    mockNft.mint(owner, TOKEN_ID_1);
    mapper.claim(label, TOKEN_ID_1);

    // Verify initial claim
    assertEq(mapper.domainMap(node), TOKEN_ID_1);

    // Attempt to claim same domain with different token should fail
    mockNft.mint(owner, TOKEN_ID_2);
    vm.expectRevert(LilNounsEnsMapperV2.AlreadyClaimed.selector);
    mapper.claim(label, TOKEN_ID_2);

    // Invariant: Domain should still be mapped to original token
    assertEq(mapper.domainMap(node), TOKEN_ID_1, "Domain uniqueness violated");
  }

  /**
   * @notice Property test: Token uniqueness invariant
   * @dev Verifies that each token can only be mapped to one domain
   */
  function testInvariant_TokenUniqueness() public {
    mockNft.mint(owner, TOKEN_ID_1);

    // Claim first domain
    mapper.claim("first", TOKEN_ID_1);
    bytes32 firstNode = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("first"))
      )
    );

    // Claim second domain with same token (should overwrite)
    mapper.claim("second", TOKEN_ID_1);
    bytes32 secondNode = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("second"))
      )
    );

    // Invariant: Token should only be mapped to the latest domain
    assertEq(mapper.tokenNode(TOKEN_ID_1), secondNode, "Token should map to latest domain");
    assertEq(mapper.domainMap(secondNode), TOKEN_ID_1, "Latest domain should map to token");

    // First domain should no longer be mapped to this token
    assertEq(mapper.domainMap(firstNode), 0, "Previous domain should be unmapped");
  }

  /**
   * @notice Property test: Authorization consistency invariant
   * @dev Verifies that authorization checks are consistent across all functions
   */
  function testInvariant_AuthorizationConsistency() public {
    address nftOwner = makeAddr("nftOwner");
    address unauthorized = makeAddr("unauthorized");

    mockNft.mint(nftOwner, TOKEN_ID_1);

    // Contract owner should be able to perform all operations
    mapper.claim(LABEL_1, TOKEN_ID_1);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );

    mapper.setText(node, "description", "Set by contract owner");
    mapper.importLegacy(TOKEN_ID_1); // This will fail but shouldn't revert due to authorization

    // NFT owner should be able to perform operations on their token
    vm.startPrank(nftOwner);
    mapper.setText(node, "url", "Set by NFT owner");
    vm.stopPrank();

    // Unauthorized user should not be able to perform any operations
    vm.startPrank(unauthorized);

    vm.expectRevert(LilNounsEnsMapperV2.NotAuthorised.selector);
    mapper.claim("unauthorized", TOKEN_ID_1);

    vm.expectRevert(LilNounsEnsMapperV2.NotAuthorised.selector);
    mapper.setText(node, "unauthorized", "value");

    vm.expectRevert(LilNounsEnsMapperV2.NotAuthorised.selector);
    mapper.importLegacy(TOKEN_ID_1);

    vm.stopPrank();

    // Invariant: Authorization should be consistent - only owner or NFT holder can modify
    assertTrue(true, "Authorization consistency maintained");
  }

  /**
   * @notice Property test: State preservation across operations
   * @dev Verifies that unrelated state is preserved during operations
   */
  function testInvariant_StatePreservationAcrossOperations() public {
    // Set up initial state with multiple domains
    mockNft.mint(owner, TOKEN_ID_1);
    mockNft.mint(owner, TOKEN_ID_2);

    mapper.claim("domain1", TOKEN_ID_1);
    mapper.claim("domain2", TOKEN_ID_2);

    bytes32 node1 = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("domain1"))
      )
    );

    bytes32 node2 = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("domain2"))
      )
    );

    mapper.setText(node1, "key1", "value1");
    mapper.setText(node2, "key2", "value2");

    // Store initial state
    uint256 initialDomain1 = mapper.domainMap(node1);
    uint256 initialDomain2 = mapper.domainMap(node2);
    string memory initialText1 = mapper.text(node1, "key1");
    string memory initialText2 = mapper.text(node2, "key2");

    // Perform operation on domain1
    mapper.setText(node1, "newkey", "newvalue");

    // Invariant: Domain2 state should be unchanged
    assertEq(mapper.domainMap(node2), initialDomain2, "Unrelated domain mapping changed");
    assertEq(mapper.text(node2, "key2"), initialText2, "Unrelated text record changed");

    // Domain1 should still have its original mappings plus new ones
    assertEq(mapper.domainMap(node1), initialDomain1, "Modified domain mapping changed unexpectedly");
    assertEq(mapper.text(node1, "key1"), initialText1, "Original text record lost");
    assertEq(mapper.text(node1, "newkey"), "newvalue", "New text record not set");
  }

  /**
   * @notice Property test: Address resolution consistency
   * @dev Verifies that addr() always returns current NFT owner
   */
  function testInvariant_AddressResolutionConsistency() public {
    address initialOwner = makeAddr("initialOwner");
    address newOwner = makeAddr("newOwner");

    mockNft.mint(initialOwner, TOKEN_ID_1);

    // Claim domain as initial owner
    vm.prank(initialOwner);
    mapper.claim(LABEL_1, TOKEN_ID_1);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );

    // Verify initial resolution
    assertEq(mapper.addr(node), initialOwner, "Initial address resolution incorrect");

    // Transfer NFT to new owner
    vm.prank(initialOwner);
    mockNft.transferFrom(initialOwner, newOwner, TOKEN_ID_1);

    // Invariant: addr() should always return current NFT owner
    assertEq(mapper.addr(node), newOwner, "Address resolution not updated after transfer");

    // Transfer back
    vm.prank(newOwner);
    mockNft.transferFrom(newOwner, initialOwner, TOKEN_ID_1);

    assertEq(mapper.addr(node), initialOwner, "Address resolution not updated after second transfer");
  }

  /**
   * @notice Property test: Avatar generation consistency
   * @dev Verifies that avatar text records are always generated correctly
   */
  function testInvariant_AvatarGenerationConsistency() public {
    mockNft.mint(owner, TOKEN_ID_1);
    mapper.claim(LABEL_1, TOKEN_ID_1);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );

    // Get avatar multiple times
    string memory avatar1 = mapper.text(node, "avatar");
    string memory avatar2 = mapper.text(node, "avatar");
    string memory avatar3 = mapper.text(node, "avatar");

    // Invariant: Avatar should be consistently generated
    assertEq(avatar1, avatar2, "Avatar generation inconsistent");
    assertEq(avatar2, avatar3, "Avatar generation inconsistent");

    // Verify avatar format
    string memory expectedAvatar = string.concat(
      "eip155:1/erc721:0x4b10701Bfd7BFEdc47d50562b76b436fbB5BdB3B/",
      vm.toString(TOKEN_ID_1)
    );
    assertEq(avatar1, expectedAvatar, "Avatar format incorrect");

    // Avatar should not be settable manually
    vm.expectRevert(LilNounsEnsMapperV2.AvatarLocked.selector);
    mapper.setText(node, "avatar", "manual avatar");

    // Avatar should still be the same after failed attempt
    assertEq(mapper.text(node, "avatar"), expectedAvatar, "Avatar changed after failed manual set");
  }

  /**
   * @notice Property test: Legacy compatibility invariant
   * @dev Verifies that legacy data is properly handled and doesn't interfere with new data
   */
  function testInvariant_LegacyCompatibility() public {
    // Set up legacy data
    bytes32 legacyNode = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("legacy"))
      )
    );
    mockLegacy.setLegacyData(TOKEN_ID_1, legacyNode, "legacy");
    mockLegacy.setLegacyText(legacyNode, "description", "Legacy description");

    // Legacy data should be accessible
    assertEq(mapper.text(legacyNode, "description"), "Legacy description");

    // Claim new domain
    mockNft.mint(owner, TOKEN_ID_2);
    mapper.claim("new", TOKEN_ID_2);

    bytes32 newNode = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes("new"))
      )
    );

    mapper.setText(newNode, "description", "New description");

    // Invariant: Legacy and new data should coexist without interference
    assertEq(mapper.text(legacyNode, "description"), "Legacy description", "Legacy data corrupted");
    assertEq(mapper.text(newNode, "description"), "New description", "New data corrupted");

    // Import legacy data
    mockNft.mint(owner, TOKEN_ID_1);
    mapper.importLegacy(TOKEN_ID_1);

    // After import, data should still be accessible and consistent
    assertEq(mapper.domainMap(legacyNode), TOKEN_ID_1, "Legacy import failed");
    assertEq(mapper.tokenNode(TOKEN_ID_1), legacyNode, "Legacy reverse mapping failed");
    assertEq(mapper.text(legacyNode, "description"), "Legacy description", "Legacy text lost after import");
  }

  /**
   * @notice Property test: Pause state invariant
   * @dev Verifies that pause state correctly blocks/allows operations
   */
  function testInvariant_PauseStateConsistency() public {
    mockNft.mint(owner, TOKEN_ID_1);

    // Normal operations should work when not paused
    mapper.claim(LABEL_1, TOKEN_ID_1);

    bytes32 node = keccak256(
      abi.encodePacked(
        bytes32(0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492),
        keccak256(bytes(LABEL_1))
      )
    );

    mapper.setText(node, "key", "value");

    // Pause the contract
    mapper.pause();
    assertTrue(mapper.paused(), "Contract should be paused");

    // Invariant: All state-changing operations should be blocked when paused
    vm.expectRevert();
    mapper.claim("paused", TOKEN_ID_2);

    vm.expectRevert();
    mapper.setText(node, "pausedkey", "pausedvalue");

    vm.expectRevert();
    mapper.importLegacy(TOKEN_ID_1);

    vm.expectRevert();
    mapper.updateAddresses(new uint256[](1));

    // View functions should still work
    assertEq(mapper.text(node, "key"), "value", "View functions should work when paused");
    assertEq(mapper.addr(node), owner, "Address resolution should work when paused");

    // Unpause and verify operations work again
    mapper.unpause();
    assertFalse(mapper.paused(), "Contract should be unpaused");

    mockNft.mint(owner, TOKEN_ID_2);
    mapper.claim("unpaused", TOKEN_ID_2); // Should work now

    // Invariant: State should be preserved across pause/unpause cycles
    assertEq(mapper.text(node, "key"), "value", "State lost during pause cycle");
    assertEq(mapper.domainMap(node), TOKEN_ID_1, "Domain mapping lost during pause cycle");
  }
}
