// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { Test, console2 as console } from "forge-std/Test.sol";

import { LilNounsEnsMapperV2 } from "../src/LilNounsEnsMapperV2.sol";
import { ILilNounsEnsMapperV1 } from "../src/interfaces/ILilNounsEnsMapperV1.sol";
import { LilNounsEnsErrors } from "../src/libraries/LilNounsEnsErrors.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Minimal ENS mock that supports the functions used by the CUT
contract MockENS {
  // Store last set data for optional assertions
  struct Record {
    address owner;
    address resolver;
    uint64 ttl;
  }

  mapping(bytes32 => Record) public records; // node => record

  event NewSubnode(bytes32 indexed parent, bytes32 indexed label, address owner, address resolver, uint64 ttl);
  event ResolverSet(bytes32 indexed node, address resolver);

  function setSubnodeRecord(bytes32 parentNode, bytes32 label, address owner, address resolver, uint64 ttl) external {
    bytes32 node = keccak256(abi.encodePacked(parentNode, label));
    records[node] = Record(owner, resolver, ttl);
    emit NewSubnode(parentNode, label, owner, resolver, ttl);
  }

  function setResolver(bytes32 node, address resolver) external {
    records[node].resolver = resolver;
    emit ResolverSet(node, resolver);
  }
}

// Minimal legacy mapper mock
contract MockLegacy is ILilNounsEnsMapperV1 {
  IERC721 public immutable _nft;
  bytes32 public _domainHash;
  mapping(uint256 => bytes32) public tokenHashmapMock;
  mapping(bytes32 => uint256) public hashToIdMapMock;
  mapping(bytes32 => string) public hashToDomainMapMock;

  constructor(IERC721 nft_, bytes32 domainHash_) {
    _nft = nft_;
    _domainHash = domainHash_;
  }

  function nft() external view returns (IERC721) {
    return _nft;
  }

  function domainHash() external view returns (bytes32) {
    return _domainHash;
  }

  function name(bytes32 node) external view returns (string memory) {
    return hashToDomainMapMock[node];
  }

  function addr(bytes32 /*node*/) external view returns (address) {
    return address(0);
  }

  function text(bytes32, /*node*/ string calldata /*key*/) external pure returns (string memory) {
    return "";
  }

  function tokenHashmap(uint256 tokenId) external view returns (bytes32) {
    return tokenHashmapMock[tokenId];
  }

  function hashToIdMap(bytes32 node) external view returns (uint256) {
    return hashToIdMapMock[node];
  }

  function hashToDomainMap(bytes32 node) external view returns (string memory) {
    return hashToDomainMapMock[node];
  }

  // helpers for tests
  function setLegacyMapping(uint256 tokenId, bytes32 node, string memory label) external {
    tokenHashmapMock[tokenId] = node;
    hashToIdMapMock[node] = tokenId;
    hashToDomainMapMock[node] = label;
  }
}

// Simple mintable ERC721 for tokens
contract TestERC721 is ERC721 {
  constructor() ERC721("LilNouns", "LILNOUNS") {}

  function mint(address to, uint256 tokenId) external {
    _mint(to, tokenId);
  }
}

contract LilNounsEnsMapperV2Test is Test {
  // Actors
  address internal owner = makeAddr("owner");
  address internal alice = makeAddr("alice");
  address internal bob = makeAddr("bob");

  // Deployed contracts
  TestERC721 internal nft;
  MockENS internal ens;
  MockLegacy internal legacy;
  LilNounsEnsMapperV2 internal mapper;

  // Root
  string internal constant ROOT_LABEL = "lilnouns";
  bytes32 internal rootNode;

  // Events mirrors
  event SubdomainClaimed(address indexed registrar, uint256 indexed tokenId, bytes32 indexed node, string label);
  event AddrChanged(bytes32 indexed node, address a);

  function setUp() public {
    // Deploy minimal dependencies
    nft = new TestERC721();

    rootNode = namehash("lilnouns.eth");
    ens = new MockENS();
    legacy = new MockLegacy(IERC721(address(nft)), rootNode);

    // Deploy implementation and initialize (no proxy needed for tests)
    mapper = new LilNounsEnsMapperV2();
    vm.prank(owner);
    mapper.initialize(address(legacy), address(ens), rootNode, ROOT_LABEL);
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
    emit SubdomainClaimed(alice, tokenId, node, label);
    vm.expectEmit(address(mapper));
    emit AddrChanged(node, alice);
    mapper.claimSubdomain(label, tokenId);
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
    mapper.claimSubdomain(label, tokenId);

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
    mapper.claimSubdomain(label, tokenId);
  }

  function testClaimSubdomain_WhenTokenAlreadyClaimedV2_ShouldRevert() public {
    uint256 tokenId = 2;
    _mintTo(alice, tokenId);

    vm.prank(alice);
    mapper.claimSubdomain("a", tokenId);

    vm.prank(alice);
    vm.expectRevert(abi.encodeWithSelector(LilNounsEnsErrors.AlreadyClaimed.selector, tokenId));
    mapper.claimSubdomain("b", tokenId);
  }

  function testClaimSubdomain_WhenTokenAlreadyClaimedV1_ShouldRevert() public {
    uint256 tokenId = 3;
    _mintTo(alice, tokenId);

    string memory legacyLabel = "legacy3";
    bytes32 legacyNode = _nodeFor(legacyLabel);
    legacy.setLegacyMapping(tokenId, legacyNode, legacyLabel);

    vm.prank(alice);
    vm.expectRevert(abi.encodeWithSelector(LilNounsEnsErrors.AlreadyClaimed.selector, tokenId));
    mapper.claimSubdomain("new", tokenId);
  }

  function testClaimSubdomain_WhenLabelAlreadyTakenByAnotherToken_ShouldRevertWithExistingTokenId() public {
    string memory label = "taken";
    uint256 tokenA = 10;
    uint256 tokenB = 11;
    _mintTo(alice, tokenA);
    _mintTo(bob, tokenB);

    vm.prank(alice);
    mapper.claimSubdomain(label, tokenA);

    // Now Bob tries to claim the same label; expect AlreadyClaimed(tokenA)
    vm.prank(bob);
    vm.expectRevert(abi.encodeWithSelector(LilNounsEnsErrors.AlreadyClaimed.selector, tokenA));
    mapper.claimSubdomain(label, tokenB);
  }

  function testClaimSubdomain_WhenEmptyLabel_ShouldRevert() public {
    uint256 tokenId = 5;
    _mintTo(alice, tokenId);

    vm.prank(alice);
    vm.expectRevert(abi.encodeWithSelector(LilNounsEnsErrors.InvalidLabel.selector));
    mapper.claimSubdomain("", tokenId);
  }

  function testClaimSubdomain_WhenTokenDoesNotExist_ShouldBubbleERC721Revert() public {
    // ownerOf() must revert for nonexistent token
    uint256 nonexistentToken = 9999;
    vm.prank(alice);
    vm.expectRevert(); // generic since OZ uses custom message
    mapper.claimSubdomain("ghost", nonexistentToken);
  }

  // Attempt re-claim of same label by original owner with different token should still revert by taken label
  function testClaimSubdomain_WhenSameLabelDifferentTokenSameOwner_ShouldRevertTaken() public {
    string memory label = "dup";
    uint256 tokenA = 21;
    uint256 tokenB = 22;
    _mintTo(alice, tokenA);
    _mintTo(alice, tokenB);

    vm.prank(alice);
    mapper.claimSubdomain(label, tokenA);

    vm.prank(alice);
    vm.expectRevert(abi.encodeWithSelector(LilNounsEnsErrors.AlreadyClaimed.selector, tokenA));
    mapper.claimSubdomain(label, tokenB);
  }
}
