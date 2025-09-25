// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Organization} from "../src/contracts/Organization.sol";
import {CertificateType} from "../src/contracts/CertificateType.sol";
import {Certificate} from "../src/contracts/Certificate.sol";
import {OrganizationManager} from "../src/OrganizationManager.sol";
import {CertificationTypeManager} from "../src/CertificationTypeManager.sol";
import {CertificationManager} from "../src/CertificationManager.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with the account:", deployer);
        console.log("Account balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy base contracts first
        Organization organizationContract = new Organization(deployer);
        console.log("Organization deployed to:", address(organizationContract));

        CertificateType certificateTypeContract = new CertificateType(deployer);
        console.log("CertificateType deployed to:", address(certificateTypeContract));

        Certificate certificateContract = new Certificate(
            deployer,
            address(organizationContract),
            address(certificateTypeContract)
        );
        console.log("Certificate deployed to:", address(certificateContract));

        // Deploy manager contracts
        OrganizationManager organizationManager = new OrganizationManager(
            deployer, // admin
            address(organizationContract)
        );
        console.log("OrganizationManager deployed to:", address(organizationManager));

        CertificationTypeManager certificationTypeManager = new CertificationTypeManager(
            deployer, // admin
            address(certificateTypeContract)
        );
        console.log("CertificationTypeManager deployed to:", address(certificationTypeManager));

        // Deploy main certification manager
        CertificationManager certificationManager = new CertificationManager(deployer);
        console.log("CertificationManager deployed to:", address(certificationManager));

        // Initialize the certification manager with contract addresses
        certificationManager.initializeContracts(
            address(organizationContract),
            address(certificateContract),
            address(organizationManager)
        );

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Organization Contract:", address(organizationContract));
        console.log("CertificateType Contract:", address(certificateTypeContract));
        console.log("Certificate Contract:", address(certificateContract));
        console.log("OrganizationManager:", address(organizationManager));
        console.log("CertificationTypeManager:", address(certificationTypeManager));
        console.log("CertificationManager:", address(certificationManager));
        console.log("==========================");

        // Write addresses to a text file for easy parsing
        string memory addresses = string.concat(
            "ORGANIZATION_CONTRACT=", vm.toString(address(organizationContract)), "\n",
            "CERTIFICATE_TYPE_CONTRACT=", vm.toString(address(certificateTypeContract)), "\n", 
            "CERTIFICATE_CONTRACT=", vm.toString(address(certificateContract)), "\n",
            "ORGANIZATION_MANAGER=", vm.toString(address(organizationManager)), "\n",
            "CERTIFICATION_TYPE_MANAGER=", vm.toString(address(certificationTypeManager)), "\n",
            "CERTIFICATION_MANAGER=", vm.toString(address(certificationManager)), "\n"
        );
        
        vm.writeFile("deployment-addresses.txt", addresses);
        console.log("Contract addresses written to deployment-addresses.txt");
    }
}