// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {Organization} from "./contracts/Organization.sol";
import {CertificateType} from "./contracts/CertificateType.sol";
import {Certificate} from "./contracts/Certificate.sol";
import {OrganizationManager} from "./OrganizationManager.sol";
import {CertificationTypeManager} from "./CertificationTypeManager.sol";

/**
 * @title CertificationManager
 * @dev Main contract for managing the entire certification system
 */
contract CertificationManager is AccessControl {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Contract addresses
    address public organizationContract;
    address public certificateTypeContract;
    address public certificateContract;
    address public organizationManager;
    address public certificationTypeManager;

    // System state
    bool public paused;

    modifier whenNotPaused() {
        require(!paused, "System is paused");
        _;
    }

    modifier onlyValidContracts() {
        require(organizationContract != address(0), "Organization contract not set");
        require(certificateTypeContract != address(0), "Certificate type contract not set");
        require(certificateContract != address(0), "Certificate contract not set");
        require(organizationManager != address(0), "Organization manager not set");
        require(certificationTypeManager != address(0), "Certification type manager not set");
        _;
    }

    constructor(address _admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
    }

    /**
     * @dev Initialize the system with contract addresses (only admin)
     */
    function initializeContracts(
        address _organizationContract,
        address _certificateTypeContract,
        address _certificateContract,
        address _organizationManager,
        address _certificationTypeManager
    ) external onlyRole(ADMIN_ROLE) {
        require(_organizationContract != address(0), "Invalid organization contract address");
        require(_certificateTypeContract != address(0), "Invalid certificate type contract address");
        require(_certificateContract != address(0), "Invalid certificate contract address");
        require(_organizationManager != address(0), "Invalid organization manager address");
        require(_certificationTypeManager != address(0), "Invalid certification type manager address");

        organizationContract = _organizationContract;
        certificateTypeContract = _certificateTypeContract;
        certificateContract = _certificateContract;
        organizationManager = _organizationManager;
        certificationTypeManager = _certificationTypeManager;
    }

    // Organization Management Functions (delegated to OrganizationManager)
    function registerOrganization(
        string memory _id,
        address _owner,
        string memory _name,
        string memory _countryCode
    ) external onlyRole(ADMIN_ROLE) whenNotPaused onlyValidContracts returns (string memory) {
        return OrganizationManager(organizationManager).registerOrganization(_id, _owner, _name, _countryCode);
    }

    function updateOrganization(
        string memory _orgId,
        string memory _name,
        string memory _countryCode
    ) external whenNotPaused onlyValidContracts {
        // Allow both admin and organization owner to update
        require(
            hasRole(ADMIN_ROLE, msg.sender) || 
            OrganizationManager(organizationManager).isOrganizationOwner(_orgId, msg.sender),
            "Not authorized to update organization"
        );

        if (hasRole(ADMIN_ROLE, msg.sender)) {
            OrganizationManager(organizationManager).updateOrganization(_orgId, _name, _countryCode);
        } else {
            // For organization owners, call directly on organization contract
            Organization(organizationContract).updateOrganization(_orgId, _name, _countryCode);
        }
    }

    function deactivateOrganization(string memory _orgId) 
        external 
        onlyRole(ADMIN_ROLE) 
        whenNotPaused 
        onlyValidContracts 
    {
        OrganizationManager(organizationManager).deactivateOrganization(_orgId);
    }

    function addManager(string memory _orgId, address _manager) 
        external 
        whenNotPaused 
        onlyValidContracts 
    {
        OrganizationManager(organizationManager).addOrganizationManager(_orgId, _manager);
    }

    function removeManager(string memory _orgId, address _manager) 
        external 
        whenNotPaused 
        onlyValidContracts 
    {
        OrganizationManager(organizationManager).removeOrganizationManager(_orgId, _manager);
    }

    // Certificate Type Management Functions (delegated to CertificationTypeManager)
    function createCertificateType(
        string memory _id,
        string memory _name,
        string memory _code,
        string memory _description
    ) external onlyRole(ADMIN_ROLE) whenNotPaused onlyValidContracts returns (string memory) {
        return CertificationTypeManager(certificationTypeManager).createCertificateType(_id, _name, _code, _description);
    }

    function updateCertificateType(
        string memory _typeId,
        string memory _name,
        string memory _code,
        string memory _description
    ) external onlyRole(ADMIN_ROLE) whenNotPaused onlyValidContracts {
        CertificationTypeManager(certificationTypeManager).updateCertificateType(_typeId, _name, _code, _description);
    }

    // Certificate Management Functions (with enhanced access control)
    function submitCertificate(
        string memory _id,
        string memory _organizationId,
        string memory _certificateTypeId,
        string memory _holderIdCard,
        string memory _holderCountryCode,
        uint256 _grantLevel,
        uint256 _expireTime,
        string memory _ipfsHash
    ) external whenNotPaused onlyValidContracts returns (string memory) {
        // Enhanced access control: only organization owners/managers can submit
        require(
            OrganizationManager(organizationManager).canManageOrganization(_organizationId, msg.sender),
            "Only organization owners or managers can submit certificates"
        );
        
        Certificate(certificateContract).submitCertificate(
            _id,
            _organizationId,
            _certificateTypeId,
            _holderIdCard,
            _holderCountryCode,
            _grantLevel,
            _expireTime,
            _ipfsHash
        );
        
        return _id;
    }

    function approveCertificate(string memory _certId) 
        external 
        onlyRole(ADMIN_ROLE) 
        whenNotPaused 
        onlyValidContracts 
    {
        Certificate(certificateContract).approveCertificate(_certId);
    }

    function rejectCertificate(string memory _certId, string memory _reason) 
        external 
        onlyRole(ADMIN_ROLE) 
        whenNotPaused 
        onlyValidContracts 
    {
        Certificate(certificateContract).rejectCertificate(_certId, _reason);
    }

    function revokeCertificate(string memory _certId, string memory _reason) 
        external 
        whenNotPaused 
        onlyValidContracts 
    {
        Certificate(certificateContract).revokeCertificate(_certId, _reason);
    }

    function removePendingCertificate(string memory _certId) 
        external 
        whenNotPaused 
        onlyValidContracts 
    {
        Certificate(certificateContract).removePendingCertificate(_certId);
    }

    // View Functions (implementing ICertificationManager interface)
    function getOrganization(string memory _orgId) 
        external 
        view 
        whenNotPaused 
        onlyValidContracts 
        returns (Organization.OrganizationData memory) 
    {
        return Organization(organizationContract).getOrganization(_orgId);
    }

    function getCertificateType(string memory _typeId) 
        external 
        view 
        whenNotPaused 
        onlyValidContracts 
        returns (CertificateType.CertificateTypeData memory) 
    {
        return CertificateType(certificateTypeContract).getCertificateType(_typeId);
    }

    function getCertificate(string memory _certId) 
        external 
        view 
        whenNotPaused 
        onlyValidContracts 
        returns (Certificate.CertificateData memory) 
    {
        return Certificate(certificateContract).getCertificate(_certId);
    }

    function isOrganizationOwner(string memory _orgId, address _account) 
        external 
        view 
        whenNotPaused 
        onlyValidContracts 
        returns (bool) 
    {
        return Organization(organizationContract).isOrganizationOwner(_orgId, _account);
    }

    function isOrganizationManager(string memory _orgId, address _account) 
        external 
        view 
        whenNotPaused 
        onlyValidContracts 
        returns (bool) 
    {
        return Organization(organizationContract).isOrganizationManager(_orgId, _account);
    }

    function canManageOrganization(string memory _orgId, address _account) 
        external 
        view 
        whenNotPaused 
        onlyValidContracts 
        returns (bool) 
    {
        return Organization(organizationContract).canManageOrganization(_orgId, _account);
    }

    function getOrganizationCount() 
        external 
        view 
        onlyValidContracts 
        returns (uint256) 
    {
        return Organization(organizationContract).getOrganizationCount();
    }

    function getCertificateTypeCount() 
        external 
        view 
        onlyValidContracts 
        returns (uint256) 
    {
        return CertificateType(certificateTypeContract).getCertificateTypeCount();
    }

    function getCertificateCount() 
        external 
        view 
        onlyValidContracts 
        returns (uint256) 
    {
        return Certificate(certificateContract).getCertificateCount();
    }

    // Additional utility functions
    function getCertificatesByOrganization(string memory _orgId) 
        external 
        view 
        whenNotPaused 
        onlyValidContracts 
        returns (string[] memory) 
    {
        return Certificate(certificateContract).getCertificatesByOrganization(_orgId);
    }

    function getCertificatesByHolder(string memory _holderIdCard) 
        external 
        view 
        whenNotPaused 
        onlyValidContracts 
        returns (string[] memory) 
    {
        return Certificate(certificateContract).getCertificatesByHolder(_holderIdCard);
    }

    function getCertificatesByStatus(Certificate.CertificateStatus _status) 
        external 
        view 
        whenNotPaused 
        onlyValidContracts 
        returns (string[] memory) 
    {
        return Certificate(certificateContract).getCertificatesByStatus(_status);
    }

    function isCertificateValid(string memory _certId) 
        external 
        view 
        whenNotPaused 
        onlyValidContracts 
        returns (bool) 
    {
        return Certificate(certificateContract).isCertificateValid(_certId);
    }

    function getActiveCertificateTypes() 
        external 
        view 
        onlyValidContracts 
        returns (CertificateType.CertificateTypeData[] memory) 
    {
        return CertificateType(certificateTypeContract).getActiveCertificateTypes();
    }

    // Batch operations for efficiency
    function bulkApproveCertificates(string[] memory _certIds) 
        external 
        onlyRole(ADMIN_ROLE) 
        whenNotPaused 
        onlyValidContracts 
    {
        for (uint256 i = 0; i < _certIds.length; i++) {
            Certificate(certificateContract).approveCertificate(_certIds[i]);
        }
    }

    function bulkRejectCertificates(string[] memory _certIds, string[] memory _reasons) 
        external 
        onlyRole(ADMIN_ROLE) 
        whenNotPaused 
        onlyValidContracts 
    {
        require(_certIds.length == _reasons.length, "Array length mismatch");
        
        for (uint256 i = 0; i < _certIds.length; i++) {
            Certificate(certificateContract).rejectCertificate(_certIds[i], _reasons[i]);
        }
    }
}
