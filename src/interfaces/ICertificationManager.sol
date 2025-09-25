// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICertificationManager {
    // Events
    event OrganizationRegistered(string indexed orgId, address indexed owner, string name);
    event OrganizationUpdated(string indexed orgId, string name);
    event ManagerAdded(string indexed orgId, address indexed manager);
    event ManagerRemoved(string indexed orgId, address indexed manager);
    
    event CertificateTypeCreated(string indexed typeId, string name);
    event CertificateTypeUpdated(string indexed typeId, string name);
    
    event CertificateSubmitted(string indexed certId, string indexed orgId, address indexed holder);
    event CertificateApproved(string indexed certId, address indexed approver);
    event CertificateRejected(string indexed certId, address indexed rejector, string reason);
    event CertificateRevoked(string indexed certId, address indexed revoker, string reason);
    
    // System events
    event SystemPaused(address indexed admin);
    event SystemUnpaused(address indexed admin);
    event ContractUpdated(string indexed contractName, address indexed oldContract, address indexed newContract);
    
    // Structs
    struct OrganizationData {
        string id;
        address owner;
        string name;
        string countryCode;
        address[] managers;
        bool isActive;
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    struct CertificateTypeData {
        string id;
        string name;
        string code;
        string description;
        bool isActive;
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    enum CertificateStatus {
        Pending,
        Approved,
        Rejected,
        Revoked
    }
    
    struct CertificateData {
        string id;
        string organizationId;
        string certificateTypeId;
        CertificateStatus status;
        string holderIdCard;
        string holderCountryCode;
        uint256 grantLevel;
        uint256 issueTime;
        uint256 expireTime;
        string ipfsHash;
        string rejectionReason;
        string revocationReason;
        address submittedBy;
        address approvedBy;
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    // Admin functions
    function registerOrganization(
        string memory id,
        address owner,
        string memory name,
        string memory countryCode
    ) external returns (string memory);
    
    function updateOrganization(
        string memory orgId,
        string memory name,
        string memory countryCode
    ) external;
    
    function deactivateOrganization(string memory orgId) external;
    
    function createCertificateType(
        string memory id,
        string memory name,
        string memory code,
        string memory description
    ) external returns (string memory);
    
    function updateCertificateType(
        string memory typeId,
        string memory name,
        string memory code,
        string memory description
    ) external;
    
    function approveCertificate(string memory certId, bytes memory signature) external;
    function rejectCertificate(string memory certId, string memory reason) external;
    function revokeCertificate(string memory certId, string memory reason) external;
    
    // Organization functions
    function addManager(string memory orgId, address manager) external;
    function removeManager(string memory orgId, address manager) external;
    
    function submitCertificate(
        string memory id,
        string memory organizationId,
        string memory certificateTypeId,
        string memory holderIdCard,
        string memory holderCountryCode,
        uint256 grantLevel,
        uint256 expireTime,
        string memory ipfsHash,
        bytes memory signature
    ) external returns (string memory);
    
    function removePendingCertificate(string memory certId) external;
    
    // View functions
    function getOrganization(string memory orgId) external view returns (OrganizationData memory);
    function getCertificateType(string memory typeId) external view returns (CertificateTypeData memory);
    function getCertificate(string memory certId) external view returns (CertificateData memory);
    
    function isOrganizationOwner(string memory orgId, address account) external view returns (bool);
    function isOrganizationManager(string memory orgId, address account) external view returns (bool);
    function canManageOrganization(string memory orgId, address account) external view returns (bool);
    
    function getOrganizationCount() external view returns (uint256);
    function getCertificateTypeCount() external view returns (uint256);
    function getCertificateCount() external view returns (uint256);
    
    // Additional view functions
    function getCertificatesByOrganization(string memory orgId) external view returns (string[] memory);
    function getCertificatesByHolder(string memory holderIdCard) external view returns (string[] memory);
    function getCertificatesByStatus(CertificateStatus status) external view returns (string[] memory);
    function isCertificateValid(string memory certId) external view returns (bool);
    function getActiveCertificateTypes() external view returns (CertificateTypeData[] memory);
    
    // System management
    function pauseSystem() external;
    function unpauseSystem() external;
    function paused() external view returns (bool);
}