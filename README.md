# Digital Certificate Management System

A comprehensive blockchain-based system for managing digital education certificates on Ethereum. This system allows organizations to issue, manage, and verify educational certificates with proper access control and decentralized storage.

## 🏗️ System Architecture

The system consists of 6 main components:

### Core Entity Contracts
1. **Organization** - Manages educational institutions and their details
2. **CertificateType** - Defines types of certificates (e.g., IT Certificate, English Certificate)
3. **Certificate** - Represents individual certificates with holder information

### Manager Contracts
4. **OrganizationManager** - Handles organization-related operations
5. **CertificationTypeManager** - Manages certificate types
6. **CertificationManager** - Main system controller and entry point

## 🔑 Key Features

### Access Control & Roles
- **Admin**: System owner who can manage organizations, certificate types, and approve/reject certificates
- **Organization Owner**: Can create certificates, add/remove managers
- **Organization Manager**: Can create certificates but cannot manage other managers

### Certificate Lifecycle
1. **Submission**: Organization submits certificate for review
2. **Pending**: Certificate awaits admin approval
3. **Approved**: Certificate is validated and issued
4. **Rejected**: Certificate is rejected with reason
5. **Revoked**: Approved certificate is revoked if needed

### Data Storage
- **On-chain**: Essential certificate data, organization info, certificate types
- **IPFS**: Additional certificate details stored off-chain to optimize gas costs
- **Signatures**: Digital signatures for verification and security

## 📁 Contract Structure

```
src/
├── contracts/
│   ├── Organization.sol          # Organization entity contract
│   ├── CertificateType.sol      # Certificate type entity contract
│   └── Certificate.sol          # Certificate entity contract
├── OrganizationManager.sol      # Organization management
├── CertificationTypeManager.sol # Certificate type management
├── CertificationManager.sol     # Main system controller
└── interfaces/
    ├── ICertificationManager.sol
    ├── IOrganizationManager.sol
    └── ICertificationTypeManager.sol
```

## 🔧 Installation & Setup

### Prerequisites
- [Foundry](https://github.com/foundry-rs/foundry)
- Node.js (for frontend integration)

### Install Dependencies
```bash
# Install Foundry dependencies
forge install

# The system uses OpenZeppelin contracts which are already included
```

### Compile Contracts
```bash
forge build
```

### Run Tests
```bash
forge test
```

## 📖 Usage Examples

### 1. Admin Operations

#### Register an Organization
```solidity
// Register a university
certificationManager.registerOrganization(
    1,                              // Organization ID (from backend)
    0x1234...,                     // Owner address
    "Harvard University",          // Name
    "US"                          // Country code
);
```

#### Create Certificate Type
```solidity
// Create a computer science degree type
certificationManager.createCertificateType(
    1,                              // Type ID (from backend)
    "Computer Science Degree",     // Name
    "CS_DEGREE",                   // Unique code
    "Bachelor of Science in Computer Science"  // Description
);
```

#### Approve Certificate
```solidity
// Approve a pending certificate
certificationManager.approveCertificate(
    certificateId,
    signature                       // Admin's digital signature
);
```

### 2. Organization Operations

#### Submit Certificate
```solidity
// Submit a certificate for approval
certificationManager.submitCertificate(
    1,                              // Certificate ID (from backend)
    organizationId,                // Organization ID
    certificateTypeId,             // Certificate type ID
    "123456789",                   // Holder ID card number
    "US",                          // Holder country code
    85,                            // Grant level/points
    1735689600,                    // Expiration timestamp
    "QmX1234...",                  // IPFS hash
    signature                      // Organization's signature
);
```

#### Add Manager
```solidity
// Add a manager to organization
certificationManager.addManager(
    organizationId,
    managerAddress
);
```

### 3. View Functions

#### Get Certificate Details
```solidity
// Get complete certificate information
CertificateData memory cert = certificationManager.getCertificate(certificateId);
```

#### Check Certificate Validity
```solidity
// Check if certificate is valid (approved and not expired)
bool isValid = certificationManager.isCertificateValid(certificateId);
```

#### Get Holder's Certificates
```solidity
// Get all certificates for a holder
uint256[] memory certIds = certificationManager.getCertificatesByHolder("123456789");
```

## 🏛️ Data Structures

### Organization
```solidity
struct OrganizationData {
    uint256 id;
    address owner;
    string name;
    string countryCode;
    address[] managers;
    bool isActive;
    uint256 createdAt;
    uint256 updatedAt;
}
```

### Certificate Type
```solidity
struct CertificateTypeData {
    uint256 id;
    string name;
    string code;
    string description;
    bool isActive;
    uint256 createdAt;
    uint256 updatedAt;
}
```

### Certificate
```solidity
struct CertificateData {
    uint256 id;
    uint256 organizationId;
    uint256 certificateTypeId;
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
```

## 🔐 Security Features

### Access Control
- Role-based permissions using OpenZeppelin's AccessControl
- Multi-signature support for critical operations
- Organization-level access control

### Data Integrity
- Digital signatures for certificate submission and approval
- IPFS integration for immutable document storage
- Event logging for audit trails

### System Security
- Pause functionality for emergency situations
- Upgrade patterns for contract evolution
- Input validation and error handling

## 🌐 Integration Guide

### Backend Integration
The system expects IDs to be generated by your backend system. Here's the typical flow:

1. **Backend generates unique ID** for organization/certificate type/certificate
2. **Frontend calls contract** with the generated ID and other parameters
3. **Contract validates and stores** the data on-chain

### Frontend Integration
```javascript
// Example using ethers.js
const certificationManager = new ethers.Contract(
    CERTIFICATION_MANAGER_ADDRESS,
    CERTIFICATION_MANAGER_ABI,
    signer
);

// Submit a certificate
const tx = await certificationManager.submitCertificate(
    certificateId,
    organizationId,
    certificateTypeId,
    holderIdCard,
    holderCountryCode,
    grantLevel,
    expireTime,
    ipfsHash,
    signature
);
```

### IPFS Integration
Store detailed certificate information in IPFS:

```javascript
// Store certificate details in IPFS
const certificateDetails = {
    holderName: "John Doe",
    courseName: "Advanced JavaScript",
    completionDate: "2024-01-15",
    instructorName: "Jane Smith",
    additionalNotes: "Excellent performance"
};

const ipfsHash = await ipfs.add(JSON.stringify(certificateDetails));
```

## 📊 Events & Monitoring

The system emits comprehensive events for monitoring:

- `OrganizationCreated`, `OrganizationUpdated`, `OrganizationDeactivated`
- `CertificateTypeCreated`, `CertificateTypeUpdated`, `CertificateTypeDeactivated`
- `CertificateSubmitted`, `CertificateApproved`, `CertificateRejected`, `CertificateRevoked`
- `ManagerAdded`, `ManagerRemoved`
- `SystemPaused`, `SystemUnpaused`

## 🧪 Testing

### Test Structure
```
test/
├── Organization.t.sol
├── CertificateType.t.sol
├── Certificate.t.sol
├── OrganizationManager.t.sol
├── CertificationTypeManager.t.sol
└── CertificationManager.t.sol
```

### Run Tests
```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/CertificationManager.t.sol

# Run with gas reporting
forge test --gas-report
```

## 🚨 Important Considerations

### Gas Optimization
- Batch operations available for bulk certificate processing
- IPFS integration reduces on-chain storage costs
- Efficient data structures minimize gas usage

### Scalability
- Modular design allows for easy upgrades
- Separate manager contracts for better organization
- Event-based querying for frontend efficiency

### Compliance
- Immutable certificate records for regulatory compliance
- Audit trail through blockchain events
- Data privacy through IPFS for sensitive information

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Implement your changes with tests
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔍 Verification

After deployment, you can verify the contracts on Etherscan:

```bash
forge verify-contract CONTRACT_ADDRESS ContractName --etherscan-api-key YOUR_API_KEY
```

## 📞 Support

For questions and support:
- Create an issue in this repository
- Check the existing documentation
- Review the test files for usage examples

---

**Note**: This system is designed for educational certificate management but can be adapted for other types of credentials and certifications.