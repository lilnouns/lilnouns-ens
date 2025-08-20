// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Simple mintable ERC721 mock for tests
contract MockERC721 is ERC721 {
  constructor() ERC721("LilNouns", "LILNOUNS") {}

  function mint(address to, uint256 tokenId) external {
    _mint(to, tokenId);
  }
}
