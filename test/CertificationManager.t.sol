// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CertificationManager} from "../src/CertificationManager.sol";
import {OrganizationManager} from "../src/OrganizationManager.sol";
import {CertificationTypeManager} from "../src/CertificationTypeManager.sol";
import {Organization} from "../src/contracts/Organization.sol";
import {CertificateType} from "../src/contracts/CertificateType.sol";
import {Certificate} from "../src/contracts/Certificate.sol";

contract CertificationManagerTest is Test {
    CertificationManager public certificationManager;
    OrganizationManager public organizationManager;
    CertificationTypeManager public typeManager;
    Organization public organization;
    CertificateType public certificateType;
    Certificate public certificate;
    
    address public admin;
    address public orgOwner;
    address public orgManager;
    address public nonAuthorized;

    // Test constants
    string public constant ORG_ID = "1";
    string public constant CERT_TYPE_ID = "1";
    string public constant CERT_ID = "1";
    string public constant CERT_ID_2 = "2";
    string public constant HOLDER_ID = "123456789";
    string public constant HOLDER_COUNTRY = "US";
    uint256 public constant GRANT_LEVEL = 85;
    string public constant IPFS_HASH = "QmX1234567890abcdef";

    // Events to test
    event SystemPaused(address indexed admin);
    event SystemUnpaused(address indexed admin);
    event ContractUpdated(string indexed contractName, address indexed oldContract, address indexed newContract);

    function setUp() public {
        // Use vm.addr to get addresses from private keys for proper signature testing
        admin = vm.addr(0x3); // Address corresponding to private key 0x3
        orgOwner = vm.addr(0x1); // Address corresponding to private key 0x1
        orgManager = vm.addr(0x2); // Address corresponding to private key 0x2
        nonAuthorized = makeAddr("nonAuthorized");

        // Deploy all contracts as admin
        vm.startPrank(admin);
        organization = new Organization(admin);
        certificateType = new CertificateType(admin);
        certificate = new Certificate(admin, address(organization), address(certificateType));
        organizationManager = new OrganizationManager(admin, address(organization));
        typeManager = new CertificationTypeManager(admin, address(certificateType));
        certificationManager = new CertificationManager(admin);
        vm.stopPrank();

        // Initialize the certification manager with contract addresses
        vm.prank(admin);
        certificationManager.initializeContracts(
            address(organization),
            address(certificateType),
            address(certificate),
            address(organizationManager),
            address(typeManager)
        );

        // Grant necessary permissions
        vm.startPrank(admin);
        organization.grantRole(organization.ADMIN_ROLE(), address(certificationManager));
        organization.grantRole(organization.ADMIN_ROLE(), address(organizationManager));
        certificateType.grantRole(certificateType.ADMIN_ROLE(), address(certificationManager));
        certificateType.grantRole(certificateType.ADMIN_ROLE(), address(typeManager));
        certificate.grantRole(certificate.ADMIN_ROLE(), address(certificationManager));
        organizationManager.grantRole(organizationManager.ADMIN_ROLE(), address(certificationManager));
        typeManager.grantRole(typeManager.ADMIN_ROLE(), address(certificationManager));
        vm.stopPrank();

        // Set up test data
        _setupTestData();
    }

    function _setupTestData() internal {
        // Register organization and create certificate type as admin
        vm.startPrank(admin);
        certificationManager.registerOrganization(ORG_ID, orgOwner, "Test University", "US");
        certificationManager.createCertificateType(CERT_TYPE_ID, "Computer Science", "CS", "CS Degree");
        vm.stopPrank();
        
        // Add manager to organization as orgOwner
        vm.prank(orgOwner);
        certificationManager.addManager(ORG_ID, orgManager);
        
        // Add the CertificationManager contract as a manager so it can act on behalf of the organization
        vm.prank(orgOwner);
        certificationManager.addManager(ORG_ID, address(certificationManager));
    }

    // Test initialization
    function testInitializeContracts() public {
        CertificationManager newManager = new CertificationManager(admin);
        
        vm.prank(admin);
        newManager.initializeContracts(
            address(organization),
            address(certificateType),
            address(certificate),
            address(organizationManager),
            address(typeManager)
        );

        assertEq(newManager.organizationContract(), address(organization));
        assertEq(newManager.certificateTypeContract(), address(certificateType));
        assertEq(newManager.certificateContract(), address(certificate));
        assertEq(newManager.organizationManager(), address(organizationManager));
        assertEq(newManager.certificationTypeManager(), address(typeManager));
    }

    function testInitializeContractsFailsWithoutAdminRole() public {
        CertificationManager newManager = new CertificationManager(admin);

        vm.prank(nonAuthorized);
        vm.expectRevert();
        newManager.initializeContracts(
            address(organization),
            address(certificateType),
            address(certificate),
            address(organizationManager),
            address(typeManager)
        );
    }

    function testInitializeContractsFailsWithZeroAddress() public {
        CertificationManager newManager = new CertificationManager(admin);

        vm.prank(admin);
        vm.expectRevert("Invalid organization contract address");
        newManager.initializeContracts(
            address(0), // Zero address
            address(certificateType),
            address(certificate),
            address(organizationManager),
            address(typeManager)
        );
    }

    // Test organization management through CertificationManager
    function testRegisterOrganization() public {
        string memory newOrgId = "2";
        address newOwner = makeAddr("newOwner");

        vm.prank(admin);
        string memory returnedId = certificationManager.registerOrganization(newOrgId, newOwner, "MIT", "US");
        assertEq(returnedId, newOrgId);

        Organization.OrganizationData memory org = certificationManager.getOrganization(newOrgId);
        assertEq(org.id, newOrgId);
        assertEq(org.owner, newOwner);
        assertEq(org.name, "MIT");
        assertEq(org.countryCode, "US");
    }

    function testRegisterOrganizationFailsWithoutAdminRole() public {
        vm.prank(nonAuthorized);
        vm.expectRevert();
        certificationManager.registerOrganization("2", orgOwner, "MIT", "US");
    }

    function testUpdateOrganizationByAdmin() public {
        vm.prank(admin);
        certificationManager.updateOrganization(ORG_ID, "Updated University", "CA");

        Organization.OrganizationData memory org = certificationManager.getOrganization(ORG_ID);
        assertEq(org.name, "Updated University");
        assertEq(org.countryCode, "CA");
    }

    function testUpdateOrganizationByOwner() public {
        vm.prank(orgOwner);
        certificationManager.updateOrganization(ORG_ID, "Owner Updated University", "UK");

        Organization.OrganizationData memory org = certificationManager.getOrganization(ORG_ID);
        assertEq(org.name, "Owner Updated University");
        assertEq(org.countryCode, "UK");
    }

    function testUpdateOrganizationFailsWithUnauthorized() public {
        vm.prank(nonAuthorized);
        vm.expectRevert("Not authorized to update organization");
        certificationManager.updateOrganization(ORG_ID, "Unauthorized Update", "XX");
    }

    function testDeactivateOrganization() public {
        vm.prank(admin);
        certificationManager.deactivateOrganization(ORG_ID);
        assertFalse(organization.isOrganizationActive(ORG_ID));
    }

    function testAddAndRemoveManager() public {
        address newManager = makeAddr("newManager");

        vm.prank(orgOwner);
        certificationManager.addManager(ORG_ID, newManager);
        assertTrue(certificationManager.isOrganizationManager(ORG_ID, newManager));

        vm.prank(orgOwner);
        certificationManager.removeManager(ORG_ID, newManager);
        assertFalse(certificationManager.isOrganizationManager(ORG_ID, newManager));
    }

    // Test certificate type management
    function testCreateCertificateType() public {
        string memory newTypeId = "2";
        string memory name = "IT Certificate";
        string memory code = "IT";
        string memory description = "Information Technology Certificate";

        vm.prank(admin);
        string memory returnedId = certificationManager.createCertificateType(newTypeId, name, code, description);
        assertEq(returnedId, newTypeId);

        CertificateType.CertificateTypeData memory certType = certificationManager.getCertificateType(newTypeId);
        assertEq(certType.id, newTypeId);
        assertEq(certType.name, name);
        assertEq(certType.code, code);
        assertEq(certType.description, description);
    }

    function testCreateCertificateTypeFailsWithoutAdminRole() public {
        vm.prank(nonAuthorized);
        vm.expectRevert();
        certificationManager.createCertificateType("2", "IT Certificate", "IT", "IT Cert");
    }

    function testUpdateCertificateType() public {
        vm.prank(admin);
        certificationManager.updateCertificateType(CERT_TYPE_ID, "Updated CS", "CS_UPDATED", "Updated Description");

        CertificateType.CertificateTypeData memory certType = certificationManager.getCertificateType(CERT_TYPE_ID);
        assertEq(certType.name, "Updated CS");
        assertEq(certType.code, "CS_UPDATED");
        assertEq(certType.description, "Updated Description");
    }

    // Test certificate management
    function testSubmitCertificate() public {
        uint256 expireTime = block.timestamp + 365 days;

        vm.prank(orgOwner);
        string memory returnedId = certificationManager.submitCertificate(
            CERT_ID, ORG_ID, CERT_TYPE_ID, HOLDER_ID, HOLDER_COUNTRY,
            GRANT_LEVEL, expireTime, IPFS_HASH
        );

        assertEq(returnedId, CERT_ID);

        Certificate.CertificateData memory cert = certificationManager.getCertificate(CERT_ID);
        assertEq(cert.id, CERT_ID);
        assertEq(cert.organizationId, ORG_ID);
        assertEq(cert.certificateTypeId, CERT_TYPE_ID);
        assertEq(uint256(cert.status), uint256(Certificate.CertificateStatus.Pending));
    }

    function testSubmitCertificateByManager() public {
        uint256 expireTime = block.timestamp + 365 days;

        vm.prank(orgManager);
        certificationManager.submitCertificate(
            CERT_ID, ORG_ID, CERT_TYPE_ID, HOLDER_ID, HOLDER_COUNTRY,
            GRANT_LEVEL, expireTime, IPFS_HASH
        );

        Certificate.CertificateData memory cert = certificationManager.getCertificate(CERT_ID);
        assertEq(cert.submittedBy, address(certificationManager));
    }

    function testSubmitCertificateFailsWithUnauthorized() public {
        uint256 expireTime = block.timestamp + 365 days;

        vm.prank(nonAuthorized);
        vm.expectRevert("Only organization owners or managers can submit certificates");
        certificationManager.submitCertificate(
            CERT_ID, ORG_ID, CERT_TYPE_ID, HOLDER_ID, HOLDER_COUNTRY,
            GRANT_LEVEL, expireTime, IPFS_HASH
        );
    }

    function testApproveCertificate() public {
        _submitTestCertificate();

        vm.prank(admin);
        certificationManager.approveCertificate(CERT_ID);

        Certificate.CertificateData memory cert = certificationManager.getCertificate(CERT_ID);
        assertEq(uint256(cert.status), uint256(Certificate.CertificateStatus.Approved));
    }

    function testApproveCertificateFailsWithoutAdminRole() public {
        _submitTestCertificate();

        vm.prank(nonAuthorized);
        vm.expectRevert();
        certificationManager.approveCertificate(CERT_ID);
    }

    function testRejectCertificate() public {
        _submitTestCertificate();

        string memory reason = "Insufficient documentation";
        vm.prank(admin);
        certificationManager.rejectCertificate(CERT_ID, reason);

        Certificate.CertificateData memory cert = certificationManager.getCertificate(CERT_ID);
        assertEq(uint256(cert.status), uint256(Certificate.CertificateStatus.Rejected));
        assertEq(cert.rejectionReason, reason);
    }

    function testRevokeCertificate() public {
        _submitTestCertificate();
        _approveTestCertificate();

        string memory reason = "Fraud discovered";
        vm.prank(orgManager);
        certificationManager.revokeCertificate(CERT_ID, reason);

        Certificate.CertificateData memory cert = certificationManager.getCertificate(CERT_ID);
        assertEq(uint256(cert.status), uint256(Certificate.CertificateStatus.Revoked));
        assertEq(cert.revocationReason, reason);
    }

    function testRemovePendingCertificate() public {
        _submitTestCertificate();

        vm.prank(orgOwner);
        certificationManager.removePendingCertificate(CERT_ID);

        assertFalse(certificate.certificateExists(CERT_ID));
    }

    // Test view functions
    function testGetCertificatesByOrganization() public {
        _submitTestCertificate();
        _submitAnotherCertificate();

        string[] memory orgCerts = certificationManager.getCertificatesByOrganization(ORG_ID);
        assertEq(orgCerts.length, 2);
    }

    function testGetCertificatesByHolder() public {
        _submitTestCertificate();

        string[] memory holderCerts = certificationManager.getCertificatesByHolder(HOLDER_ID);
        assertEq(holderCerts.length, 1);
        assertEq(holderCerts[0], CERT_ID);
    }

    function testGetCertificatesByStatus() public {
        _submitTestCertificate();
        _submitAnotherCertificate();
        _approveTestCertificate();

        string[] memory pendingCerts = certificationManager.getCertificatesByStatus(Certificate.CertificateStatus.Pending);
        string[] memory approvedCerts = certificationManager.getCertificatesByStatus(Certificate.CertificateStatus.Approved);

        assertEq(pendingCerts.length, 1);
        assertEq(approvedCerts.length, 1);
    }

    function testIsCertificateValid() public {
        _submitTestCertificate();
        assertFalse(certificationManager.isCertificateValid(CERT_ID));

        _approveTestCertificate();
        assertTrue(certificationManager.isCertificateValid(CERT_ID));
    }

    function testGetActiveCertificateTypes() public view {
        // Note: getActiveCertificateTypes() is deprecated and returns empty array
        // since iteration over string IDs is not feasible
        CertificateType.CertificateTypeData[] memory activeTypes = certificationManager.getActiveCertificateTypes();
        assertEq(activeTypes.length, 0);
    }

    function testGetCounts() public {
        assertEq(certificationManager.getOrganizationCount(), 1);
        assertEq(certificationManager.getCertificateTypeCount(), 1);
        assertEq(certificationManager.getCertificateCount(), 0);

        _submitTestCertificate();
        assertEq(certificationManager.getCertificateCount(), 1);
    }

    // Test batch operations
    function testBulkApproveCertificates() public {
        _submitTestCertificate();
        _submitAnotherCertificate();

        string[] memory certIds = new string[](2);
        certIds[0] = CERT_ID;
        certIds[1] = CERT_ID_2;

        bytes[] memory signatures = new bytes[](2);
        signatures[0] = abi.encodePacked(keccak256(abi.encodePacked("APPROVE", CERT_ID, admin)));
        signatures[1] = abi.encodePacked(keccak256(abi.encodePacked("APPROVE", CERT_ID_2, admin)));

        vm.prank(admin);
        certificationManager.bulkApproveCertificates(certIds);

        Certificate.CertificateData memory cert1 = certificationManager.getCertificate(CERT_ID);
        Certificate.CertificateData memory cert2 = certificationManager.getCertificate(CERT_ID_2);

        assertEq(uint256(cert1.status), uint256(Certificate.CertificateStatus.Approved));
        assertEq(uint256(cert2.status), uint256(Certificate.CertificateStatus.Approved));
    }

    function testBulkApproveCertificatesFailsWithMismatchedArrays() public {
        string[] memory certIds = new string[](1);
        certIds[0] = "999"; // Non-existent certificate

        vm.prank(admin);
        vm.expectRevert("Certificate does not exist");
        certificationManager.bulkApproveCertificates(certIds);
    }

    function testBulkRejectCertificates() public {
        _submitTestCertificate();
        _submitAnotherCertificate();

        string[] memory certIds = new string[](2);
        certIds[0] = CERT_ID;
        certIds[1] = CERT_ID_2;

        string[] memory reasons = new string[](2);
        reasons[0] = "Reason 1";
        reasons[1] = "Reason 2";

        vm.prank(admin);
        certificationManager.bulkRejectCertificates(certIds, reasons);

        Certificate.CertificateData memory cert1 = certificationManager.getCertificate(CERT_ID);
        Certificate.CertificateData memory cert2 = certificationManager.getCertificate(CERT_ID_2);

        assertEq(uint256(cert1.status), uint256(Certificate.CertificateStatus.Rejected));
        assertEq(uint256(cert2.status), uint256(Certificate.CertificateStatus.Rejected));
        assertEq(cert1.rejectionReason, "Reason 1");
        assertEq(cert2.rejectionReason, "Reason 2");
    }

    // Remove the receive ether test as CertificationManager doesn't accept Ether

    // Helper functions
    function _submitTestCertificate() internal {
        uint256 expireTime = block.timestamp + 365 days;

        vm.prank(orgOwner);
        certificationManager.submitCertificate(
            CERT_ID, ORG_ID, CERT_TYPE_ID, HOLDER_ID, HOLDER_COUNTRY,
            GRANT_LEVEL, expireTime, IPFS_HASH
        );
    }

    function _submitAnotherCertificate() internal {
        string memory certId = CERT_ID_2;
        uint256 expireTime = block.timestamp + 365 days;
        vm.prank(orgOwner);
        certificationManager.submitCertificate(
            certId, ORG_ID, CERT_TYPE_ID, "987654321", HOLDER_COUNTRY,
            90, expireTime, "QmY9876543210fedcba"
        );
    }

    function _approveTestCertificate() internal {
        vm.prank(admin);
        certificationManager.approveCertificate(CERT_ID);
    }

    // Test complex workflows
    function testCompleteWorkflow() public {
        // 1. Register additional organization
        string memory org2Id = "2";
        address org2Owner = makeAddr("org2Owner");
        vm.prank(admin);
        certificationManager.registerOrganization(org2Id, org2Owner, "Stanford", "US");

        // 2. Create additional certificate type
        string memory type2Id = "2";
        vm.prank(admin);
        certificationManager.createCertificateType(type2Id, "Mathematics", "MATH", "Mathematics Certificate");
        
        // Add manager to the second organization
        vm.prank(org2Owner);
        certificationManager.addManager(org2Id, address(certificationManager));

        // 3. Submit certificates from different organizations
        _submitTestCertificate(); // From org 1

        string memory cert2Id = CERT_ID_2;
        uint256 expireTime = block.timestamp + 365 days;

        vm.prank(org2Owner);
        certificationManager.submitCertificate(
            cert2Id, org2Id, type2Id, "111222333", "CA", 95, expireTime, "QmABC123"
        );

        // 4. Approve one, reject another
        _approveTestCertificate();
        vm.prank(admin);
        certificationManager.rejectCertificate(cert2Id, "Missing signature");

        // 5. Verify final states
        Certificate.CertificateData memory cert1 = certificationManager.getCertificate(CERT_ID);
        Certificate.CertificateData memory cert2 = certificationManager.getCertificate(cert2Id);

        assertEq(uint256(cert1.status), uint256(Certificate.CertificateStatus.Approved));
        assertEq(uint256(cert2.status), uint256(Certificate.CertificateStatus.Rejected));

        // 6. Check counts
        assertEq(certificationManager.getOrganizationCount(), 2);
        assertEq(certificationManager.getCertificateTypeCount(), 2);
        assertEq(certificationManager.getCertificateCount(), 2);

        // 7. Test queries
        string[] memory org1Certs = certificationManager.getCertificatesByOrganization(ORG_ID);
        string[] memory org2Certs = certificationManager.getCertificatesByOrganization(org2Id);
        assertEq(org1Certs.length, 1);
        assertEq(org2Certs.length, 1);

        string[] memory approvedCerts = certificationManager.getCertificatesByStatus(Certificate.CertificateStatus.Approved);
        string[] memory rejectedCerts = certificationManager.getCertificatesByStatus(Certificate.CertificateStatus.Rejected);
        assertEq(approvedCerts.length, 1);
        assertEq(rejectedCerts.length, 1);
    }

    // Test edge cases and error conditions
    function testOperationsWithoutInitialization() public {
        CertificationManager uninitializedManager = new CertificationManager(admin);

        vm.prank(admin);
        vm.expectRevert("Organization contract not set");
        uninitializedManager.registerOrganization("1", orgOwner, "Test", "US");
    }

    function testAccessControlInheritance() public view {
        // Test that admin can perform all operations
        assertTrue(certificationManager.hasRole(certificationManager.ADMIN_ROLE(), admin));
        assertTrue(certificationManager.hasRole(certificationManager.DEFAULT_ADMIN_ROLE(), admin));

        // Test that non-admin cannot perform admin operations
        assertFalse(certificationManager.hasRole(certificationManager.ADMIN_ROLE(), nonAuthorized));
    }
}