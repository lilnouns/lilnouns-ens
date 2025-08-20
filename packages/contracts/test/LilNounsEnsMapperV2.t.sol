// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { Test, console2 as console } from "forge-std/Test.sol";

import { LilNounsEnsMapperV2 } from "../src/LilNounsEnsMapperV2.sol";
import { ILilNounsEnsMapperV1 } from "../src/interfaces/ILilNounsEnsMapperV1.sol";
import { LilNounsEnsErrors } from "../src/libraries/LilNounsEnsErrors.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { MockENS } from "./mocks/MockENS.sol";
import { MockLegacy } from "./mocks/MockLegacy.sol";
import { MockERC721 } from "./mocks/MockERC721.sol";

contract LilNounsEnsMapperV2Test is Test {
  // Actors
  address internal owner = makeAddr("owner");
  address internal alice = makeAddr("alice");
  address internal bob = makeAddr("bob");

  // Deployed contracts
  MockERC721 internal nft;
  MockENS internal ens;
  MockLegacy internal legacy;
  LilNounsEnsMapperV2 internal mapper;

  // Root
  string internal constant ROOT_LABEL = "lilnouns";
  bytes32 internal rootNode;

  // Events mirrors
  event SubnameClaimed(address indexed registrar, uint256 indexed tokenId, bytes32 indexed node, string label);
  event AddrChanged(bytes32 indexed node, address a);

  function setUp() public {
    // Deploy minimal dependencies
    nft = new MockERC721();

    rootNode = namehash("lilnouns.eth");
    ens = new MockENS();
    legacy = new MockLegacy(IERC721(address(nft)), rootNode);

    // Deploy implementation and initialize (no proxy needed for tests)
    mapper = new LilNounsEnsMapperV2();
    vm.prank(owner);
    mapper.initialize(owner, address(legacy), address(ens), rootNode, ROOT_LABEL);
  }

  // Utility: ENS namehash
  function namehash(string memory name_) internal pure returns (bytes32) {
    bytes32 node = bytes32(0);
    uint256 labelStart = 0;
    bytes memory s = bytes(name_);
    for (uint256 i = s.length; i > 0; ) {
      uint256 lastDot = i;
      while (i > 0 && s[i - 1] != ".") {
        unchecked {
          i--;
        }
      }
      bytes memory label;
      if (i == 0) {
        label = new bytes(lastDot - 0);
        for (uint256 j = 0; j < lastDot; ) {
          label[j] = s[j];
          unchecked {
            j++;
          }
        }
      } else {
        uint256 start = i;
        label = new bytes(lastDot - start);
        for (uint256 j = 0; j < lastDot - start; ) {
          label[j] = s[start + j];
          unchecked {
            j++;
          }
        }
        unchecked {
          i--;
        }
      }
      node = keccak256(abi.encodePacked(node, keccak256(label)));
    }
    return node;
  }

  function _nodeFor(string memory label) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(rootNode, keccak256(abi.encodePacked(label))));
  }

  function _mintTo(address to, uint256 tokenId) internal {
    nft.mint(to, tokenId);
  }

  // ============ Success cases ============
  function testClaimSubdomain_WhenValid_ShouldMapAndEmitEvents() public {
    uint256 tokenId = 42;
    string memory label = "noun42";
    _mintTo(alice, tokenId);
    bytes32 node = _nodeFor(label);

    vm.startPrank(alice);
    vm.expectEmit(address(mapper));
    emit SubnameClaimed(alice, tokenId, node, label);
    vm.expectEmit(address(mapper));
    emit AddrChanged(node, alice);
    mapper.claimSubname(label, tokenId);
    vm.stopPrank();

    // name() should reflect the new mapping
    string memory expected = string(abi.encodePacked(label, ".", ROOT_LABEL, ".eth"));
    assertEq(mapper.name(node), expected, "name() mismatch");

    // addr() should resolve to current owner of tokenId
    assertEq(mapper.addr(node), payable(alice));

    // Transfer NFT -> addr() should follow new owner
    vm.prank(alice);
    nft.transferFrom(alice, bob, tokenId);
    assertEq(mapper.addr(node), payable(bob));
  }

  // Long label edge case
  function testClaimSubdomain_WhenLongLabel_ShouldSucceed() public {
    uint256 tokenId = 7;
    // 200-char label
    bytes memory b = new bytes(200);
    for (uint256 i = 0; i < b.length; ) {
      b[i] = bytes1("a");
      unchecked {
        i++;
      }
    }
    string memory label = string(b);

    _mintTo(alice, tokenId);
    bytes32 node = _nodeFor(label);

    vm.prank(alice);
    mapper.claimSubname(label, tokenId);

    // Verify mapping via name()
    string memory expected = string(abi.encodePacked(label, ".", ROOT_LABEL, ".eth"));
    assertEq(mapper.name(node), expected);
  }

  // ============ Failure cases ============
  function testClaimSubdomain_WhenCallerNotOwner_ShouldRevert() public {
    uint256 tokenId = 1;
    string memory label = "x1";
    _mintTo(alice, tokenId);

    vm.prank(bob);
    vm.expectRevert(abi.encodeWithSelector(LilNounsEnsErrors.NotTokenOwner.selector, tokenId));
    mapper.claimSubname(label, tokenId);
  }

  function testClaimSubdomain_WhenTokenAlreadyClaimedV2_ShouldRevert() public {
    uint256 tokenId = 2;
    _mintTo(alice, tokenId);

    vm.prank(alice);
    mapper.claimSubname("a", tokenId);

    vm.prank(alice);
    vm.expectRevert(abi.encodeWithSelector(LilNounsEnsErrors.AlreadyClaimed.selector, tokenId));
    mapper.claimSubname("b", tokenId);
  }

  function testClaimSubdomain_WhenTokenAlreadyClaimedV1_ShouldRevert() public {
    uint256 tokenId = 3;
    _mintTo(alice, tokenId);

    string memory legacyLabel = "legacy3";
    bytes32 legacyNode = _nodeFor(legacyLabel);
    legacy.setLegacyMapping(tokenId, legacyNode, legacyLabel);

    vm.prank(alice);
    vm.expectRevert(abi.encodeWithSelector(LilNounsEnsErrors.AlreadyClaimed.selector, tokenId));
    mapper.claimSubname("new", tokenId);
  }

  function testClaimSubdomain_WhenLabelAlreadyTakenByAnotherToken_ShouldRevertWithExistingTokenId() public {
    string memory label = "taken";
    uint256 tokenA = 10;
    uint256 tokenB = 11;
    _mintTo(alice, tokenA);
    _mintTo(bob, tokenB);

    vm.prank(alice);
    mapper.claimSubname(label, tokenA);

    // Now Bob tries to claim the same label; expect AlreadyClaimed(tokenA)
    vm.prank(bob);
    vm.expectRevert(abi.encodeWithSelector(LilNounsEnsErrors.AlreadyClaimed.selector, tokenA));
    mapper.claimSubname(label, tokenB);
  }

  function testClaimSubdomain_WhenEmptyLabel_ShouldRevert() public {
    uint256 tokenId = 5;
    _mintTo(alice, tokenId);

    vm.prank(alice);
    vm.expectRevert(abi.encodeWithSelector(LilNounsEnsErrors.InvalidLabel.selector));
    mapper.claimSubname("", tokenId);
  }

  function testClaimSubdomain_WhenTokenDoesNotExist_ShouldBubbleERC721Revert() public {
    // ownerOf() must revert for nonexistent token
    uint256 nonexistentToken = 9999;
    vm.prank(alice);
    vm.expectRevert(); // generic since OZ uses custom message
    mapper.claimSubname("ghost", nonexistentToken);
  }

  // Attempt re-claim of same label by original owner with different token should still revert by taken label
  function testClaimSubdomain_WhenSameLabelDifferentTokenSameOwner_ShouldRevertTaken() public {
    string memory label = "dup";
    uint256 tokenA = 21;
    uint256 tokenB = 22;
    _mintTo(alice, tokenA);
    _mintTo(alice, tokenB);

    vm.prank(alice);
    mapper.claimSubname(label, tokenA);

    vm.prank(alice);
    vm.expectRevert(abi.encodeWithSelector(LilNounsEnsErrors.AlreadyClaimed.selector, tokenA));
    mapper.claimSubname(label, tokenB);
  }

  // ============ ensNameOf / ensNamesOf tests ============

  function testEnsNameOf_WhenV2Claimed_ShouldReturnFullName() public {
    uint256 tokenId = 100;
    string memory label = "noun100";
    _mintTo(alice, tokenId);

    vm.prank(alice);
    mapper.claimSubname(label, tokenId);

    string memory expected = string(abi.encodePacked(label, ".", ROOT_LABEL, ".eth"));
    assertEq(mapper.ensNameOf(tokenId), expected, "ensNameOf should return full V2 name");
  }

  function testEnsNameOf_WhenLegacyOnly_ShouldFallback() public {
    uint256 tokenId = 200;
    string memory legacyLabel = "legacy200";
    bytes32 legacyNode = _nodeFor(legacyLabel);

    // Set only legacy mapping; do not claim in V2
    legacy.setLegacyMapping(tokenId, legacyNode, legacyLabel);

    // MockLegacy.name(node) returns the label (not full domain) in this test harness
    assertEq(mapper.ensNameOf(tokenId), legacyLabel, "ensNameOf should fallback to legacy name");
  }

  // ============ Fuzz tests for claimSubname ============
  function _labelFrom(bytes32 salt, uint256 idx) internal pure returns (string memory) {
    // produce a non-empty, ascii lower-case label using salt and idx
    bytes memory alphabet = "abcdefghijklmnopqrstuvwxyz0123456789";
    uint256 len = 6 + (uint256(salt) % 10); // 6..15
    bytes memory out = new bytes(len);
    uint256 x = uint256(keccak256(abi.encodePacked(salt, idx)));
    for (uint256 i = 0; i < len; ) {
      out[i] = alphabet[x % alphabet.length];
      x /= 37;
      unchecked {
        ++i;
      }
    }
    return string(out);
  }

  function testFuzz_ClaimSubname_SucceedsForOwner(uint256 tokenId, bytes32 salt) public {
    tokenId = bound(tokenId, 1, type(uint128).max);
    string memory label = _labelFrom(salt, tokenId);
    bytes32 node = _nodeFor(label);

    _mintTo(alice, tokenId);

    vm.startPrank(alice);
    vm.expectEmit(address(mapper));
    emit SubnameClaimed(alice, tokenId, node, label);
    vm.expectEmit(address(mapper));
    emit AddrChanged(node, alice);
    mapper.claimSubname(label, tokenId);
    vm.stopPrank();

    // Check properties
    assertEq(mapper.addr(node), payable(alice));
    string memory expected = string(abi.encodePacked(label, ".", ROOT_LABEL, ".eth"));
    assertEq(mapper.name(node), expected);
  }

  function testFuzz_ClaimSubname_RevertOnDuplicateLabel(uint256 tokenA, uint256 tokenB, bytes32 salt) public {
    tokenA = bound(tokenA, 1, type(uint64).max);
    tokenB = bound(tokenB, 1, type(uint64).max);
    vm.assume(tokenA != tokenB);

    string memory label = _labelFrom(salt, 1);
    bytes32 node = _nodeFor(label);

    _mintTo(alice, tokenA);
    _mintTo(bob, tokenB);

    vm.prank(alice);
    mapper.claimSubname(label, tokenA);

    vm.prank(bob);
    vm.expectRevert(abi.encodeWithSelector(LilNounsEnsErrors.AlreadyClaimed.selector, tokenA));
    mapper.claimSubname(label, tokenB);

    // Ensure mapping remains to tokenA
    assertEq(mapper.addr(node), payable(alice));
  }

  function testFuzz_ClaimSubname_RevertOnUnauthorized(uint256 tokenId, bytes32 salt) public {
    tokenId = bound(tokenId, 1, type(uint64).max);
    string memory label = _labelFrom(salt, 2);

    _mintTo(alice, tokenId);

    vm.prank(bob);
    vm.expectRevert(abi.encodeWithSelector(LilNounsEnsErrors.NotTokenOwner.selector, tokenId));
    mapper.claimSubname(label, tokenId);
  }

  function testFuzz_ClaimSubname_UniquenessInvariant(uint256 n, bytes32 seed) public {
    n = bound(n, 1, 20);

    bytes32[] memory nodes = new bytes32[](n);

    // Create n distinct claims
    for (uint256 i = 0; i < n; ) {
      uint256 tokenId = i + 1; // avoid 0 sentinel
      string memory label = _labelFrom(seed, i + 1000);
      nodes[i] = _nodeFor(label);

      _mintTo(alice, tokenId);
      vm.prank(alice);
      mapper.claimSubname(label, tokenId);
      unchecked {
        ++i;
      }
    }

    // Invariant: all nodes are unique and resolve to distinct tokenIds
    for (uint256 i = 0; i < n; ) {
      for (uint256 j = i + 1; j < n; ) {
        vm.assume(i != j);
        assertTrue(nodes[i] != nodes[j], "duplicate node detected");
        unchecked {
          ++j;
        }
      }
      unchecked {
        ++i;
      }
    }
  }

  // ============ Fuzz tests for migrateLegacySubname ============
  function testFuzz_MigrateLegacySubname_Succeeds(uint256 tokenId, bytes32 salt) public {
    tokenId = bound(tokenId, 1, type(uint64).max);
    string memory label = _labelFrom(salt, 77);
    bytes32 node = _nodeFor(label);

    // Prepare legacy mapping and mint the NFT to alice
    legacy.setLegacyMapping(tokenId, node, label);
    _mintTo(alice, tokenId);

    vm.startPrank(owner);
    vm.expectEmit(address(mapper));
    emit SubnameClaimed(alice, tokenId, node, label);
    vm.expectEmit(address(mapper));
    emit AddrChanged(node, alice);
    mapper.migrateLegacySubname(tokenId);
    vm.stopPrank();

    // Properties preserved
    assertEq(mapper.addr(node), payable(alice));
    string memory expected = string(abi.encodePacked(label, ".", ROOT_LABEL, ".eth"));
    assertEq(mapper.name(node), expected);
    assertEq(mapper.ensNameOf(tokenId), expected);
    assertFalse(mapper.isLegacySubname(tokenId));
  }

  function testFuzz_MigrateLegacySubname_RevertIfUnregistered(uint256 tokenId) public {
    tokenId = bound(tokenId, 1, type(uint64).max);
    // Ensure legacy has no mapping for tokenId
    vm.prank(owner);
    vm.expectRevert(abi.encodeWithSelector(LilNounsEnsErrors.UnregisteredNode.selector, bytes32(0)));
    mapper.migrateLegacySubname(tokenId);
  }

  function testFuzz_MigrateLegacySubname_RevertIfCallerNotOwner(uint256 tokenId, bytes32 salt) public {
    tokenId = bound(tokenId, 1, type(uint64).max);
    string memory label = _labelFrom(salt, 99);
    bytes32 node = _nodeFor(label);

    legacy.setLegacyMapping(tokenId, node, label);
    _mintTo(alice, tokenId);

    vm.prank(alice);
    vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", alice));
    mapper.migrateLegacySubname(tokenId);
  }

  function testFuzz_MigrateLegacySubname_RevertOnConflictWithExistingV2(
    uint256 tokenX,
    uint256 tokenY,
    bytes32 salt
  ) public {
    tokenX = bound(tokenX, 1, type(uint64).max);
    tokenY = bound(tokenY, 1, type(uint64).max);
    vm.assume(tokenX != tokenY);

    string memory label = _labelFrom(salt, 12345);
    bytes32 node = _nodeFor(label);

    // V2 already claimed by tokenX
    _mintTo(alice, tokenX);
    vm.prank(alice);
    mapper.claimSubname(label, tokenX);

    // Legacy tries to migrate same label for tokenY
    legacy.setLegacyMapping(tokenY, node, label);
    _mintTo(bob, tokenY);

    vm.prank(owner);
    vm.expectRevert(abi.encodeWithSelector(LilNounsEnsErrors.AlreadyClaimed.selector, tokenX));
    mapper.migrateLegacySubname(tokenY);
  }
}
