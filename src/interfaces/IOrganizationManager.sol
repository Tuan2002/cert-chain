// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IOrganizationManager {
    // Events
    event OrganizationContractUpdated(address indexed oldContract, address indexed newContract);
    
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
    
    function transferOrganizationOwnership(string memory orgId, address newOwner) external;
    
    // Organization management functions
    function addOrganizationManager(string memory orgId, address manager) external;
    function removeOrganizationManager(string memory orgId, address manager) external;
    
    // View functions
    function getOrganization(string memory orgId) external view returns (OrganizationData memory);
    function isOrganizationOwner(string memory orgId, address account) external view returns (bool);
    function isOrganizationManager(string memory orgId, address account) external view returns (bool);
    function canManageOrganization(string memory orgId, address account) external view returns (bool);
    function getOrganizationCount() external view returns (uint256);
    function getOwnerOrganizations(address owner) external view returns (string[] memory);
    function getManagerOrganizations(address manager) external view returns (string[] memory);
    function organizationExists(string memory orgId) external view returns (bool);
    function isOrganizationActive(string memory orgId) external view returns (bool);
    
    // Batch operations
    function getOrganizations(string[] memory orgIds) external view returns (OrganizationData[] memory);
    function organizationsExist(string[] memory orgIds) external view returns (bool[] memory);
    
    // Admin contract management
    function updateOrganizationContract(address newContract) external;
    
    // Contract state
    function organizationContract() external view returns (address);
    
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
}
