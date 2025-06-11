param(
    [Parameter(Mandatory=$true)]
    [string]$DatabricksHost,
    
    [Parameter(Mandatory=$true)]
    [string]$AccessToken,
    
    [Parameter(Mandatory=$true)]
    [string]$NewCidrBlock,
    
    [Parameter(Mandatory=$true)]
    [string]$Environment
)

Write-Host "=================================================================================="
Write-Host "APPLYING DATABRICKS IP ALLOWLIST CHANGES - $Environment Environment"
Write-Host "=================================================================================="
Write-Host "Databricks Host: $DatabricksHost"
Write-Host "New CIDR Block: $NewCidrBlock"
Write-Host "Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")"
Write-Host ""

# Configure Databricks CLI
Write-Host "Configuring Databricks CLI..."
$env:DATABRICKS_HOST = $DatabricksHost
$env:DATABRICKS_TOKEN = $AccessToken

# Display current allowlist before changes
Write-Host "STEP 1: Displaying current allowlist BEFORE changes"
Write-Host "=================================================================================="
$beforeScript = Join-Path $PSScriptRoot "Get-DatabricksAllowlist.ps1"
$beforeAllowlist = & $beforeScript -DatabricksHost $DatabricksHost -AccessToken $AccessToken

Write-Host ""
Write-Host "STEP 2: Applying new CIDR block to allowlist"
Write-Host "=================================================================================="
Write-Host "Adding CIDR block: $NewCidrBlock"

try {
    # Create a new IP access list or add to existing one
    $listName = "$Environment-Pipeline-Allowlist"
    
    # First, try to create a new allowlist (this will fail if it exists, which is fine)
    Write-Host "Attempting to create new IP access list: $listName"
    $createResult = databricks ip-access-lists create --label $listName --list-type ALLOW --ip-addresses $NewCidrBlock 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully created new IP access list with CIDR block: $NewCidrBlock"
    } else {
        Write-Host "IP access list may already exist, attempting to update existing list..."
        
        # Get existing lists to find the one to update
        $existingLists = databricks ip-access-lists list --output json | ConvertFrom-Json
        $targetList = $existingLists.ip_access_lists | Where-Object { $_.label -eq $listName }
        
        if ($targetList) {
            Write-Host "Found existing list: $($targetList.label) (ID: $($targetList.list_id))"
            
            # Get current IP addresses
            $currentIPs = $targetList.ip_addresses
            $allIPs = $currentIPs + $NewCidrBlock
            
            # Update the list with new CIDR block
            $updateResult = databricks ip-access-lists replace --list-id $targetList.list_id --label $listName --list-type ALLOW --ip-addresses ($allIPs -join ',') --enabled true 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Successfully updated IP access list with new CIDR block: $NewCidrBlock"
            } else {
                Write-Error "Failed to update IP access list: $updateResult"
                exit 1
            }
        } else {
            Write-Error "Could not find or create IP access list: $listName"
            Write-Error "Create result: $createResult"
            exit 1
        }
    }
    
} catch {
    Write-Error "Error applying CIDR block: $($_.Exception.Message)"
    exit 1
}

Write-Host ""
Write-Host "STEP 3: Displaying allowlist AFTER changes"
Write-Host "=================================================================================="
Start-Sleep -Seconds 5  # Allow time for changes to propagate

$afterScript = Join-Path $PSScriptRoot "Get-DatabricksAllowlist.ps1"
$afterAllowlist = & $afterScript -DatabricksHost $DatabricksHost -AccessToken $AccessToken

Write-Host ""
Write-Host "STEP 4: Change Summary"
Write-Host "=================================================================================="
Write-Host "Environment: $Environment"
Write-Host "CIDR Block Added: $NewCidrBlock"
Write-Host "Applied at: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")"
Write-Host "Status: SUCCESS"
Write-Host ""
Write-Host "=================================================================================="
Write-Host "DATABRICKS IP ALLOWLIST UPDATE COMPLETED SUCCESSFULLY"
Write-Host "=================================================================================="