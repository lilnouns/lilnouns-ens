// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

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
