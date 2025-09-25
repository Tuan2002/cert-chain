// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICertificationTypeManager {
    // Events
    event CertificateTypeContractUpdated(address indexed oldContract, address indexed newContract);
    
    // Admin functions
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
    
    function deactivateCertificateType(string memory typeId) external;
    function reactivateCertificateType(string memory typeId) external;
    
    // View functions
    function getCertificateType(string memory typeId) external view returns (CertificateTypeData memory);
    function getCertificateTypeByCode(string memory code) external view returns (CertificateTypeData memory);
    function certificateTypeExists(string memory typeId) external view returns (bool);
    function isCertificateTypeActive(string memory typeId) external view returns (bool);
    function codeExists(string memory code) external view returns (bool);
    function getIdByCode(string memory code) external view returns (string memory);
    function getCertificateTypeCount() external view returns (uint256);
    function getActiveCertificateTypes() external view returns (CertificateTypeData[] memory);
    function getAllCertificateTypes() external view returns (CertificateTypeData[] memory);
    
    // Batch operations
    function getCertificateTypes(string[] memory typeIds) external view returns (CertificateTypeData[] memory);
    function certificateTypesExist(string[] memory typeIds) external view returns (bool[] memory);
    function getCertificateTypesByCodes(string[] memory codes) external view returns (CertificateTypeData[] memory);
    function codesExist(string[] memory codes) external view returns (bool[] memory);
    
    function bulkCreateCertificateTypes(
        string[] memory ids,
        string[] memory names,
        string[] memory codes,
        string[] memory descriptions
    ) external;
    
    function bulkDeactivateCertificateTypes(string[] memory typeIds) external;
    
    // Admin contract management
    function updateCertificateTypeContract(address newContract) external;
    
    // Contract state
    function certificateTypeContract() external view returns (address);
    
    struct CertificateTypeData {
        string id;
        string name;
        string code;
        string description;
        bool isActive;
        uint256 createdAt;
        uint256 updatedAt;
    }
}
