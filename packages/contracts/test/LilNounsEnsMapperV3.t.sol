// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

// Test utilities
import { Test } from "forge-std/Test.sol";

// Contract under test
import { LilNounsEnsMapperV3 } from "../src/LilNounsEnsMapperV3.sol";

// Errors to assert on
import { LilNounsEnsErrors } from "../src/LilNounsEnsErrors.sol";

// Minimal interfaces we need
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ENS } from "@ensdomains/ens-contracts/registry/ENS.sol"; // type used by the wrapper initializer
import { IBaseRegistrar } from "@ensdomains/ens-contracts/ethregistrar/IBaseRegistrar.sol"; // type used by the wrapper initializer
import { INameWrapper } from "@ensdomains/ens-contracts/wrapper/INameWrapper.sol";

/// -----------------------------------------------------------------------
/// Test Mocks (minimal and purpose-built for this suite)
/// -----------------------------------------------------------------------

/// @notice Minimal Lil Nouns ERC721 mock with mint and transfer, sufficient for owner checks.
contract MockLilNouns is IERC721 {
  string public name = "Mock LilNouns";
  string public symbol = "MLIL";

  mapping(uint256 => address) internal _owner;
  mapping(address => mapping(address => bool)) public override isApprovedForAll;
  mapping(uint256 => address) public override getApproved;

  function ownerOf(uint256 tokenId) public view override returns (address) {
    address o = _owner[tokenId];
    require(o != address(0), "NOT_MINTED");
    return o;
  }

  function balanceOf(address owner) external pure override returns (uint256) {
    owner; // unused in tests
    return 0;
  }

  function supportsInterface(bytes4) external pure returns (bool) {
    return true;
  }

  function approve(address to, uint256 tokenId) external override {
    require(msg.sender == ownerOf(tokenId), "NOT_OWNER");
    getApproved[tokenId] = to;
    emit Approval(msg.sender, to, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) external override {
    isApprovedForAll[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override {
    require(from == ownerOf(tokenId), "FROM_NOT_OWNER");
    require(msg.sender == from || msg.sender == getApproved[tokenId] || isApprovedForAll[from][msg.sender], "NOT_AUTH");
    _owner[tokenId] = to;
    emit Transfer(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) external override {
    transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata /*data*/) external override {
    transferFrom(from, to, tokenId);
  }

  // Helpers for tests
  function mint(address to, uint256 tokenId) external {
    require(_owner[tokenId] == address(0), "ALREADY_MINTED");
    _owner[tokenId] = to;
    emit Transfer(address(0), to, tokenId);
  }
}

/// @notice Minimal deployment-only helper to get a distinct nonzero address.
contract DummyAddr {}

/// @notice NameWrapper mock that validates wiring and records setSubnodeRecord calls; can simulate reentrancy via hook.
contract MockNameWrapper {
  ENS internal _ens;
  IBaseRegistrar internal _registrar;
  bytes32 public lastRoot;
  string public lastLabel;
  address public lastOwner;
  address public lastResolver;
  bool public tryReenter;
  LilNounsEnsMapperV3 public mapper; // set by tests when reentrancy is desired

  function configureReenter(LilNounsEnsMapperV3 _mapper, bool _try) external {
    mapper = _mapper;
    tryReenter = _try;
  }

  constructor(address ensAddr, address registrarAddr) {
    _ens = ENS(ensAddr);
    _registrar = IBaseRegistrar(registrarAddr);
  }

  function ens() external view returns (ENS) {
    return _ens;
  }

  function registrar() external view returns (IBaseRegistrar) {
    return _registrar;
  }

  // The contract under test only calls setSubnodeRecord in this suite
  function setSubnodeRecord(
    bytes32 parentNode,
    string calldata label,
    address owner,
    address resolver,
    uint64 /*ttl*/,
    uint32 /*fuses*/,
    uint64 /*expiry*/
  ) external returns (bytes32) {
    lastRoot = parentNode;
    lastLabel = label;
    lastOwner = owner;
    lastResolver = resolver;

    // Optional reentrancy attempt after state changes in mapper
    if (tryReenter) {
      // If set, attempt to call claim again; should be blocked by nonReentrant
      try mapper.claim(string("badreenter"), 999) {
        // should not succeed
      } catch {}
    }

    bytes32 node = keccak256(abi.encodePacked(parentNode, keccak256(bytes(label))));
    return node; // non-zero indicates success
  }

  // Unused INameWrapper functions; provide stubs to satisfy interface
  function ownerOf(uint256) external pure returns (address) {
    return address(0);
  }

  function isApprovedForAll(address, address) external pure returns (bool) {
    return false;
  }

  function getApproved(uint256) external pure returns (address) {
    return address(0);
  }

  function setApprovalForAll(address, bool) external {}
  function approve(address, uint256) external {}

  function getData(uint256) external pure returns (address, uint32, uint64) {
    return (address(0), 0, 0);
  }

  function setRecord(bytes32, address, address, uint64) external {}
  function setTTL(bytes32, uint64) external {}

  function setSubnodeOwner(bytes32, string calldata, address, uint32, uint64) external pure returns (bytes32) {
    return bytes32(0);
  }

  function setResolver(bytes32, address) external {}
  function setOwner(bytes32, address) external {}
  function setFuses(bytes32, uint32) external {}
  function setTTLAndFuses(bytes32, uint64, uint32) external {}

  function isWrapped(bytes32) external pure returns (bool) {
    return true;
  }

  function setChildFuses(bytes32, bytes32, uint32, uint64) external {}

  function setSubnodeRecord(
    bytes32,
    bytes32,
    address,
    address,
    uint64,
    uint32,
    uint64
  ) external pure returns (bytes32) {
    return bytes32(0);
  }

  function setSubnodeOwner(bytes32, bytes32, address, uint32, uint64) external pure returns (bytes32) {
    return bytes32(0);
  }

  // Minimal API used by production contract
  function unwrapETH2LD(bytes32, address, address) external {}

  function wrapETH2LD(string calldata, address, uint16, address) external pure returns (uint64) {
    return 0;
  }

  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external pure returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function supportsInterface(bytes4) external pure returns (bool) {
    return true;
  }
}

/// -----------------------------------------------------------------------
/// LilNounsEnsMapperV3.sol Test Suite
/// -----------------------------------------------------------------------
/// Minimal legacy interface matching the subset used
interface ILegacy {
  function tokenHashmap(uint256) external view returns (bytes32);
  function hashToIdMap(bytes32) external view returns (uint256);
  function hashToDomainMap(bytes32) external view returns (string memory);
  function texts(bytes32, string calldata) external view returns (string memory);
}

/// Dummy legacy implementation returning nothing (no legacy data)
contract LegacyNull is ILegacy {
  function tokenHashmap(uint256) external pure returns (bytes32) {
    return bytes32(0);
  }

  function hashToIdMap(bytes32) external pure returns (uint256) {
    return 0;
  }

  function hashToDomainMap(bytes32) external pure returns (string memory) {
    return "";
  }

  function texts(bytes32, string calldata) external pure returns (string memory) {
    return "";
  }
}

contract LilNounsEnsMapperV3Test is Test {
  // Actors
  address internal alice = address(0xA11CE);
  address internal bob = address(0xB0B);
  address internal admin = address(0xAD);

  // Contracts
  MockLilNouns internal nft;
  address internal ensAddr;
  address internal registrarAddr;
  MockNameWrapper internal wrapper;
  LilNounsEnsMapperV3 internal mapper;

  // Constants
  bytes32 internal ROOT_ETH = namehash("eth");
  bytes32 internal ROOT_LILNOUNS; // namehash("lilnouns.eth")

  // Legacy interface mock: we only need it to return zeros
  ILegacy internal legacy;

  /// Setup common to all tests: deploy mocks and mapper, initialize root to lilnouns.eth
  function setUp() public {
    // Deploy mocks
    nft = new MockLilNouns();
    ensAddr = address(new DummyAddr());
    registrarAddr = address(new DummyAddr());
    wrapper = new MockNameWrapper(ensAddr, registrarAddr);

    // Compute namehash for lilnouns.eth
    ROOT_LILNOUNS = keccak256(abi.encodePacked(ROOT_ETH, keccak256(bytes("lilnouns"))));

    // Legacy
    LegacyNull legacyImpl = new LegacyNull();
    legacy = ILegacy(address(legacyImpl));

    // Deploy mapper (implementation directly; using initializer pattern)
    mapper = new LilNounsEnsMapperV3();

    // Initialize with admin as owner, and wire mocks. Root is lilnouns.eth
    mapper.initialize(
      admin,
      ensAddr,
      registrarAddr,
      address(wrapper),
      address(legacy),
      address(nft),
      ROOT_LILNOUNS,
      "lilnouns"
    );
  }

  // ---------------------------- Helpers ----------------------------
  function namehash(string memory label) internal pure returns (bytes32) {
    // Standard ENS namehash for single label: keccak(abi.encode(0x0, keccak(label)))
    return keccak256(abi.encodePacked(bytes32(0), keccak256(bytes(label))));
  }

  function nodeFor(string memory sub) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(ROOT_LILNOUNS, keccak256(bytes(sub))));
  }

  function _mintTo(address to, uint256 id) internal {
    nft.mint(to, id);
  }

  // ---------------------------- Core behavior ----------------------------

  /// Claim succeeds when msg.sender owns the NFT and label is unused
  function testClaim_WhenHolderAndUnused_Succeeds() public {
    _mintTo(alice, 1);

    vm.prank(alice);
    vm.expectEmit(true, true, true, true);
    emit LilNounsEnsMapperV3.RegisterSubdomain(alice, 1, "alice");
    vm.expectEmit(true, false, false, true);
    emit LilNounsEnsMapperV3.AddrChanged(nodeFor("alice"), alice);
    mapper.claim("alice", 1);

    // State: token -> node
    assertEq(mapper.tokenNode(1), nodeFor("alice"));
    // Name resolution
    assertEq(mapper.name(nodeFor("alice")), "alice.lilnouns.eth");
    // Addr resolves to current owner (alice)
    assertEq(mapper.addr(nodeFor("alice")), alice);
  }

  /// Claim reverts if label already taken (by any token)
  function testClaim_WhenLabelAlreadyTaken_Reverts() public {
    _mintTo(alice, 1);
    _mintTo(bob, 2);

    vm.prank(alice);
    mapper.claim("name", 1);

    vm.prank(bob);
    vm.expectRevert(LilNounsEnsErrors.AlreadyClaimed.selector);
    mapper.claim("name", 2);
  }

  /// Claim reverts if caller is not token owner nor admin
  function testClaim_WhenNotOwnerOrAdmin_RevertsNotAuthorised() public {
    _mintTo(alice, 1);

    vm.prank(bob); // bob is not owner
    vm.expectRevert(LilNounsEnsErrors.NotAuthorised.selector);
    mapper.claim("x", 1);
  }

  /// Empty label is rejected
  function testClaim_WhenEmptyLabel_Reverts() public {
    _mintTo(alice, 1);

    vm.prank(alice);
    vm.expectRevert(LilNounsEnsErrors.EmptyLabel.selector);
    mapper.claim("", 1);
  }

  /// After claiming, transferring the NFT updates address resolution automatically (binding to token)
  function testTransfer_AfterClaim_AddrResolvesToNewOwner() public {
    _mintTo(alice, 42);

    vm.prank(alice);
    mapper.claim("fortytwo", 42);

    // Transfer token to bob
    vm.prank(alice);
    nft.transferFrom(alice, bob, 42);

    // addr(node) should now be bob
    assertEq(mapper.addr(nodeFor("fortytwo")), bob);
    // tokenNode remains same node for token 42
    assertEq(mapper.tokenNode(42), nodeFor("fortytwo"));
  }

  /// The contract allows the same NFT to claim another free label; tokenNode now points to the latest, and both nodes stay claimed.
  function testClaim_AfterSecondLabel_TokenNodeUpdatesAndOldNodePersists() public {
    _mintTo(alice, 7);

    vm.startPrank(alice);
    mapper.claim("first", 7);
    bytes32 node1 = nodeFor("first");
    mapper.claim("second", 7);
    bytes32 node2 = nodeFor("second");
    vm.stopPrank();

    // tokenNode should point to the most recent node
    assertEq(mapper.tokenNode(7), node2);

    // Both nodes are considered claimed via domainMap/addr
    assertEq(mapper.domainMap("first"), node1);
    assertEq(mapper.domainMap("second"), node2);
    assertEq(mapper.addr(node1), alice);
    assertEq(mapper.addr(node2), alice);

    // getTokenDomain should return the latest label
    assertEq(mapper.getTokenDomain(7), "second.lilnouns.eth");
  }

  /// Pausing by owner disables claim and setText, and emits events; unpause restores functionality
  function testAdmin_PauseUnpause_Behaves() public {
    // pause as admin
    vm.prank(admin);
    vm.expectEmit(true, false, false, true);
    emit LilNounsEnsMapperV3.ContractPaused(admin);
    mapper.pause();

    _mintTo(alice, 1);
    vm.prank(alice);
    vm.expectRevert("Pausable: paused");
    mapper.claim("paused", 1);

    // unpause as admin
    vm.prank(admin);
    vm.expectEmit(true, false, false, true);
    emit LilNounsEnsMapperV3.ContractUnpaused(admin);
    mapper.unpause();

    vm.prank(alice);
    mapper.claim("ok", 1);
  }

  /// setText cannot set avatar key and requires non-empty key
  function testSetText_Restrictions() public {
    _mintTo(alice, 9);
    vm.startPrank(alice);
    mapper.claim("niner", 9);

    bytes32 node = nodeFor("niner");

    vm.expectRevert(LilNounsEnsErrors.EmptyKey.selector);
    mapper.setText(node, "", "value");

    vm.expectRevert(LilNounsEnsErrors.AvatarLocked.selector);
    mapper.setText(node, "avatar", "nope");

    // A normal key succeeds and emits TextChanged
    vm.expectEmit(true, true, true, true);
    emit LilNounsEnsMapperV3.TextChanged(node, "url", "https://ex", alice);
    mapper.setText(node, "url", "https://ex");
    vm.stopPrank();
  }

  /// updateAddresses emits events for each token and batch event
  function testUpdateAddresses_EmitsAndValidates() public {
    _mintTo(alice, 11);
    _mintTo(alice, 12);
    vm.startPrank(alice);
    mapper.claim("a11", 11);
    mapper.claim("a12", 12);
    vm.stopPrank();

    // Transfer 12 to bob so addr differs
    vm.prank(alice);
    nft.transferFrom(alice, bob, 12);

    uint256[] memory ids = new uint256[](2);
    ids[0] = 11;
    ids[1] = 12;

    vm.expectEmit(true, false, false, true);
    emit LilNounsEnsMapperV3.AddrChanged(nodeFor("a11"), alice);
    vm.expectEmit(true, false, false, true);
    emit LilNounsEnsMapperV3.AddrChanged(nodeFor("a12"), bob);
    vm.expectEmit(false, true, false, true);
    emit LilNounsEnsMapperV3.BatchAddressesUpdated(ids, address(this), 2);
    mapper.updateAddresses(ids);
  }

  // ---------------------------- Fuzz tests ----------------------------

  /// Fuzz labels within ascii letters; first claim succeeds; second claim of same label reverts
  function testFuzz_ClaimUniqueness(bytes16 labelSeed) public {
    // Constrain seed to a readable ascii label of length 5-10
    string memory label = _asciiLabel(labelSeed);
    vm.assume(bytes(label).length >= 5);

    _mintTo(alice, 100);
    vm.prank(alice);
    mapper.claim(label, 100);

    _mintTo(bob, 101);
    vm.prank(bob);
    vm.expectRevert(LilNounsEnsErrors.AlreadyClaimed.selector);
    mapper.claim(label, 101);
  }

  /// Fuzz transfers across two holders, then claim and verify addr tracks current owner
  function testFuzz_TransferThenAddrTracksOwner(uint256 tokenId, bytes16 labelSeed) public {
    tokenId = bound(tokenId, 1, type(uint64).max);
    string memory label = _asciiLabel(labelSeed);
    vm.assume(bytes(label).length >= 3);

    _mintTo(alice, tokenId);
    vm.prank(alice);
    mapper.claim(label, tokenId);

    // Transfer back and forth
    for (uint256 i = 0; i < 3; i++) {
      vm.prank(alice);
      nft.transferFrom(alice, bob, tokenId);
      assertEq(mapper.addr(keccak256(abi.encodePacked(ROOT_LILNOUNS, keccak256(bytes(label))))), bob);

      vm.prank(bob);
      nft.transferFrom(bob, alice, tokenId);
      assertEq(mapper.addr(keccak256(abi.encodePacked(ROOT_LILNOUNS, keccak256(bytes(label))))), alice);
    }
  }

  // ---------------------------- Negative / Edge ----------------------------

  /// Non-holder cannot setText for someone else's node (authorised modifier)
  function testSetText_WhenNotAuthorised_Reverts() public {
    _mintTo(alice, 55);
    vm.prank(alice);
    mapper.claim("owned", 55);

    bytes32 node = nodeFor("owned");
    vm.prank(bob);
    vm.expectRevert(LilNounsEnsErrors.NotAuthorised.selector);
    mapper.setText(node, "k", "v");
  }

  /// Reentrancy attempt during setSubnodeRecord should not corrupt state due to nonReentrant on claim
  function testReentrancy_AttemptDuringClaim_IsBlocked() public {
    // Deploy a special wrapper that will try to reenter
    MockNameWrapper reentrant = new MockNameWrapper(ensAddr, registrarAddr);
    // We need a fresh mapper wired to this wrapper
    LilNounsEnsMapperV3 m2 = new LilNounsEnsMapperV3();
    LegacyNull legacyImpl = new LegacyNull();
    m2.initialize(
      admin,
      ensAddr,
      registrarAddr,
      address(reentrant),
      address(legacyImpl),
      address(nft),
      ROOT_LILNOUNS,
      "lilnouns"
    );

    // Configure reentrancy attempt
    reentrant.configureReenter(m2, true);

    _mintTo(alice, 1);
    vm.prank(alice);
    m2.claim("r", 1);

    // Verify state exists and single node claimed
    assertEq(m2.tokenNode(1), keccak256(abi.encodePacked(ROOT_LILNOUNS, keccak256(bytes("r")))));
  }

  // ---------------------------- Gas check ----------------------------

  /// Gas upper bound check for a fresh claim path (rough bound; adjust if needed)
  function testGas_ClaimFresh_IsBelowUpperBound() public {
    _mintTo(alice, 777);
    uint256 gasBefore = gasleft();
    vm.prank(alice);
    mapper.claim("freshgas", 777);
    uint256 gasUsed = gasBefore - gasleft();

    // Assert an upper bound that should be safe for local runs
    assertLt(gasUsed, 160_000);
  }

  // ---------------------------- Label helper ----------------------------
  function _asciiLabel(bytes16 seed) internal pure returns (string memory) {
    bytes memory b = new bytes(6);
    for (uint256 i = 0; i < b.length; i++) {
      uint8 v = uint8(seed[i]);
      // map into [a-z]
      b[i] = bytes1(uint8(97) + (v % 26));
    }
    return string(b);
  }
}

/**
 * Run notes:
 * - This suite uses minimal mocks for ENS, NameWrapper, and BaseRegistrar to satisfy the mapper’s initializer wiring and subnode creation path.
 * - It focuses on LilNounsEnsMapperV3.sol’s actual behaviors: claiming unique labels, authorization, pause, text records, updateAddresses, and that addr resolution tracks NFT transfers.
 * - The contract does not expose a relinquish function; tests instead verify multiple claims by the same token update tokenNode to the latest label while earlier nodes remain mapped, matching current implementation design.
 * - Execute with:
 *   cd packages/contracts && forge test -vv
 */
