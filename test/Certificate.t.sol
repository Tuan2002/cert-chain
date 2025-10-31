// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Certificate} from "../src/contracts/Certificate.sol";
import {Organization} from "../src/contracts/Organization.sol";
import {CertificateType} from "../src/contracts/CertificateType.sol";

contract CertificateTest is Test {
    Certificate public certificate;
    Organization public organization;
    CertificateType public certificateType;
    
    address public admin;
    address public orgOwner;
    address public orgManager;
    address public nonAuthorized;

    // Test data
    string public constant ORG_ID = "1";
    string public constant CERT_TYPE_ID = "1";
    string public constant CERT_ID = "1";
    string public constant HOLDER_ID = "123456789";
    string public constant HOLDER_COUNTRY = "US";
    uint256 public constant GRANT_LEVEL = 85;
    string public constant IPFS_HASH = "QmX1234567890abcdef";

    // Events to test
    event CertificateSubmitted(
        string id,
        string organizationId,
        string certificateTypeId,
        address submittedBy,
        string holderIdCard
    );
    event CertificateApproved(string id, address approvedBy);
    event CertificateRejected(string id, address rejectedBy, string reason);
    event CertificateRevoked(string id, address revokedBy, string reason);
    event CertificateRemoved(string id, address removedBy);

    function setUp() public {
        // Use vm.addr to get addresses from private keys for proper signature testing
        admin = vm.addr(0x3); // Address corresponding to private key 0x3
        orgOwner = vm.addr(0x1); // Address corresponding to private key 0x1
        orgManager = vm.addr(0x2); // Address corresponding to private key 0x2
        nonAuthorized = makeAddr("nonAuthorized");

        // Deploy contracts as admin
        vm.startPrank(admin);
        organization = new Organization(admin);
        certificateType = new CertificateType(admin);
        certificate = new Certificate(admin, address(organization), address(certificateType));
        vm.stopPrank();

        // Set up test organization
        vm.prank(admin);
        organization.createOrganization(ORG_ID, orgOwner, "Test University", "US");
        
        // Add manager to organization
        vm.prank(orgOwner);
        organization.addManager(ORG_ID, orgManager);

        // Set up test certificate type
        vm.prank(admin);
        certificateType.createCertificateType(CERT_TYPE_ID, "Computer Science", "CS", "CS Degree");
    }

    // Test certificate submission
    function testSubmitCertificate() public {
        uint256 expireTime = block.timestamp + 365 days;

        vm.expectEmit(true, true, true, true);
        emit CertificateSubmitted(CERT_ID, ORG_ID, CERT_TYPE_ID, orgOwner, HOLDER_ID);

        vm.prank(orgOwner);
        certificate.submitCertificate(
            CERT_ID,
            ORG_ID,
            CERT_TYPE_ID,
            HOLDER_ID,
            HOLDER_COUNTRY,
            GRANT_LEVEL,
            expireTime,
            IPFS_HASH
        );

        Certificate.CertificateData memory cert = certificate.getCertificate(CERT_ID);
        assertEq(cert.id, CERT_ID);
        assertEq(cert.organizationId, ORG_ID);
        assertEq(cert.certificateTypeId, CERT_TYPE_ID);
        assertEq(uint256(cert.status), uint256(Certificate.CertificateStatus.Pending));
        assertEq(cert.holderIdCard, HOLDER_ID);
        assertEq(cert.holderCountryCode, HOLDER_COUNTRY);
        assertEq(cert.grantLevel, GRANT_LEVEL);
        assertEq(cert.expireTime, expireTime);
        assertEq(cert.ipfsHash, IPFS_HASH);
        assertEq(cert.submittedBy, orgOwner);
    }

    function testSubmitCertificateByManager() public {
        uint256 expireTime = block.timestamp + 365 days;

        vm.prank(orgManager);
        certificate.submitCertificate(
            CERT_ID,
            ORG_ID,
            CERT_TYPE_ID,
            HOLDER_ID,
            HOLDER_COUNTRY,
            GRANT_LEVEL,
            expireTime,
            IPFS_HASH
        );

        Certificate.CertificateData memory cert = certificate.getCertificate(CERT_ID);
        assertEq(cert.submittedBy, orgManager);
    }

    function testSubmitCertificateFailsWithInvalidId() public {
        uint256 expireTime = block.timestamp + 365 days;

        vm.prank(orgOwner);
        vm.expectRevert("Certificate ID cannot be empty");
        certificate.submitCertificate(
            "", ORG_ID, CERT_TYPE_ID, HOLDER_ID, HOLDER_COUNTRY,
            GRANT_LEVEL, expireTime, IPFS_HASH
        );
    }

    function testSubmitCertificateFailsWithDuplicateId() public {
        uint256 expireTime = block.timestamp + 365 days;

        vm.prank(orgOwner);
        certificate.submitCertificate(
            CERT_ID, ORG_ID, CERT_TYPE_ID, HOLDER_ID, HOLDER_COUNTRY,
            GRANT_LEVEL, expireTime, IPFS_HASH
        );

        vm.prank(orgOwner);
        vm.expectRevert("Certificate with this ID already exists");
        certificate.submitCertificate(
            CERT_ID, ORG_ID, CERT_TYPE_ID, HOLDER_ID, HOLDER_COUNTRY,
            GRANT_LEVEL, expireTime, IPFS_HASH
        );
    }

    function testSubmitCertificateFailsWithExpiredTime() public {
        // Set a specific timestamp to avoid underflow
        vm.warp(365 days); // Set block.timestamp to a year from epoch
        uint256 expiredTime = block.timestamp - 1 days;

        vm.prank(orgOwner);
        vm.expectRevert("Expiration time must be in the future");
        certificate.submitCertificate(
            CERT_ID, ORG_ID, CERT_TYPE_ID, HOLDER_ID, HOLDER_COUNTRY,
            GRANT_LEVEL, expiredTime, IPFS_HASH
        );
    }

    function testSubmitCertificateFailsWithUnauthorized() public {
        uint256 expireTime = block.timestamp + 365 days;

        vm.prank(nonAuthorized);
        vm.expectRevert("Not authorized for this organization");
        certificate.submitCertificate(
            CERT_ID, ORG_ID, CERT_TYPE_ID, HOLDER_ID, HOLDER_COUNTRY,
            GRANT_LEVEL, expireTime, IPFS_HASH
        );
    }

    function testSubmitCertificateFailsWithInactiveOrganization() public {
        vm.prank(admin);
        organization.deactivateOrganization(ORG_ID);
        uint256 expireTime = block.timestamp + 365 days;

        vm.prank(orgOwner);
        vm.expectRevert("Invalid or inactive organization");
        certificate.submitCertificate(
            CERT_ID, ORG_ID, CERT_TYPE_ID, HOLDER_ID, HOLDER_COUNTRY,
            GRANT_LEVEL, expireTime, IPFS_HASH
        );
    }

    function testSubmitCertificateFailsWithInactiveCertificateType() public {
        vm.prank(admin);
        certificateType.deactivateCertificateType(CERT_TYPE_ID);

        uint256 expireTime = block.timestamp + 365 days;

        vm.prank(orgOwner);
        vm.expectRevert("Invalid or inactive certificate type");
        certificate.submitCertificate(
            CERT_ID, ORG_ID, CERT_TYPE_ID, HOLDER_ID, HOLDER_COUNTRY,
            GRANT_LEVEL, expireTime, IPFS_HASH
        );
    }

    // Test certificate approval
    function testApproveCertificate() public {
        _submitTestCertificate();

        vm.expectEmit(true, true, false, false);
        emit CertificateApproved(CERT_ID, admin);

        vm.prank(admin);
        certificate.approveCertificate(CERT_ID);

        Certificate.CertificateData memory cert = certificate.getCertificate(CERT_ID);
        assertEq(uint256(cert.status), uint256(Certificate.CertificateStatus.Approved));
        assertGt(cert.issueTime, 0);
    }

    function testApproveCertificateFailsWithNonPendingStatus() public {
        _submitTestCertificate();
        _approveTestCertificate();

        vm.expectRevert("Certificate is not pending");
        vm.prank(admin);
        certificate.approveCertificate(CERT_ID);
    }

    function testApproveCertificateFailsWithoutAdminRole() public {
        _submitTestCertificate();

        vm.prank(nonAuthorized);
        vm.expectRevert();
        certificate.approveCertificate(CERT_ID);
    }

    // Test certificate rejection
    function testRejectCertificate() public {
        _submitTestCertificate();

        string memory reason = "Insufficient documentation";

        vm.expectEmit(true, true, false, true);
        emit CertificateRejected(CERT_ID, admin, reason);

        vm.prank(admin);
        certificate.rejectCertificate(CERT_ID, reason);

        Certificate.CertificateData memory cert = certificate.getCertificate(CERT_ID);
        assertEq(uint256(cert.status), uint256(Certificate.CertificateStatus.Rejected));
        assertEq(cert.rejectionReason, reason);
    }

    function testRejectCertificateFailsWithEmptyReason() public {
        _submitTestCertificate();

        vm.expectRevert("Rejection reason cannot be empty");
        vm.prank(admin);
        certificate.rejectCertificate(CERT_ID, "");
    }

    function testRejectCertificateFailsWithNonPendingStatus() public {
        _submitTestCertificate();
        _approveTestCertificate();

        vm.expectRevert("Certificate is not pending");
        vm.prank(admin);
        certificate.rejectCertificate(CERT_ID, "Some reason");
    }

    // Test certificate revocation
    function testRevokeCertificate() public {
        _submitTestCertificate();
        _approveTestCertificate();

        string memory reason = "Fraudulent information discovered";

        vm.expectEmit(true, true, false, true);
        emit CertificateRevoked(CERT_ID, admin, reason);

        vm.prank(admin);
        certificate.revokeCertificate(CERT_ID, reason);

        Certificate.CertificateData memory cert = certificate.getCertificate(CERT_ID);
        assertEq(uint256(cert.status), uint256(Certificate.CertificateStatus.Revoked));
        assertEq(cert.revocationReason, reason);
    }

    function testRevokeCertificateFailsWithNonApprovedStatus() public {
        _submitTestCertificate();

        vm.expectRevert("Certificate is not approved");
        vm.prank(admin);
        certificate.revokeCertificate(CERT_ID, "Some reason");
    }

    function testRevokeCertificateFailsWithEmptyReason() public {
        _submitTestCertificate();
        _approveTestCertificate();

        vm.expectRevert("Revocation reason cannot be empty");
        vm.prank(admin);
        certificate.revokeCertificate(CERT_ID, "");
    }

    // Test view functions
    function testGetCertificatesByOrganization() public {
        _submitTestCertificate();
        _submitAnotherCertificate();

        string[] memory orgCerts = certificate.getCertificatesByOrganization(ORG_ID);
        assertEq(orgCerts.length, 2);
        assertTrue(_stringArrayContains(orgCerts, CERT_ID));
        assertTrue(_stringArrayContains(orgCerts, "2"));
    }

    function testGetCertificatesByHolder() public {
        _submitTestCertificate();

        string[] memory holderCerts = certificate.getCertificatesByHolder(HOLDER_ID);
        assertEq(holderCerts.length, 1);
        assertEq(holderCerts[0], CERT_ID);
    }

    function testGetCertificatesByStatus() public {
        _submitTestCertificate();
        _submitAnotherCertificate();
        _approveTestCertificate();

        string[] memory pendingCerts = certificate.getCertificatesByStatus(Certificate.CertificateStatus.Pending);
        string[] memory approvedCerts = certificate.getCertificatesByStatus(Certificate.CertificateStatus.Approved);

        assertEq(pendingCerts.length, 1);
        assertEq(approvedCerts.length, 1);
        assertEq(pendingCerts[0], "2");
        assertEq(approvedCerts[0], CERT_ID);
    }

    function testIsCertificateValid() public {
        _submitTestCertificate();
        assertFalse(certificate.isCertificateValid(CERT_ID)); // Not approved yet

        _approveTestCertificate();
        assertTrue(certificate.isCertificateValid(CERT_ID)); // Approved and not expired

        // Test with expired certificate
        vm.warp(block.timestamp + 400 days); // Beyond expiration
        assertFalse(certificate.isCertificateValid(CERT_ID)); // Expired
    }

    function testCertificateExists() public {
        assertFalse(certificate.certificateExists(CERT_ID));

        _submitTestCertificate();
        assertTrue(certificate.certificateExists(CERT_ID));
    }

    function testGetCertificateCount() public {
        assertEq(certificate.getCertificateCount(), 0);

        _submitTestCertificate();
        assertEq(certificate.getCertificateCount(), 1);

        _submitAnotherCertificate();
        assertEq(certificate.getCertificateCount(), 2);
    }

    // Helper functions
    function _submitTestCertificate() internal {
        uint256 expireTime = block.timestamp + 365 days;

        vm.prank(orgOwner);
        certificate.submitCertificate(
            CERT_ID, ORG_ID, CERT_TYPE_ID, HOLDER_ID, HOLDER_COUNTRY,
            GRANT_LEVEL, expireTime, IPFS_HASH
        );
    }

    function _submitAnotherCertificate() internal {
        string memory certId = "2";
        uint256 expireTime = block.timestamp + 365 days;

        vm.prank(orgOwner);
        certificate.submitCertificate(
            certId, ORG_ID, CERT_TYPE_ID, "987654321", HOLDER_COUNTRY,
            90, expireTime, "QmY9876543210fedcba"
        );
    }

    function _approveTestCertificate() internal {
        vm.prank(admin);
        certificate.approveCertificate(CERT_ID);
    }

    function _arrayContains(uint256[] memory array, uint256 value) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    function _stringArrayContains(string[] memory array, string memory value) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (keccak256(bytes(array[i])) == keccak256(bytes(value))) {
                return true;
            }
        }
        return false;
    }

    // Test edge cases
    function testGetNonExistentCertificate() public {
        vm.expectRevert("Certificate does not exist");
        certificate.getCertificate("999");
    }

}