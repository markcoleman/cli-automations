param(
    [Parameter(Mandatory=$true)]
    [string]$DatabricksHost,
    
    [Parameter(Mandatory=$true)]
    [string]$AccessToken,
    
    [Parameter(Mandatory=$true)]
    [string]$NewCidrBlock,
    
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "allowlist-preview.txt"
)

Write-Host "Generating allowlist preview for environment: $Environment"
Write-Host "New CIDR block to be added: $NewCidrBlock"

# Get current allowlist
$currentAllowlistScript = Join-Path $PSScriptRoot "Get-DatabricksAllowlist.ps1"
$currentAllowlist = & $currentAllowlistScript -DatabricksHost $DatabricksHost -AccessToken $AccessToken

# Create preview content
$previewContent = @"
================================================================================
DATABRICKS IP ALLOWLIST PREVIEW - $Environment Environment
================================================================================
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
Databricks Host: $DatabricksHost
New CIDR Block to Add: $NewCidrBlock

================================================================================
CURRENT IP ACCESS LISTS
================================================================================
$currentAllowlist

================================================================================
PROPOSED CHANGES
================================================================================
Action: ADD new CIDR block
CIDR Block: $NewCidrBlock
Environment: $Environment

The following CIDR block will be added to the IP allowlist:
- $NewCidrBlock

================================================================================
IMPACT ASSESSMENT
================================================================================
- This change will ALLOW network access from the specified CIDR range
- Existing allowlist entries will remain unchanged
- The new CIDR block will be added as an additional allowed range
- Please verify this CIDR block is correct and authorized for $Environment environment

================================================================================
REVIEW REQUIRED
================================================================================
Please review the above changes carefully before approving.
Ensure the CIDR block is correct and authorized for network access.

"@

# Write preview to file
$previewContent | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "Preview generated and saved to: $OutputPath"

# Also display the preview content
Write-Host ""
Write-Host "PREVIEW CONTENT:"
Write-Host "================================================================================"
Write-Host $previewContent
Write-Host "================================================================================"