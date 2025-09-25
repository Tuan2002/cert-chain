// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CertificateType} from "../src/contracts/CertificateType.sol";

contract CertificateTypeTest is Test {
    CertificateType public certificateType;
    address public admin;
    address public nonAuthorized;

    // Test constants
    string public constant TYPE_ID = "TYPE001";
    string public constant TYPE_ID_2 = "TYPE002";

    // Events to test
    event CertificateTypeCreated(string indexed id, string name, string code);
    event CertificateTypeUpdated(string indexed id, string name, string code, string description);
    event CertificateTypeDeactivated(string indexed id);

    function setUp() public {
        admin = address(this);
        nonAuthorized = makeAddr("nonAuthorized");

        certificateType = new CertificateType(admin);
    }

    // Test certificate type creation
    function testCreateCertificateType() public {
        string memory name = "Computer Science Degree";
        string memory code = "CS_DEGREE";
        string memory description = "Bachelor of Science in Computer Science";

        vm.expectEmit(true, false, false, true);
        emit CertificateTypeCreated(TYPE_ID, name, code);

        certificateType.createCertificateType(TYPE_ID, name, code, description);

        CertificateType.CertificateTypeData memory certType = certificateType.getCertificateType(TYPE_ID);
        assertEq(certType.id, TYPE_ID);
        assertEq(certType.name, name);
        assertEq(certType.code, code);
        assertEq(certType.description, description);
        assertTrue(certType.isActive);
        assertGt(certType.createdAt, 0);
        assertGt(certType.updatedAt, 0);
    }

    function testCreateCertificateTypeFailsWithInvalidId() public {
        vm.expectRevert("Certificate type ID cannot be empty");
        certificateType.createCertificateType("", "Test Cert", "TEST", "Description");
    }

    function testCreateCertificateTypeFailsWithEmptyName() public {
        vm.expectRevert("Certificate type name cannot be empty");
        certificateType.createCertificateType(TYPE_ID, "", "TEST", "Description");
    }

    function testCreateCertificateTypeFailsWithEmptyCode() public {
        vm.expectRevert("Certificate type code cannot be empty");
        certificateType.createCertificateType(TYPE_ID, "Test Cert", "", "Description");
    }

    function testCreateCertificateTypeFailsWithDuplicateId() public {
        certificateType.createCertificateType(TYPE_ID, "Test Cert 1", "TEST1", "Description 1");
        
        vm.expectRevert("Certificate type with this ID already exists");
        certificateType.createCertificateType(TYPE_ID, "Test Cert 2", "TEST2", "Description 2");
    }

    function testCreateCertificateTypeFailsWithDuplicateCode() public {
        certificateType.createCertificateType(TYPE_ID, "Test Cert 1", "TEST", "Description 1");
        
        vm.expectRevert("Certificate type with this code already exists");
        certificateType.createCertificateType(TYPE_ID_2, "Test Cert 2", "TEST", "Description 2");
    }

    function testCreateCertificateTypeFailsWithoutAdminRole() public {
        vm.prank(nonAuthorized);
        vm.expectRevert();
        certificateType.createCertificateType(TYPE_ID, "Test Cert", "TEST", "Description");
    }

    // Test certificate type updates
    function testUpdateCertificateType() public {
        certificateType.createCertificateType(TYPE_ID, "Original Name", "ORIG", "Original Description");
        
        string memory newName = "Updated Name";
        string memory newCode = "UPDATED";
        string memory newDescription = "Updated Description";

        vm.expectEmit(true, false, false, true);
        emit CertificateTypeUpdated(TYPE_ID, newName, newCode, newDescription);

        certificateType.updateCertificateType(TYPE_ID, newName, newCode, newDescription);

        CertificateType.CertificateTypeData memory certType = certificateType.getCertificateType(TYPE_ID);
        assertEq(certType.name, newName);
        assertEq(certType.code, newCode);
        assertEq(certType.description, newDescription);
    }

    function testUpdateCertificateTypeWithSameCode() public {
        string memory code = "SAME_CODE";
        certificateType.createCertificateType(TYPE_ID, "Original Name", code, "Original Description");

        // Should work fine updating with same code
        certificateType.updateCertificateType(TYPE_ID, "Updated Name", code, "Updated Description");

        CertificateType.CertificateTypeData memory certType = certificateType.getCertificateType(TYPE_ID);
        assertEq(certType.name, "Updated Name");
    }

    function testUpdateCertificateTypeFailsWithDuplicateCode() public {
        certificateType.createCertificateType(TYPE_ID, "Cert 1", "CODE1", "Description 1");
        certificateType.createCertificateType(TYPE_ID_2, "Cert 2", "CODE2", "Description 2");

        vm.expectRevert("Certificate type with this code already exists");
        certificateType.updateCertificateType(TYPE_ID_2, "Updated Cert 2", "CODE1", "Updated Description 2");
    }

    function testUpdateNonExistentCertificateType() public {
        vm.expectRevert("Certificate type does not exist");
        certificateType.updateCertificateType("NONEXISTENT", "Test", "TEST", "Description");
    }

    function testUpdateCertificateTypeFailsWithoutAdminRole() public {
        certificateType.createCertificateType(TYPE_ID, "Test Cert", "TEST", "Description");

        vm.prank(nonAuthorized);
        vm.expectRevert();
        certificateType.updateCertificateType(TYPE_ID, "Updated", "UPDATED", "Updated Description");
    }

    // Test certificate type deactivation
    function testDeactivateCertificateType() public {
        certificateType.createCertificateType(TYPE_ID, "Test Cert", "TEST", "Description");

        vm.expectEmit(true, false, false, false);
        emit CertificateTypeDeactivated(TYPE_ID);

        certificateType.deactivateCertificateType(TYPE_ID);

        CertificateType.CertificateTypeData memory certType = certificateType.getCertificateType(TYPE_ID);
        assertFalse(certType.isActive);
    }

    function testDeactivateNonExistentCertificateType() public {
        vm.expectRevert("Certificate type does not exist");
        certificateType.deactivateCertificateType("NONEXISTENT");
    }

    function testDeactivateCertificateTypeFailsWithoutAdminRole() public {
        certificateType.createCertificateType(TYPE_ID, "Test Cert", "TEST", "Description");

        vm.prank(nonAuthorized);
        vm.expectRevert();
        certificateType.deactivateCertificateType(TYPE_ID);
    }

    // Test certificate type reactivation
    function testReactivateCertificateType() public {
        certificateType.createCertificateType(TYPE_ID, "Test Cert", "TEST", "Description");
        certificateType.deactivateCertificateType(TYPE_ID);

        certificateType.reactivateCertificateType(TYPE_ID);

        CertificateType.CertificateTypeData memory certType = certificateType.getCertificateType(TYPE_ID);
        assertTrue(certType.isActive);
    }

    function testReactivateNonExistentCertificateType() public {
        vm.expectRevert("Certificate type does not exist");
        certificateType.reactivateCertificateType("NONEXISTENT");
    }

    // Test view functions
    function testGetCertificateTypeByCode() public {
        string memory code = "TEST_CODE";
        certificateType.createCertificateType(TYPE_ID, "Test Cert", code, "Description");

        CertificateType.CertificateTypeData memory certType = certificateType.getCertificateTypeByCode(code);
        assertEq(certType.id, TYPE_ID);
        assertEq(certType.code, code);
    }

    function testGetCertificateTypeByNonExistentCode() public {
        vm.expectRevert("Certificate type with this code does not exist");
        certificateType.getCertificateTypeByCode("NONEXISTENT");
    }

    function testCertificateTypeExists() public {
        assertFalse(certificateType.certificateTypeExists(TYPE_ID));
        
        certificateType.createCertificateType(TYPE_ID, "Test Cert", "TEST", "Description");
        assertTrue(certificateType.certificateTypeExists(TYPE_ID));
    }

    function testIsCertificateTypeActive() public {
        certificateType.createCertificateType(TYPE_ID, "Test Cert", "TEST", "Description");
        assertTrue(certificateType.isCertificateTypeActive(TYPE_ID));

        certificateType.deactivateCertificateType(TYPE_ID);
        assertFalse(certificateType.isCertificateTypeActive(TYPE_ID));
    }

    function testCodeExists() public {
        string memory code = "TEST_CODE";
        assertFalse(certificateType.codeExists(code));
        
        certificateType.createCertificateType(TYPE_ID, "Test Cert", code, "Description");
        assertTrue(certificateType.codeExists(code));
    }

    function testGetIdByCode() public {
        string memory code = "TEST_CODE";
        certificateType.createCertificateType(TYPE_ID, "Test Cert", code, "Description");

        string memory retrievedId = certificateType.getIdByCode(code);
        assertEq(retrievedId, TYPE_ID);
    }

    function testGetCertificateTypeCount() public {
        assertEq(certificateType.getCertificateTypeCount(), 0);
        
        certificateType.createCertificateType(TYPE_ID, "Test Cert 1", "CODE1", "Description 1");
        assertEq(certificateType.getCertificateTypeCount(), 1);
        
        certificateType.createCertificateType(TYPE_ID_2, "Test Cert 2", "CODE2", "Description 2");
        assertEq(certificateType.getCertificateTypeCount(), 2);
    }

    function testGetActiveCertificateTypes() public {
        certificateType.createCertificateType(TYPE_ID, "Active Cert", "ACTIVE", "Active Description");
        certificateType.createCertificateType(TYPE_ID_2, "Inactive Cert", "INACTIVE", "Inactive Description");
        
        certificateType.deactivateCertificateType(TYPE_ID_2);

        // Note: This method is deprecated and returns empty array by design
        CertificateType.CertificateTypeData[] memory activeTypes = certificateType.getActiveCertificateTypes();
        assertEq(activeTypes.length, 0);
    }

    function testGetAllCertificateTypes() public {
        certificateType.createCertificateType(TYPE_ID, "Cert 1", "CODE1", "Description 1");
        certificateType.createCertificateType(TYPE_ID_2, "Cert 2", "CODE2", "Description 2");

        // Note: This method is deprecated and returns empty array by design
        CertificateType.CertificateTypeData[] memory allTypes = certificateType.getAllCertificateTypes();
        assertEq(allTypes.length, 0);
    }
}