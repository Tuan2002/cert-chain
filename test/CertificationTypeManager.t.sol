// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CertificationTypeManager} from "../src/CertificationTypeManager.sol";
import {CertificateType} from "../src/contracts/CertificateType.sol";

contract CertificationTypeManagerTest is Test {
    CertificationTypeManager public typeManager;
    CertificateType public certificateType;
    
    address public admin;
    address public nonAuthorized;

    // Events to test
    event CertificateTypeContractUpdated(address indexed oldContract, address indexed newContract);

    function setUp() public {
        admin = address(this);
        nonAuthorized = makeAddr("nonAuthorized");

        // Deploy contracts
        certificateType = new CertificateType(admin);
        typeManager = new CertificationTypeManager(admin, address(certificateType));

        // Grant manager permission to call certificate type contract
        certificateType.grantRole(certificateType.ADMIN_ROLE(), address(typeManager));
    }

    // Test certificate type creation
    function testCreateCertificateType() public {
        string memory typeId = "1";
        string memory name = "Computer Science Degree";
        string memory code = "CS_DEGREE";
        string memory description = "Bachelor of Science in Computer Science";

        string memory returnedId = typeManager.createCertificateType(typeId, name, code, description);
        assertEq(returnedId, typeId);

        CertificateType.CertificateTypeData memory certType = typeManager.getCertificateType(typeId);
        assertEq(certType.id, typeId);
        assertEq(certType.name, name);
        assertEq(certType.code, code);
        assertEq(certType.description, description);
        assertTrue(certType.isActive);
    }

    function testCreateCertificateTypeFailsWithoutAdminRole() public {
        vm.prank(nonAuthorized);
        vm.expectRevert();
        typeManager.createCertificateType("1", "Test Cert", "TEST", "Description");
    }

    function testCreateCertificateTypeFailsWithoutValidContract() public {
        CertificationTypeManager invalidManager = new CertificationTypeManager(admin, address(0));
        
        vm.expectRevert("Certificate type contract not set");
        invalidManager.createCertificateType("1", "Test Cert", "TEST", "Description");
    }

    // Test certificate type updates
    function testUpdateCertificateType() public {
        string memory typeId = "1";
        typeManager.createCertificateType(typeId, "Original Name", "ORIG", "Original Description");

        string memory newName = "Updated Name";
        string memory newCode = "UPDATED";
        string memory newDescription = "Updated Description";

        typeManager.updateCertificateType(typeId, newName, newCode, newDescription);

        CertificateType.CertificateTypeData memory certType = typeManager.getCertificateType(typeId);
        assertEq(certType.name, newName);
        assertEq(certType.code, newCode);
        assertEq(certType.description, newDescription);
    }

    function testUpdateCertificateTypeFailsWithoutAdminRole() public {
        string memory typeId = "1";
        typeManager.createCertificateType(typeId, "Original Name", "ORIG", "Original Description");

        vm.prank(nonAuthorized);
        vm.expectRevert();
        typeManager.updateCertificateType(typeId, "Updated Name", "UPDATED", "Updated Description");
    }

    // Test certificate type deactivation
    function testDeactivateCertificateType() public {
        string memory typeId = "1";
        typeManager.createCertificateType(typeId, "Test Cert", "TEST", "Description");

        typeManager.deactivateCertificateType(typeId);

        assertFalse(typeManager.isCertificateTypeActive(typeId));
    }

    function testDeactivateCertificateTypeFailsWithoutAdminRole() public {
        string memory typeId = "1";
        typeManager.createCertificateType(typeId, "Test Cert", "TEST", "Description");

        vm.prank(nonAuthorized);
        vm.expectRevert();
        typeManager.deactivateCertificateType(typeId);
    }

    // Test certificate type reactivation
    function testReactivateCertificateType() public {
        string memory typeId = "1";
        typeManager.createCertificateType(typeId, "Test Cert", "TEST", "Description");
        typeManager.deactivateCertificateType(typeId);

        typeManager.reactivateCertificateType(typeId);

        assertTrue(typeManager.isCertificateTypeActive(typeId));
    }

    function testReactivateCertificateTypeFailsWithoutAdminRole() public {
        string memory typeId = "1";
        typeManager.createCertificateType(typeId, "Test Cert", "TEST", "Description");
        typeManager.deactivateCertificateType(typeId);

        vm.prank(nonAuthorized);
        vm.expectRevert();
        typeManager.reactivateCertificateType(typeId);
    }

    // Test view functions
    function testGetCertificateType() public {
        string memory typeId = "1";
        string memory name = "Test Certificate";
        string memory code = "TEST";
        string memory description = "Test Description";

        typeManager.createCertificateType(typeId, name, code, description);

        CertificateType.CertificateTypeData memory certType = typeManager.getCertificateType(typeId);
        assertEq(certType.id, typeId);
        assertEq(certType.name, name);
        assertEq(certType.code, code);
        assertEq(certType.description, description);
    }

    function testGetCertificateTypeByCode() public {
        string memory typeId = "1";
        string memory code = "CS_DEGREE";
        typeManager.createCertificateType(typeId, "Computer Science", code, "CS Degree");

        CertificateType.CertificateTypeData memory certType = typeManager.getCertificateTypeByCode(code);
        assertEq(certType.id, typeId);
        assertEq(certType.code, code);
    }

    function testCertificateTypeExists() public {
        assertFalse(typeManager.certificateTypeExists("1"));

        typeManager.createCertificateType("1", "Test Cert", "TEST", "Description");
        assertTrue(typeManager.certificateTypeExists("1"));
    }

    function testIsCertificateTypeActive() public {
        typeManager.createCertificateType("1", "Test Cert", "TEST", "Description");
        assertTrue(typeManager.isCertificateTypeActive("1"));

        typeManager.deactivateCertificateType("1");
        assertFalse(typeManager.isCertificateTypeActive("1"));
    }

    function testCodeExists() public {
        assertFalse(typeManager.codeExists("TEST"));

        typeManager.createCertificateType("1", "Test Cert", "TEST", "Description");
        assertTrue(typeManager.codeExists("TEST"));
    }

    function testGetIdByCode() public {
        string memory typeId = "1";
        string memory code = "TEST";
        typeManager.createCertificateType(typeId, "Test Cert", code, "Description");

        assertEq(typeManager.getIdByCode(code), typeId);
    }

    function testGetCertificateTypeCount() public {
        assertEq(typeManager.getCertificateTypeCount(), 0);

        typeManager.createCertificateType("1", "Cert 1", "CODE1", "Description 1");
        assertEq(typeManager.getCertificateTypeCount(), 1);

        typeManager.createCertificateType("2", "Cert 2", "CODE2", "Description 2");
        assertEq(typeManager.getCertificateTypeCount(), 2);
    }

    function testGetActiveCertificateTypes() public {
        typeManager.createCertificateType("1", "Active Cert 1", "ACTIVE1", "Description 1");
        typeManager.createCertificateType("2", "Active Cert 2", "ACTIVE2", "Description 2");
        typeManager.createCertificateType("3", "Inactive Cert", "INACTIVE", "Description 3");

        typeManager.deactivateCertificateType("3");

        // Note: This method is deprecated and returns empty array by design
        CertificateType.CertificateTypeData[] memory activeTypes = typeManager.getActiveCertificateTypes();
        assertEq(activeTypes.length, 0);
    }

    function testGetAllCertificateTypes() public {
        typeManager.createCertificateType("1", "Cert 1", "CODE1", "Description 1");
        typeManager.createCertificateType("2", "Cert 2", "CODE2", "Description 2");
        typeManager.createCertificateType("3", "Cert 3", "CODE3", "Description 3");

        typeManager.deactivateCertificateType("2");

        // Note: This method is deprecated and returns empty array by design
        CertificateType.CertificateTypeData[] memory allTypes = typeManager.getAllCertificateTypes();
        assertEq(allTypes.length, 0);
    }

    // Test batch operations
    function testGetCertificateTypes() public {
        typeManager.createCertificateType("1", "Cert 1", "CODE1", "Description 1");
        typeManager.createCertificateType("2", "Cert 2", "CODE2", "Description 2");

        string[] memory typeIds = new string[](3);
        typeIds[0] = "1";
        typeIds[1] = "2";
        typeIds[2] = "999"; // Non-existent

        CertificateType.CertificateTypeData[] memory types = typeManager.getCertificateTypes(typeIds);
        assertEq(types.length, 3);
        assertEq(types[0].id, "1");
        assertEq(types[1].id, "2");
        assertEq(types[2].id, ""); // Default value for non-existent
    }

    function testCertificateTypesExist() public {
        typeManager.createCertificateType("1", "Cert 1", "CODE1", "Description 1");

        string[] memory typeIds = new string[](3);
        typeIds[0] = "1";
        typeIds[1] = "999"; // Non-existent
        typeIds[2] = "2"; // Non-existent

        bool[] memory exists = typeManager.certificateTypesExist(typeIds);
        assertEq(exists.length, 3);
        assertTrue(exists[0]);
        assertFalse(exists[1]);
        assertFalse(exists[2]);
    }

    function testGetCertificateTypesByCodes() public {
        typeManager.createCertificateType("1", "Cert 1", "CODE1", "Description 1");
        typeManager.createCertificateType("2", "Cert 2", "CODE2", "Description 2");

        string[] memory codes = new string[](3);
        codes[0] = "CODE1";
        codes[1] = "CODE2";
        codes[2] = "NONEXISTENT";

        CertificateType.CertificateTypeData[] memory types = typeManager.getCertificateTypesByCodes(codes);
        assertEq(types.length, 3);
        assertEq(types[0].id, "1");
        assertEq(types[1].id, "2");
        assertEq(types[2].id, ""); // Default value for non-existent
    }

    function testCodesExist() public {
        typeManager.createCertificateType("1", "Cert 1", "CODE1", "Description 1");

        string[] memory codes = new string[](3);
        codes[0] = "CODE1";
        codes[1] = "NONEXISTENT1";
        codes[2] = "NONEXISTENT2";

        bool[] memory exists = typeManager.codesExist(codes);
        assertEq(exists.length, 3);
        assertTrue(exists[0]);
        assertFalse(exists[1]);
        assertFalse(exists[2]);
    }

    function testBulkCreateCertificateTypes() public {
        string[] memory ids = new string[](3);
        string[] memory names = new string[](3);
        string[] memory codes = new string[](3);
        string[] memory descriptions = new string[](3);

        ids[0] = "1";
        ids[1] = "2";
        ids[2] = "3";

        names[0] = "CS Degree";
        names[1] = "IT Certificate";
        names[2] = "English Certificate";

        codes[0] = "CS";
        codes[1] = "IT";
        codes[2] = "ENG";

        descriptions[0] = "Computer Science Degree";
        descriptions[1] = "Information Technology Certificate";
        descriptions[2] = "English Language Certificate";

        typeManager.bulkCreateCertificateTypes(ids, names, codes, descriptions);

        // Verify all were created
        assertEq(typeManager.getCertificateTypeCount(), 3);
        assertTrue(typeManager.certificateTypeExists("1"));
        assertTrue(typeManager.certificateTypeExists("2"));
        assertTrue(typeManager.certificateTypeExists("3"));

        CertificateType.CertificateTypeData memory cert1 = typeManager.getCertificateType("1");
        assertEq(cert1.name, "CS Degree");
        assertEq(cert1.code, "CS");
    }

    function testBulkCreateCertificateTypesFailsWithMismatchedArrays() public {
        string[] memory ids = new string[](2);
        string[] memory names = new string[](3); // Mismatched length
        string[] memory codes = new string[](2);
        string[] memory descriptions = new string[](2);

        vm.expectRevert("Array length mismatch: ids and names");
        typeManager.bulkCreateCertificateTypes(ids, names, codes, descriptions);
    }

    function testBulkCreateCertificateTypesFailsWithoutAdminRole() public {
        string[] memory ids = new string[](1);
        string[] memory names = new string[](1);
        string[] memory codes = new string[](1);
        string[] memory descriptions = new string[](1);

        ids[0] = "1";
        names[0] = "Test";
        codes[0] = "TEST";
        descriptions[0] = "Description";

        vm.prank(nonAuthorized);
        vm.expectRevert();
        typeManager.bulkCreateCertificateTypes(ids, names, codes, descriptions);
    }

    function testBulkDeactivateCertificateTypes() public {
        typeManager.createCertificateType("1", "Cert 1", "CODE1", "Description 1");
        typeManager.createCertificateType("2", "Cert 2", "CODE2", "Description 2");
        typeManager.createCertificateType("3", "Cert 3", "CODE3", "Description 3");

        string[] memory typeIds = new string[](2);
        typeIds[0] = "1";
        typeIds[1] = "3";

        typeManager.bulkDeactivateCertificateTypes(typeIds);

        assertFalse(typeManager.isCertificateTypeActive("1"));
        assertTrue(typeManager.isCertificateTypeActive("2"));
        assertFalse(typeManager.isCertificateTypeActive("3"));
    }

    function testBulkDeactivateCertificateTypesFailsWithoutAdminRole() public {
        typeManager.createCertificateType("1", "Cert 1", "CODE1", "Description 1");

        string[] memory typeIds = new string[](1);
        typeIds[0] = "1";

        vm.prank(nonAuthorized);
        vm.expectRevert();
        typeManager.bulkDeactivateCertificateTypes(typeIds);
    }

    // Test contract management
    function testUpdateCertificateTypeContract() public {
        address newContract = makeAddr("newCertificateTypeContract");

        vm.expectEmit(true, true, false, false);
        emit CertificateTypeContractUpdated(address(certificateType), newContract);

        typeManager.updateCertificateTypeContract(newContract);

        assertEq(typeManager.certificateTypeContract(), newContract);
    }

    function testUpdateCertificateTypeContractFailsWithZeroAddress() public {
        vm.expectRevert("Invalid contract address");
        typeManager.updateCertificateTypeContract(address(0));
    }

    function testUpdateCertificateTypeContractFailsWithSameAddress() public {
        vm.expectRevert("Same contract address");
        typeManager.updateCertificateTypeContract(address(certificateType));
    }

    function testUpdateCertificateTypeContractFailsWithoutAdminRole() public {
        address newContract = makeAddr("newContract");

        vm.prank(nonAuthorized);
        vm.expectRevert();
        typeManager.updateCertificateTypeContract(newContract);
    }

    // Test edge cases
    function testGetNonExistentCertificateType() public {
        vm.expectRevert("Certificate type does not exist");
        typeManager.getCertificateType("999");
    }

    function testEmptyBatchOperations() public view {
        string[] memory emptyIds = new string[](0);
        string[] memory emptyCodes = new string[](0);
        
        CertificateType.CertificateTypeData[] memory types = typeManager.getCertificateTypes(emptyIds);
        bool[] memory exists = typeManager.certificateTypesExist(emptyIds);
        CertificateType.CertificateTypeData[] memory typesByCodes = typeManager.getCertificateTypesByCodes(emptyCodes);
        bool[] memory codesExistResult = typeManager.codesExist(emptyCodes);
        
        assertEq(types.length, 0);
        assertEq(exists.length, 0);
        assertEq(typesByCodes.length, 0);
        assertEq(codesExistResult.length, 0);
    }

    function testMultipleCertificateTypesWorkflow() public {
        // Create multiple certificate types
        typeManager.createCertificateType("1", "CS Degree", "CS", "Computer Science");
        typeManager.createCertificateType("2", "IT Cert", "IT", "Information Technology");
        typeManager.createCertificateType("3", "English Cert", "ENG", "English Language");

        // Verify all exist and are active
        assertEq(typeManager.getCertificateTypeCount(), 3);
        assertTrue(typeManager.isCertificateTypeActive("1"));
        assertTrue(typeManager.isCertificateTypeActive("2"));
        assertTrue(typeManager.isCertificateTypeActive("3"));

        // Deactivate one
        typeManager.deactivateCertificateType("2");
        assertFalse(typeManager.isCertificateTypeActive("2"));

        // Check active types count - Note: This method is deprecated and returns empty array by design
        CertificateType.CertificateTypeData[] memory activeTypes = typeManager.getActiveCertificateTypes();
        assertEq(activeTypes.length, 0);

        // Reactivate
        typeManager.reactivateCertificateType("2");
        assertTrue(typeManager.isCertificateTypeActive("2"));

        // Update one
        typeManager.updateCertificateType("1", "Computer Science Degree", "CS_DEGREE", "Updated CS Description");

        CertificateType.CertificateTypeData memory updated = typeManager.getCertificateType("1");
        assertEq(updated.name, "Computer Science Degree");
        assertEq(updated.code, "CS_DEGREE");
        assertEq(updated.description, "Updated CS Description");

        // Verify code mapping updated
        assertFalse(typeManager.codeExists("CS"));
        assertTrue(typeManager.codeExists("CS_DEGREE"));
        assertEq(typeManager.getIdByCode("CS_DEGREE"), "1");
    }

    function testLargeScaleBatchOperations() public {
        // Create a larger batch for performance testing
        string[] memory ids = new string[](10);
        string[] memory names = new string[](10);
        string[] memory codes = new string[](10);
        string[] memory descriptions = new string[](10);

        for (uint256 i = 0; i < 10; i++) {
            ids[i] = vm.toString(i + 1);
            names[i] = string(abi.encodePacked("Certificate ", vm.toString(i + 1)));
            codes[i] = string(abi.encodePacked("CODE", vm.toString(i + 1)));
            descriptions[i] = string(abi.encodePacked("Description ", vm.toString(i + 1)));
        }

        typeManager.bulkCreateCertificateTypes(ids, names, codes, descriptions);
        assertEq(typeManager.getCertificateTypeCount(), 10);

        // Bulk deactivate half
        string[] memory deactivateIds = new string[](5);
        for (uint256 i = 0; i < 5; i++) {
            deactivateIds[i] = vm.toString(i + 1);
        }

        typeManager.bulkDeactivateCertificateTypes(deactivateIds);

        // Verify active count - Note: This method is deprecated and returns empty array by design
        CertificateType.CertificateTypeData[] memory activeTypes = typeManager.getActiveCertificateTypes();
        assertEq(activeTypes.length, 0);
    }
}