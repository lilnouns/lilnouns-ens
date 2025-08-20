// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { ILilNounsEnsMapperV1 } from "../../src/interfaces/ILilNounsEnsMapperV1.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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
