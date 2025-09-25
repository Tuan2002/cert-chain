# Deployment Documentation

This document describes the automated deployment process for the Certificate Chain smart contracts to Ethereum Sepolia testnet.

## Overview

The deployment workflow consists of 4 main steps:
1. **Test** - Run the complete test suite
2. **Build** - Compile contracts and generate artifacts
3. **Deploy** - Deploy contracts to Sepolia testnet
4. **Summary** - Generate deployment report with contract addresses

## Required GitHub Secrets

Before running the deployment workflow, you need to configure the following secrets in your GitHub repository:

### Required Secrets

1. **`SEPOLIA_RPC_URL`** - Ethereum Sepolia testnet RPC endpoint
   - Example: `https://sepolia.infura.io/v3/YOUR_PROJECT_ID`
   - You can get this from [Infura](https://infura.io/), [Alchemy](https://www.alchemy.com/), or [QuickNode](https://quicknode.com/)

2. **`PRIVATE_KEY`** - Private key of the deployer account
   - ⚠️ **SECURITY WARNING**: Use a dedicated deployment account, never your main account
   - The account must have sufficient ETH on Sepolia testnet for deployment gas fees
   - Get Sepolia ETH from: [Sepolia Faucet](https://sepoliafaucet.com/)

3. **`ETHERSCAN_API_KEY`** (Optional but recommended)
   - API key for contract verification on Etherscan
   - Get your API key from [Etherscan](https://etherscan.io/apis)
   - Without this, contracts won't be automatically verified

### Setting Up Secrets

1. Go to your GitHub repository
2. Click on **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each secret above
4. Enter the secret name and value

## Contract Deployment Order

The deployment script deploys contracts in this specific order:

1. **Organization** contract (base contract for managing organizations)
2. **CertificateType** contract (base contract for managing certificate types)
3. **Certificate** contract (base contract for managing certificates)
4. **OrganizationManager** (manager for organization operations)
5. **CertificationTypeManager** (manager for certificate type operations)
6. **CertificationManager** (main contract that coordinates everything)

## Workflow Triggers

The deployment workflow can be triggered by:

- **Push to main branch** - Automatic deployment
- **Push to develop branch** - Runs tests and build, but no deployment
- **Pull requests to main** - Runs tests and build only
- **Manual trigger** - Use "Run workflow" button in GitHub Actions

## Environment Configuration

The workflow uses a GitHub Environment called `Development` for additional security. This allows you to:

- Add environment-specific secrets
- Require manual approval before deployment
- Add deployment protection rules

To set up the environment:
1. Go to **Settings** → **Environments**
2. Create new environment named `Development`
3. Configure protection rules as needed

## Deployment Outputs

After successful deployment, the workflow provides:

### Deployment Artifacts
- `deployment-addresses.txt` - Contract addresses in key=value format
- `deployment-summary.json` - Complete deployment info in JSON format
- `broadcast/` - Foundry broadcast logs and transaction details

### GitHub Summary
The workflow generates a comprehensive summary including:
- Contract addresses with Etherscan links
- Environment variables for frontend/backend integration
- Deployment transaction details
- Next steps for integration

## Local Testing

You can test the deployment script locally:

```bash
# Set environment variables
export RPC_URL="https://sepolia.infura.io/v3/YOUR_PROJECT_ID"
export PRIVATE_KEY="your_private_key"

# Run deployment script
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

## Troubleshooting

### Common Issues

1. **Insufficient balance** - Ensure deployer account has enough Sepolia ETH
2. **RPC rate limits** - Use a reliable RPC provider (Infura, Alchemy)
3. **Contract verification fails** - Check ETHERSCAN_API_KEY is valid
4. **Deployment script fails** - Review contract dependencies and constructor arguments

### Getting Help

- Check the GitHub Actions logs for detailed error messages
- Review the Foundry documentation: https://book.getfoundry.sh/
- Check Etherscan for contract interactions: https://sepolia.etherscan.io/

## Security Considerations

- Always use a dedicated deployment account
- Never commit private keys to version control
- Use GitHub Environment protection rules for production deployments
- Regularly rotate API keys and secrets
- Monitor deployed contracts for unusual activity