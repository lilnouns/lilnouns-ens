// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.29;

import { Test, console } from "forge-std/Test.sol";
import { LilNounsEnsMapperV2 } from "../src/LilNounsEnsMapperV2.sol";
import { ILilNounsEnsMapperV1 } from "../src/interfaces/ILilNounsEnsMapperV1.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

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

  /// @notice Mock address representing the legacy mapper contract
  /// @dev Used to test initialization and legacy contract integration
  address public mockLegacy;

  /// @notice The contract owner address (this test contract)
  /// @dev Used to test owner-only functions and access controls
  address public owner;

  /// @notice A regular user address for testing non-owner interactions
  /// @dev Used to verify access control restrictions work correctly
  address public user;

  /**
   * @notice Sets up the test environment before each test
   * @dev Deploys the implementation contract behind an ERC1967 proxy
   *      and initializes it with a mock legacy contract address.
   *      This setup ensures each test starts with a fresh, properly initialized contract.
   */
  function setUp() public {
    owner = address(this);
    user = address(0x1234);

    // Create a mock legacy contract
    mockLegacy = address(0x5678);

    // Deploy the implementation contract
    LilNounsEnsMapperV2 implementation = new LilNounsEnsMapperV2();

    // Deploy the proxy and initialize
    bytes memory initData = abi.encodeWithSelector(LilNounsEnsMapperV2.initialize.selector, mockLegacy);

    ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
    mapper = LilNounsEnsMapperV2(address(proxy));
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
    assertEq(address(mapper.legacy()), mockLegacy);
    assertEq(mapper.owner(), owner);
    assertFalse(mapper.paused());
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
}
