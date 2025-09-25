// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Certificate} from "./contracts/Certificate.sol";
import {OrganizationManager} from "./OrganizationManager.sol";

/**
 * @title CertificationManager
 * @dev Main contract for managing the entire certification system
 */
contract CertificationManager is AccessControl {

    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Contract addresses
    address public organizationContract;
    address public certificateContract;
    address public organizationManager;

    // System state
    bool public paused;

    modifier whenNotPaused() {
        require(!paused, "System is paused");
        _;
    }

    modifier onlyValidContracts() {
        require(organizationContract != address(0) && 
                certificateContract != address(0) && 
                organizationManager != address(0), "Contracts not set");
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
        address _certificateContract,
        address _organizationManager
    ) external onlyRole(ADMIN_ROLE) {
        organizationContract = _organizationContract;
        certificateContract = _certificateContract;
        organizationManager = _organizationManager;
    }

    /**
     * @dev Pause/unpause the system (only admin)
     */
    function setPaused(bool _paused) external onlyRole(ADMIN_ROLE) {
        paused = _paused;
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
        // Simplified access control: only organization owners/managers can submit
        require(
            OrganizationManager(organizationManager).canManageOrganization(_organizationId, msg.sender),
            "Only organization owners or managers can submit certificates"
        );
        
        Certificate(certificateContract).submitCertificate(
            _id, _organizationId, _certificateTypeId, _holderIdCard, 
            _holderCountryCode, _grantLevel, _expireTime, _ipfsHash
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

    // Main certificate view function - keep this as it's core to certification management
    function getCertificate(string memory _certId) 
        external 
        view 
        whenNotPaused 
        onlyValidContracts 
        returns (Certificate.CertificateData memory) 
    {
        return Certificate(certificateContract).getCertificate(_certId);
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
