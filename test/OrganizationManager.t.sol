// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {OrganizationManager} from "../src/OrganizationManager.sol";
import {Organization} from "../src/contracts/Organization.sol";

contract OrganizationManagerTest is Test {
    OrganizationManager public organizationManager;
    Organization public organization;
    
    address public admin;
    address public orgOwner1;
    address public orgOwner2;
    address public manager1;
    address public nonAuthorized;

    // Test constants
    string public constant ORG_ID = "ORG001";
    string public constant ORG_ID_2 = "ORG002";

    // Events to test
    event OrganizationContractUpdated(address indexed oldContract, address indexed newContract);

    function setUp() public {
        admin = address(this);
        orgOwner1 = makeAddr("orgOwner1");
        orgOwner2 = makeAddr("orgOwner2");
        manager1 = makeAddr("manager1");
        nonAuthorized = makeAddr("nonAuthorized");

        // Deploy contracts
        organization = new Organization(admin);
        organizationManager = new OrganizationManager(admin, address(organization));

        // Grant manager permission to call organization contract
        organization.grantRole(organization.ADMIN_ROLE(), address(organizationManager));
    }

    // Test organization registration
    function testRegisterOrganization() public {
        string memory name = "Harvard University";
        string memory countryCode = "US";

        string memory returnedId = organizationManager.registerOrganization(ORG_ID, orgOwner1, name, countryCode);
        assertEq(returnedId, ORG_ID);

        Organization.OrganizationData memory org = organizationManager.getOrganization(ORG_ID);
        assertEq(org.id, ORG_ID);
        assertEq(org.owner, orgOwner1);
        assertEq(org.name, name);
        assertEq(org.countryCode, countryCode);
        assertTrue(org.isActive);
        assertEq(org.managers.length, 0);
        assertGt(org.createdAt, 0);
        assertGt(org.updatedAt, 0);
    }

    function testRegisterOrganizationFailsWithoutAdminRole() public {
        vm.prank(nonAuthorized);
        vm.expectRevert();
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Test Org", "US");
    }

    function testRegisterOrganizationFailsWithInvalidParameters() public {
        // Empty ID
        vm.expectRevert("Organization ID cannot be empty");
        organizationManager.registerOrganization("", orgOwner1, "Test Org", "US");

        // Zero address owner
        vm.expectRevert("Owner address cannot be zero");
        organizationManager.registerOrganization(ORG_ID, address(0), "Test Org", "US");

        // Empty name
        vm.expectRevert("Organization name cannot be empty");
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "", "US");

        // Empty country code
        vm.expectRevert("Country code cannot be empty");
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Test Org", "");
    }

    function testRegisterOrganizationFailsWithDuplicateId() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard University", "US");

        vm.expectRevert("Organization with this ID already exists");
        organizationManager.registerOrganization(ORG_ID, orgOwner2, "MIT", "US");
    }

    // Test organization updates
    function testUpdateOrganization() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard University", "US");

        string memory newName = "Harvard University - Updated";
        string memory newCountryCode = "CA";

        // Only admin can update organization through OrganizationManager
        organizationManager.updateOrganization(ORG_ID, newName, newCountryCode);

        Organization.OrganizationData memory org = organizationManager.getOrganization(ORG_ID);
        assertEq(org.name, newName);
        assertEq(org.countryCode, newCountryCode);
    }

    function testUpdateOrganizationFailsWithUnauthorized() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard University", "US");

        vm.prank(nonAuthorized);
        vm.expectRevert();
        organizationManager.updateOrganization(ORG_ID, "Updated Name", "CA");
    }

    function testUpdateNonExistentOrganization() public {
        vm.expectRevert("Organization does not exist");
        organizationManager.updateOrganization("NONEXISTENT", "Test Name", "US");
    }

    // Test organization deactivation
    function testDeactivateOrganization() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard University", "US");

        organizationManager.deactivateOrganization(ORG_ID);

        Organization.OrganizationData memory org = organizationManager.getOrganization(ORG_ID);
        assertFalse(org.isActive);
    }

    function testDeactivateOrganizationFailsWithoutAdminRole() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard University", "US");

        vm.prank(nonAuthorized);
        vm.expectRevert();
        organizationManager.deactivateOrganization(ORG_ID);
    }

    function testDeactivateNonExistentOrganization() public {
        vm.expectRevert("Organization does not exist");
        organizationManager.deactivateOrganization("NONEXISTENT");
    }

    // Test ownership transfer
    function testTransferOrganizationOwnership() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard University", "US");

        // Only admin can transfer ownership through OrganizationManager
        organizationManager.transferOrganizationOwnership(ORG_ID, orgOwner2);

        Organization.OrganizationData memory org = organizationManager.getOrganization(ORG_ID);
        assertEq(org.owner, orgOwner2);

        assertTrue(organizationManager.isOrganizationOwner(ORG_ID, orgOwner2));
        assertFalse(organizationManager.isOrganizationOwner(ORG_ID, orgOwner1));
    }

    function testTransferOwnershipFailsWithUnauthorized() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard University", "US");

        vm.prank(nonAuthorized);
        vm.expectRevert();
        organizationManager.transferOrganizationOwnership(ORG_ID, orgOwner2);
    }

    // Test manager management
    function testAddOrganizationManager() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard University", "US");

        vm.prank(orgOwner1);
        organizationManager.addOrganizationManager(ORG_ID, manager1);

        assertTrue(organizationManager.isOrganizationManager(ORG_ID, manager1));

        Organization.OrganizationData memory org = organizationManager.getOrganization(ORG_ID);
        assertEq(org.managers.length, 1);
        assertEq(org.managers[0], manager1);
    }

    function testAddOrganizationManagerFailsWithUnauthorized() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard University", "US");

        vm.prank(nonAuthorized);
        vm.expectRevert("Only admin or organization owner can add managers");
        organizationManager.addOrganizationManager(ORG_ID, manager1);
    }

    function testRemoveOrganizationManager() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard University", "US");

        vm.prank(orgOwner1);
        organizationManager.addOrganizationManager(ORG_ID, manager1);

        assertTrue(organizationManager.isOrganizationManager(ORG_ID, manager1));

        vm.prank(orgOwner1);
        organizationManager.removeOrganizationManager(ORG_ID, manager1);

        assertFalse(organizationManager.isOrganizationManager(ORG_ID, manager1));

        Organization.OrganizationData memory org = organizationManager.getOrganization(ORG_ID);
        assertEq(org.managers.length, 0);
    }

    function testRemoveOrganizationManagerFailsWithUnauthorized() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard University", "US");

        vm.prank(orgOwner1);
        organizationManager.addOrganizationManager(ORG_ID, manager1);

        vm.prank(nonAuthorized);
        vm.expectRevert("Only admin or organization owner can remove managers");
        organizationManager.removeOrganizationManager(ORG_ID, manager1);
    }

    // Test view functions
    function testIsOrganizationOwner() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard University", "US");

        assertTrue(organizationManager.isOrganizationOwner(ORG_ID, orgOwner1));
        assertFalse(organizationManager.isOrganizationOwner(ORG_ID, orgOwner2));
    }

    function testCanManageOrganization() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard University", "US");

        vm.prank(orgOwner1);
        organizationManager.addOrganizationManager(ORG_ID, manager1);

        assertTrue(organizationManager.canManageOrganization(ORG_ID, orgOwner1)); // Owner
        assertTrue(organizationManager.canManageOrganization(ORG_ID, manager1)); // Manager
        assertFalse(organizationManager.canManageOrganization(ORG_ID, nonAuthorized)); // Neither
    }

    function testGetOrganizationCount() public {
        assertEq(organizationManager.getOrganizationCount(), 0);

        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard", "US");
        assertEq(organizationManager.getOrganizationCount(), 1);

        organizationManager.registerOrganization(ORG_ID_2, orgOwner2, "MIT", "US");
        assertEq(organizationManager.getOrganizationCount(), 2);
    }

    function testGetOwnerOrganizations() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard", "US");
        organizationManager.registerOrganization(ORG_ID_2, orgOwner2, "MIT", "US");

        string[] memory owner1Orgs = organizationManager.getOwnerOrganizations(orgOwner1);
        string[] memory owner2Orgs = organizationManager.getOwnerOrganizations(orgOwner2);

        assertEq(owner1Orgs.length, 1);
        assertEq(owner2Orgs.length, 1);
        assertEq(owner1Orgs[0], ORG_ID);
        assertEq(owner2Orgs[0], ORG_ID_2);
    }

    function testGetManagerOrganizations() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard", "US");
        organizationManager.registerOrganization(ORG_ID_2, orgOwner2, "MIT", "US");

        vm.prank(orgOwner1);
        organizationManager.addOrganizationManager(ORG_ID, manager1);

        vm.prank(orgOwner2);
        organizationManager.addOrganizationManager(ORG_ID_2, manager1);

        string[] memory managerOrgs = organizationManager.getManagerOrganizations(manager1);
        assertEq(managerOrgs.length, 2);

        // Check both orgs are in the array
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

    function testOrganizationExists() public {
        assertFalse(organizationManager.organizationExists(ORG_ID));

        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard", "US");
        assertTrue(organizationManager.organizationExists(ORG_ID));
    }

    function testIsOrganizationActive() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard", "US");
        assertTrue(organizationManager.isOrganizationActive(ORG_ID));

        organizationManager.deactivateOrganization(ORG_ID);
        assertFalse(organizationManager.isOrganizationActive(ORG_ID));
    }

    // Test batch operations
    function testGetOrganizations() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard", "US");
        organizationManager.registerOrganization(ORG_ID_2, orgOwner2, "MIT", "US");

        string[] memory orgIds = new string[](2);
        orgIds[0] = ORG_ID;
        orgIds[1] = ORG_ID_2;

        Organization.OrganizationData[] memory orgs = organizationManager.getOrganizations(orgIds);
        assertEq(orgs.length, 2);
        assertEq(orgs[0].id, ORG_ID);
        assertEq(orgs[1].id, ORG_ID_2);
    }

    function testOrganizationsExist() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard", "US");

        string[] memory orgIds = new string[](3);
        orgIds[0] = ORG_ID;
        orgIds[1] = ORG_ID_2;
        orgIds[2] = "NONEXISTENT";

        bool[] memory exists = organizationManager.organizationsExist(orgIds);
        assertEq(exists.length, 3);
        assertTrue(exists[0]);
        assertFalse(exists[1]);
        assertFalse(exists[2]);
    }

    // Test contract management
    function testUpdateOrganizationContract() public {
        Organization newOrganization = new Organization(admin);
        address oldContract = organizationManager.organizationContract();

        vm.expectEmit(true, true, false, false);
        emit OrganizationContractUpdated(oldContract, address(newOrganization));

        organizationManager.updateOrganizationContract(address(newOrganization));
        assertEq(organizationManager.organizationContract(), address(newOrganization));
    }

    function testUpdateOrganizationContractFailsWithoutAdminRole() public {
        Organization newOrganization = new Organization(admin);

        vm.prank(nonAuthorized);
        vm.expectRevert();
        organizationManager.updateOrganizationContract(address(newOrganization));
    }

    function testUpdateOrganizationContractFailsWithZeroAddress() public {
        vm.expectRevert("Invalid contract address");
        organizationManager.updateOrganizationContract(address(0));
    }

    // Test edge cases
    function testGetNonExistentOrganization() public {
        vm.expectRevert("Organization does not exist");
        organizationManager.getOrganization("NONEXISTENT");
    }

    function testMultipleManagerOperations() public {
        organizationManager.registerOrganization(ORG_ID, orgOwner1, "Harvard", "US");

        address manager2 = makeAddr("manager2");
        address manager3 = makeAddr("manager3");

        // Add multiple managers
        vm.prank(orgOwner1);
        organizationManager.addOrganizationManager(ORG_ID, manager1);

        vm.prank(orgOwner1);
        organizationManager.addOrganizationManager(ORG_ID, manager2);

        vm.prank(orgOwner1);
        organizationManager.addOrganizationManager(ORG_ID, manager3);

        Organization.OrganizationData memory org = organizationManager.getOrganization(ORG_ID);
        assertEq(org.managers.length, 3);

        assertTrue(organizationManager.isOrganizationManager(ORG_ID, manager1));
        assertTrue(organizationManager.isOrganizationManager(ORG_ID, manager2));
        assertTrue(organizationManager.isOrganizationManager(ORG_ID, manager3));

        // Remove middle manager
        vm.prank(orgOwner1);
        organizationManager.removeOrganizationManager(ORG_ID, manager2);

        org = organizationManager.getOrganization(ORG_ID);
        assertEq(org.managers.length, 2);
        assertFalse(organizationManager.isOrganizationManager(ORG_ID, manager2));
    }
}