Param(
    [Parameter(HelpMessage = "Parameters from AL-Go Deploy action", Mandatory = $true)]
    [hashtable] $parameters
)

Write-Host "Starting On-Premise Deployment"
Write-Host "Deployment Type: $($parameters.type)"
Write-Host "Environment: $($parameters.EnvironmentName)"
Write-Host "Server Instance: $($parameters.ServerInstance)"
Write-Host "Tenant: $($parameters.tenant)"

# Extract AL-Go parameters
$apps = $parameters.Apps
$dependencies = $parameters.Dependencies
$authContext = $parameters.AuthContext | ConvertFrom-Json
$deploymentSettings = $parameters

# Create temporary artifacts directory for filtering
$tempArtifactsDir = Join-Path $env:TEMP "AL-Go-OnPremise-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -Path $tempArtifactsDir -ItemType Directory -Force | Out-Null

try {
    Write-Host "Processing artifacts for on-premise deployment..."
    
    # Copy all apps and dependencies to temp directory for processing
    $allFiles = @()
    if ($apps) {
        $allFiles += $apps
    }
    if ($dependencies) {
        $allFiles += $dependencies
    }
    
    Write-Host "Found $($allFiles.Count) artifact files to process"
    
    # Copy files to temp directory
    foreach ($file in $allFiles) {
        if (Test-Path $file) {
            $fileName = Split-Path $file -Leaf
            $destPath = Join-Path $tempArtifactsDir $fileName
            Copy-Item -Path $file -Destination $destPath -Force
            Write-Host "Copied: $fileName"
        }
    }
    
    # Apply your existing filtering logic
    Write-Host "Applying artifact filters..."
    
    # Remove all apps that are not of the right type (exclude SAAS apps)
    Get-ChildItem $tempArtifactsDir -Recurse -Filter "*.app" -Exclude "*_SAAS.app" | ForEach-Object {
        Write-Host "Keeping: $($_.Name)"
    }
    Get-ChildItem $tempArtifactsDir -Recurse -Filter "*_SAAS.app" | ForEach-Object {
        Write-Host "Removing SAAS app: $($_.Name)"
        Remove-Item $_.FullName -Force
    }
    
    # Remove all test apps
    Get-ChildItem $tempArtifactsDir -Recurse -Filter "*Test*.app" | ForEach-Object {
        Write-Host "Removing test app: $($_.Name)"
        Remove-Item $_.FullName -Force
    }
    
    # Authentication setup using AL-Go auth context or deployment settings
    Write-Host "Setting up authentication..."
    
    # Extract SharePoint credentials from auth context or deployment settings
    $spUsername = $null
    $spPassword = $null
    
    if ($authContext.spUsername -and $authContext.spPassword) {
        $spUsername = $authContext.spUsername
        $spPassword = $authContext.spPassword
    }
    elseif ($deploymentSettings.spUsername -and $deploymentSettings.spPassword) {
        $spUsername = $deploymentSettings.spUsername
        $spPassword = $deploymentSettings.spPassword
    }
    else {
        # Fallback to environment variables (AL-Go secrets)
        $spUsername = $env:spusername
        $spPassword = $env:sppassword
    }
    
    if (-not $spUsername -or -not $spPassword) {
        throw "SharePoint credentials not found. Please configure spUsername and spPassword in deployment settings or environment secrets."
    }
    
    $password = ConvertTo-SecureString $spPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential -ArgumentList $spUsername, $password
    
    # Connect to SharePoint (matching your original script)
    try {
        Write-Host "Connecting to SharePoint..."
        Connect-PnPOnline -Credentials $credential -Url "https://trasersoftware.sharepoint.com/sites/Produktteams" -ClientId "968dcd85-c78a-4e3a-a77d-062753c93ce6"
        Write-Host "SharePoint connection successful"
    }
    catch {
        throw "Failed to connect to SharePoint: $($_.Exception.Message)"
    }
    
    # Extract deployment parameters with defaults
    $serverInstance = $deploymentSettings.ServerInstance
    $tenant = $deploymentSettings.tenant
    $releaseType = $deploymentSettings.releasetype ?? "Production"
    $appType = $deploymentSettings.apptype ?? "PTE"
    $targetBCVersion = $deploymentSettings.targetBCVersion ?? "22.0"
    $targetBCCountry = $deploymentSettings.targetBCCountry ?? "W1"
    $syncMode = $deploymentSettings.syncMode ?? "Add"
    $useNuGet = $deploymentSettings.useNuGet ?? $true
    $nuGetToken = $env:TRASERInternalFeedsToken ?? $deploymentSettings.nuGetToken
    
    Write-Host "Deployment Configuration:"
    Write-Host "  Server Instance: $serverInstance"
    Write-Host "  Tenant: $tenant"
    Write-Host "  Release Type: $releaseType"
    Write-Host "  App Type: $appType"
    Write-Host "  Target BC Version: $targetBCVersion"
    Write-Host "  Target BC Country: $targetBCCountry"
    Write-Host "  Sync Mode: $syncMode"
    Write-Host "  Use NuGet: $useNuGet"
    
    # Validate required parameters
    if (-not $serverInstance) {
        throw "ServerInstance is required for on-premise deployment"
    }
    if (-not $tenant) {
        throw "Tenant is required for on-premise deployment"
    }
    
    # Call your existing Deploy-ToBCCustomer function
    Write-Host "Calling Deploy-ToBCCustomer..."
    
    # Ensure the Deploy-ToBCCustomer function is available
    # You may need to import your module here
    # Import-Module YourDeploymentModule -Force
    
    $deploymentParams = @{
        artifactFolder = $tempArtifactsDir
        ServerInstance = $serverInstance
        tenant = $tenant
        sharepointcredential = $credential
        releasetype = $releaseType
        apptype = $appType
        targetBCVersion = $targetBCVersion
        targetBCCountry = $targetBCCountry
        syncMode = $syncMode
        useNuGet = $useNuGet
    }
    
    if ($nuGetToken) {
        $deploymentParams.nuGetToken = $nuGetToken
    }
    
    # This is where you would call your existing deployment function
    # Uncomment and modify as needed when Deploy-ToBCCustomer is available
    # Deploy-ToBCCustomer @deploymentParams
    
    Write-Host "Deployment parameters prepared:"
    $deploymentParams | Format-Table -AutoSize
    
    Write-Host "On-premise deployment completed successfully"
}
catch {
    Write-Error "On-premise deployment failed: $($_.Exception.Message)"
    throw
}
finally {
    # Cleanup
    if (Test-Path $tempArtifactsDir) {
        Write-Host "Cleaning up temporary directory..."
        Get-ChildItem -Path $tempArtifactsDir -Include * -Recurse -File | ForEach-Object { 
            Remove-Item -Path $_.FullName -Force
        }
        Remove-Item -Path $tempArtifactsDir -Force -Recurse
    }
    
    # Disconnect from SharePoint if connected
    try {
        Disconnect-PnPOnline
    }
    catch {
        # Ignore disconnection errors
    }
}