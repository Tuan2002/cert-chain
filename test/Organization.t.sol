// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Organization} from "../src/contracts/Organization.sol";

contract OrganizationTest is Test {
    Organization public organization;
    address public admin;
    address public owner1;
    address public owner2;
    address public manager1;
    address public manager2;
    address public nonAuthorized;

    // Test constants
    string public constant ORG_ID = "ORG001";
    string public constant ORG_ID_2 = "ORG002";

    // Events to test
    event OrganizationCreated(string indexed id, address indexed owner, string name, string countryCode);
    event OrganizationUpdated(string indexed id, string name, string countryCode);
    event OrganizationDeactivated(string indexed id);
    event ManagerAdded(string indexed orgId, address indexed manager);
    event ManagerRemoved(string indexed orgId, address indexed manager);
    event OwnershipTransferred(string indexed orgId, address indexed previousOwner, address indexed newOwner);

    function setUp() public {
        admin = address(this);
        owner1 = makeAddr("owner1");
        owner2 = makeAddr("owner2");
        manager1 = makeAddr("manager1");
        manager2 = makeAddr("manager2");
        nonAuthorized = makeAddr("nonAuthorized");

        organization = new Organization(admin);
    }

    // Test organization creation
    function testCreateOrganization() public {
        string memory name = "Test University";
        string memory countryCode = "US";

        vm.expectEmit(true, true, false, true);
        emit OrganizationCreated(ORG_ID, owner1, name, countryCode);

        organization.createOrganization(ORG_ID, owner1, name, countryCode);

        Organization.OrganizationData memory org = organization.getOrganization(ORG_ID);
        assertEq(org.id, ORG_ID);
        assertEq(org.owner, owner1);
        assertEq(org.name, name);
        assertEq(org.countryCode, countryCode);
        assertTrue(org.isActive);
        assertEq(org.managers.length, 0);
        assertGt(org.createdAt, 0);
        assertGt(org.updatedAt, 0);
    }

    function testCreateOrganizationFailsWithInvalidId() public {
        vm.expectRevert("Organization ID cannot be empty");
        organization.createOrganization("", owner1, "Test University", "US");
    }

    function testCreateOrganizationFailsWithInvalidOwner() public {
        vm.expectRevert("Owner address cannot be zero");
        organization.createOrganization(ORG_ID, address(0), "Test University", "US");
    }

    function testCreateOrganizationFailsWithEmptyName() public {
        vm.expectRevert("Organization name cannot be empty");
        organization.createOrganization(ORG_ID, owner1, "", "US");
    }

    function testCreateOrganizationFailsWithEmptyCountryCode() public {
        vm.expectRevert("Country code cannot be empty");
        organization.createOrganization(ORG_ID, owner1, "Test University", "");
    }

    function testCreateOrganizationFailsWithDuplicateId() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");
        
        vm.expectRevert("Organization with this ID already exists");
        organization.createOrganization(ORG_ID, owner2, "Another University", "CA");
    }

    function testCreateOrganizationFailsWithoutAdminRole() public {
        vm.prank(nonAuthorized);
        vm.expectRevert();
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");
    }

    // Test organization updates
    function testUpdateOrganization() public {
        organization.createOrganization(ORG_ID, owner1, "Original Name", "US");
        
        string memory newName = "Updated University";
        string memory newCountryCode = "CA";

        vm.expectEmit(true, false, false, true);
        emit OrganizationUpdated(ORG_ID, newName, newCountryCode);

        vm.prank(owner1);
        organization.updateOrganization(ORG_ID, newName, newCountryCode);

        Organization.OrganizationData memory org = organization.getOrganization(ORG_ID);
        assertEq(org.name, newName);
        assertEq(org.countryCode, newCountryCode);
    }

    function testUpdateOrganizationFailsWithUnauthorizedUser() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");

        vm.prank(nonAuthorized);
        vm.expectRevert("Only organization owner can perform this action");
        organization.updateOrganization(ORG_ID, "Updated Name", "CA");
    }

    function testUpdateNonExistentOrganization() public {
        vm.prank(owner1);
        vm.expectRevert("Organization does not exist");
        organization.updateOrganization("NONEXISTENT", "Test Name", "US");
    }

    // Test organization deactivation
    function testDeactivateOrganization() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");

        vm.expectEmit(true, false, false, false);
        emit OrganizationDeactivated(ORG_ID);

        organization.deactivateOrganization(ORG_ID);

        Organization.OrganizationData memory org = organization.getOrganization(ORG_ID);
        assertFalse(org.isActive);
    }

    function testDeactivateNonExistentOrganization() public {
        vm.expectRevert("Organization does not exist");
        organization.deactivateOrganization("NONEXISTENT");
    }

    function testDeactivateOrganizationFailsWithoutAdminRole() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");

        vm.prank(nonAuthorized);
        vm.expectRevert();
        organization.deactivateOrganization(ORG_ID);
    }

    // Test manager management
    function testAddManager() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");

        vm.expectEmit(true, true, false, false);
        emit ManagerAdded(ORG_ID, manager1);

        vm.prank(owner1);
        organization.addManager(ORG_ID, manager1);

        Organization.OrganizationData memory org = organization.getOrganization(ORG_ID);
        assertEq(org.managers.length, 1);
        assertEq(org.managers[0], manager1);
        assertTrue(organization.isOrganizationManager(ORG_ID, manager1));
    }

    function testAddManagerFailsWithUnauthorizedUser() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");

        vm.prank(nonAuthorized);
        vm.expectRevert("Only organization owner can perform this action");
        organization.addManager(ORG_ID, manager1);
    }

    function testAddManagerFailsWithZeroAddress() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");

        vm.prank(owner1);
        vm.expectRevert("Manager address cannot be zero");
        organization.addManager(ORG_ID, address(0));
    }

    function testAddManagerFailsWithDuplicateManager() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");

        vm.prank(owner1);
        organization.addManager(ORG_ID, manager1);

        vm.prank(owner1);
        vm.expectRevert("Manager already exists");
        organization.addManager(ORG_ID, manager1);
    }

    function testRemoveManager() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");
        
        vm.prank(owner1);
        organization.addManager(ORG_ID, manager1);
        
        vm.prank(owner1);
        organization.addManager(ORG_ID, manager2);

        vm.expectEmit(true, true, false, false);
        emit ManagerRemoved(ORG_ID, manager1);

        vm.prank(owner1);
        organization.removeManager(ORG_ID, manager1);

        Organization.OrganizationData memory org = organization.getOrganization(ORG_ID);
        assertEq(org.managers.length, 1);
        assertEq(org.managers[0], manager2);
        assertFalse(organization.isOrganizationManager(ORG_ID, manager1));
        assertTrue(organization.isOrganizationManager(ORG_ID, manager2));
    }

    function testRemoveManagerFailsWithUnauthorizedUser() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");
        
        vm.prank(owner1);
        organization.addManager(ORG_ID, manager1);

        vm.prank(nonAuthorized);
        vm.expectRevert("Only organization owner can perform this action");
        organization.removeManager(ORG_ID, manager1);
    }

    function testRemoveManagerFailsWithNonManager() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");

        vm.prank(owner1);
        vm.expectRevert("Manager does not exist");
        organization.removeManager(ORG_ID, manager1);
    }

    // Test ownership transfer
    function testTransferOwnership() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");

        vm.expectEmit(true, true, true, false);
        emit OwnershipTransferred(ORG_ID, owner1, owner2);

        // Admin calls transferOwnership, not the owner
        organization.transferOwnership(ORG_ID, owner2);

        Organization.OrganizationData memory org = organization.getOrganization(ORG_ID);
        assertEq(org.owner, owner2);
        assertTrue(organization.isOrganizationOwner(ORG_ID, owner2));
        assertFalse(organization.isOrganizationOwner(ORG_ID, owner1));
    }

    function testTransferOwnershipFailsWithUnauthorizedUser() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");

        vm.prank(nonAuthorized);
        vm.expectRevert();
        organization.transferOwnership(ORG_ID, owner2);
    }

    function testTransferOwnershipFailsWithZeroAddress() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");

        vm.expectRevert("New owner address cannot be zero");
        organization.transferOwnership(ORG_ID, address(0));
    }

    function testTransferOwnershipFailsWithSameOwner() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");

        vm.expectRevert("New owner is the same as current owner");
        organization.transferOwnership(ORG_ID, owner1);
    }

    // Test view functions
    function testOrganizationExists() public {
        assertFalse(organization.organizationExists(ORG_ID));
        
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");
        assertTrue(organization.organizationExists(ORG_ID));
    }

    function testIsOrganizationActive() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");
        assertTrue(organization.isOrganizationActive(ORG_ID));

        organization.deactivateOrganization(ORG_ID);
        assertFalse(organization.isOrganizationActive(ORG_ID));
    }

    function testIsOrganizationOwner() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");
        
        assertTrue(organization.isOrganizationOwner(ORG_ID, owner1));
        assertFalse(organization.isOrganizationOwner(ORG_ID, owner2));
    }

    function testIsOrganizationManager() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");
        
        vm.prank(owner1);
        organization.addManager(ORG_ID, manager1);
        
        assertTrue(organization.isOrganizationManager(ORG_ID, manager1));
        assertFalse(organization.isOrganizationManager(ORG_ID, manager2));
    }

    function testCanManageOrganization() public {
        organization.createOrganization(ORG_ID, owner1, "Test University", "US");
        
        vm.prank(owner1);
        organization.addManager(ORG_ID, manager1);
        
        // Owner can manage
        assertTrue(organization.canManageOrganization(ORG_ID, owner1));
        // Manager can manage
        assertTrue(organization.canManageOrganization(ORG_ID, manager1));
        // Others cannot
        assertFalse(organization.canManageOrganization(ORG_ID, manager2));
    }

    function testGetOrganizationCount() public {
        assertEq(organization.getOrganizationCount(), 0);
        
        organization.createOrganization(ORG_ID, owner1, "University 1", "US");
        assertEq(organization.getOrganizationCount(), 1);
        
        organization.createOrganization(ORG_ID_2, owner2, "University 2", "CA");
        assertEq(organization.getOrganizationCount(), 2);
    }

    function testGetOwnerOrganizations() public {
        organization.createOrganization(ORG_ID, owner1, "University 1", "US");
        organization.createOrganization(ORG_ID_2, owner2, "University 2", "CA");

        string[] memory owner1Orgs = organization.getOwnerOrganizations(owner1);
        string[] memory owner2Orgs = organization.getOwnerOrganizations(owner2);

        assertEq(owner1Orgs.length, 1);
        assertEq(owner2Orgs.length, 1);
        assertEq(owner1Orgs[0], ORG_ID);
        assertEq(owner2Orgs[0], ORG_ID_2);
    }

    function testGetManagerOrganizations() public {
        organization.createOrganization(ORG_ID, owner1, "University 1", "US");
        organization.createOrganization(ORG_ID_2, owner2, "University 2", "CA");

        vm.prank(owner1);
        organization.addManager(ORG_ID, manager1);
        
        vm.prank(owner2);
        organization.addManager(ORG_ID_2, manager1);

        string[] memory managerOrgs = organization.getManagerOrganizations(manager1);
        assertEq(managerOrgs.length, 2);
        
        // Check if both organizations are in the array
        bool foundOrg1 = false;
        bool foundOrg2 = false;
        for (uint256 i = 0; i < managerOrgs.length; i++) {
            if (keccak256(abi.encodePacked(managerOrgs[i])) == keccak256(abi.encodePacked(ORG_ID))) {
                foundOrg1 = true;
            }
            if (keccak256(abi.encodePacked(managerOrgs[i])) == keccak256(abi.encodePacked(ORG_ID_2))) {
                foundOrg2 = true;
            }
        }
        assertTrue(foundOrg1);
        assertTrue(foundOrg2);
    }

    // Test edge cases
    function testGetNonExistentOrganization() public {
        vm.expectRevert("Organization does not exist");
        organization.getOrganization("NONEXISTENT");
    }

    function testLargeOrganizationId() public {
        string memory largeId = "ORG999999999999999999";
        organization.createOrganization(largeId, owner1, "Large ID Org", "US");

        Organization.OrganizationData memory org = organization.getOrganization(largeId);
        assertEq(org.id, largeId);
        assertEq(org.owner, owner1);
    }
}