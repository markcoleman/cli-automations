# CLI Automations

This repository contains reusable automation pipelines and scripts for managing cloud infrastructure and services through command-line interfaces.

## Databricks IP Allowlist Automation

### Overview

The Databricks IP Allowlist Automation provides a secure, auditable, and consistent way to manage IP CIDR allowlists across Databricks workspaces using Azure DevOps pipelines. This automation follows infrastructure-as-code principles with manual approval gates and preview capabilities.

### Pipeline Architecture

The pipeline consists of four main stages:

1. **PreviewTestChange** - Generates a preview of changes for the test environment
2. **Test** - Applies changes to the test environment (requires manual approval)
3. **PreviewProdChange** - Generates a preview of changes for the production environment  
4. **Production** - Applies changes to the production environment (requires manual approval)

### Features

- ✅ **Windows-compatible**: Runs on Windows-based Azure DevOps agents using PowerShell
- ✅ **Preview functionality**: Shows current and proposed allowlist changes before applying
- ✅ **Manual approvals**: Requires human approval before applying changes to any environment
- ✅ **Audit trail**: Full logging and artifact storage for compliance
- ✅ **Multi-environment**: Supports separate test and production configurations
- ✅ **Reusable templates**: Easily add new environments with minimal configuration
- ✅ **Secure token handling**: Uses Azure DevOps secure variables for API tokens

### Prerequisites

Before using this pipeline, ensure you have:

1. **Azure DevOps Project** with appropriate permissions
2. **Databricks Workspaces** for test and production environments
3. **Personal Access Tokens** for each Databricks workspace
4. **DataAdmins Team** configured in Azure DevOps for approvals

### Setup Instructions

#### 1. Generate Databricks Personal Access Tokens

For each Databricks workspace (test and production):

1. Log into your Databricks workspace
2. Click on your username in the top right corner
3. Select **User Settings**
4. Go to the **Access tokens** tab
5. Click **Generate new token**
6. Provide a descriptive name (e.g., "Azure DevOps Pipeline - Test Environment")
7. Set an appropriate expiration date
8. Click **Generate**
9. **Important**: Copy the token immediately as it won't be shown again
10. Store the token securely

#### 2. Configure Azure DevOps Variables

Create the following secure variables in your Azure DevOps project:

| Variable Name | Type | Description | Example Value |
|---------------|------|-------------|---------------|
| `testDatabricksToken` | Secret | PAT for test Databricks workspace | `dapi12345678...` |
| `prodDatabricksToken` | Secret | PAT for production Databricks workspace | `dapi87654321...` |

To add these variables:
1. Go to your Azure DevOps project
2. Navigate to **Pipelines** > **Library**
3. Create a new **Variable Group** named "Databricks-Tokens"
4. Add the variables above and mark them as **Secret**
5. Save the variable group

#### 3. Update Pipeline Configuration

Edit the `azure-pipelines/databricks-ip-allowlist.yml` file and update:

```yaml
variables:
  # Test Environment Configuration
  testDatabricksHost: 'https://your-test-workspace.cloud.databricks.com'
  testCidrBlock: '10.0.0.0/24'  # Your test environment CIDR block
  
  # Production Environment Configuration  
  prodDatabricksHost: 'https://your-prod-workspace.cloud.databricks.com'
  prodCidrBlock: '10.1.0.0/24'  # Your production environment CIDR block
```

#### 4. Configure Approval Gates

1. In Azure DevOps, go to **Pipelines** > **Environments**
2. Create environments named "Test" and "Production"
3. For each environment:
   - Click on the environment name
   - Select **Approvals and checks**
   - Add **Approvals** check
   - Add the "DataAdmins" team as required approvers
   - Configure timeout and other approval settings as needed

#### 5. Create the Pipeline

1. In Azure DevOps, go to **Pipelines**
2. Click **New pipeline**
3. Select your repository
4. Choose **Existing Azure Pipelines YAML file**
5. Select the path: `azure-pipelines/databricks-ip-allowlist.yml`
6. Review and run the pipeline

### Pipeline Execution Flow

#### Stage 1: PreviewTestChange
- Installs Databricks CLI on Windows agent
- Retrieves current IP allowlist from test Databricks workspace
- Generates a preview file showing current and proposed changes
- Uploads preview as pipeline artifact for review

#### Stage 2: Test
- **Manual Approval Required** - DataAdmins team must approve
- Downloads and displays the approved preview
- Shows current allowlist before changes
- Applies the new CIDR block to the test environment
- Shows updated allowlist after changes
- Logs all actions for audit trail

#### Stage 3: PreviewProdChange
- Same as Stage 1 but for production environment
- Only runs after successful test environment deployment

#### Stage 4: Production
- **Manual Approval Required** - DataAdmins team must approve
- Same as Stage 2 but for production environment
- Only runs after successful production preview generation

### File Structure

```
azure-pipelines/
├── databricks-ip-allowlist.yml          # Main pipeline definition
├── templates/
│   ├── preview-stage.yml                # Reusable preview stage template
│   ├── apply-stage.yml                  # Reusable apply stage template
│   └── scripts/
│       ├── Get-DatabricksAllowlist.ps1  # PowerShell script to retrieve current allowlist
│       ├── Generate-AllowlistPreview.ps1 # PowerShell script to generate preview
│       └── Apply-DatabricksAllowlist.ps1 # PowerShell script to apply changes
```

### Adding New Environments

To add a new environment (e.g., "Staging"):

1. **Add variables** to the main pipeline YAML:
```yaml
stagingDatabricksHost: 'https://staging-workspace.cloud.databricks.com'
stagingCidrBlock: '10.2.0.0/24'
```

2. **Add secure token** variable: `stagingDatabricksToken`

3. **Add preview stage**:
```yaml
- template: templates/preview-stage.yml
  parameters:
    environment: 'Staging'
    databricksHost: $(stagingDatabricksHost)
    accessTokenVariable: 'stagingDatabricksToken'
    cidrBlock: $(stagingCidrBlock)
    dependsOn: ['Test']  # or appropriate dependency
```

4. **Add apply stage**:
```yaml
- template: templates/apply-stage.yml
  parameters:
    environment: 'Staging'
    databricksHost: $(stagingDatabricksHost)
    accessTokenVariable: 'stagingDatabricksToken'
    cidrBlock: $(stagingCidrBlock)
    dependsOn: ['PreviewStagingChange']
```

5. **Create environment** in Azure DevOps with appropriate approvals

### Security Considerations

- **Token Security**: Personal Access Tokens are stored as secure variables in Azure DevOps
- **Approval Gates**: Manual approval required before any changes are applied
- **Audit Trail**: All actions are logged and artifacts are stored for compliance
- **Least Privilege**: Use dedicated service accounts with minimal required permissions
- **Token Rotation**: Regularly rotate Personal Access Tokens

### Troubleshooting

#### Common Issues

1. **"Failed to retrieve IP access list"**
   - Verify the Databricks host URL is correct
   - Check that the Personal Access Token is valid and not expired
   - Ensure the token has appropriate permissions

2. **"Could not find or create IP access list"**
   - The script will attempt to create a new allowlist if none exists
   - Check Databricks workspace permissions for IP access list management

3. **Pipeline fails on Windows agent**
   - Ensure all file paths use Windows-style backslashes (`\`)
   - Verify PowerShell execution policy allows script execution

#### Getting Help

1. Check the pipeline logs for detailed error messages
2. Review the generated preview artifacts for expected changes
3. Verify all configuration variables are set correctly
4. Ensure approval gates are properly configured

### Contributing

To contribute improvements to this automation:

1. Fork the repository
2. Create a feature branch
3. Make your changes following the existing patterns
4. Test thoroughly with a non-production environment
5. Submit a pull request with detailed description

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.