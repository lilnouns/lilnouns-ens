// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

interface IEnsMapper {
  function tokenHashmap(uint256 tokenId) external view returns (bytes32);
  function hashToDomainMap(bytes32 node) external view returns (string memory);
}
