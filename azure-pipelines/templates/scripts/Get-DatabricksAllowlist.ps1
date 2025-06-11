param(
    [Parameter(Mandatory=$true)]
    [string]$DatabricksHost,
    
    [Parameter(Mandatory=$true)]
    [string]$AccessToken
)

# Configure Databricks CLI
Write-Host "Configuring Databricks CLI for host: $DatabricksHost"
$env:DATABRICKS_HOST = $DatabricksHost
$env:DATABRICKS_TOKEN = $AccessToken

# Get current IP access list
Write-Host "Retrieving current IP access list..."
try {
    $allowlistJson = databricks ip-access-lists list --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to retrieve IP access list: $allowlistJson"
        exit 1
    }
    
    # Parse and format the output
    $allowlist = $allowlistJson | ConvertFrom-Json
    
    if ($allowlist.ip_access_lists -and $allowlist.ip_access_lists.Count -gt 0) {
        Write-Host "Current IP Access Lists:"
        foreach ($list in $allowlist.ip_access_lists) {
            Write-Host "  List: $($list.label) (ID: $($list.list_id))"
            Write-Host "    Type: $($list.list_type)"
            Write-Host "    Enabled: $($list.enabled)"
            if ($list.ip_addresses) {
                Write-Host "    IP Addresses:"
                foreach ($ip in $list.ip_addresses) {
                    Write-Host "      - $ip"
                }
            }
            Write-Host ""
        }
    } else {
        Write-Host "No IP access lists found."
    }
    
    # Return the JSON for further processing
    return $allowlistJson
    
} catch {
    Write-Error "Error retrieving IP access list: $($_.Exception.Message)"
    exit 1
}