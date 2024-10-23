# Function to parse JSON input
function parse ([string]$Inputs) {
    $Param = try { 
        $Inputs | ConvertFrom-Json 
    } catch { 
        throw "Error parsing JSON input: $($_.Exception.Message)" 
    }

    # Validate input for maintenance-token and CsUninstallTool location
    if (-not $Param.'maintenance-token') {
        throw "Missing required parameter 'maintenance-token'."
    }
    if (-not $Param.'cs-uninstall-tool-location') {
        throw "Missing required parameter 'cs-uninstall-tool-location'."
    }

    return $Param
}

# Function to create a batch file in a dynamic location
function create_batch_file ([string]$csUninstallToolLocation) {
    # Determine the location for writing the batch file based on CsUninstallTool.exe location
    $batchFilePath = Join-Path -Path $csUninstallToolLocation -ChildPath "uninstall_WIN.bat"
    
    # Content of the batch file to be written
    $batchContent = @"
@echo off
echo Starting uninstall process at %date% %time% >> uninstall.log
if "%1"=="" (
    echo No token provided. Running uninstall without token. >> uninstall.log
    cd $csUninstallToolLocation
    CsUninstallTool.exe /quiet >> uninstall.log 2>&1
) else (
    echo Running uninstall with token: %1 >> uninstall.log
    cd $csUninstallToolLocation
    CsUninstallTool.exe MAINTENANCE_TOKEN=%1 /quiet >> uninstall.log 2>&1
)
echo Uninstall process completed at %date% %time% >> uninstall.log
"@

    # Write the content to the batch file
    try {
        Set-Content -Path $batchFilePath -Value $batchContent -Force
        Write-Host "Batch file created successfully at $batchFilePath."
        return $batchFilePath
    } catch {
        throw "Error writing batch file: $($_.Exception.Message)"
    }
}

# Function to run the batch file
function run_batch ([string]$script, [string]$maintenanceToken) {
    # Run the batch file with maintenance-token as argument
    try {
        Start-Process -FilePath $script -ArgumentList $maintenanceToken -Wait
        return @{status="success"; message="Batch file executed successfully."} | ConvertTo-Json
    } catch {
        return @{status="error"; message="Failed to run batch file: $($_.Exception.Message)"} | ConvertTo-Json
    }
}

# Parse the input JSON
$Param = parse $args[0]

# Create the batch file in the same directory as CsUninstallTool.exe
$batchFilePath = create_batch_file $Param.'cs-uninstall-tool-location'

# Run the batch file with the maintenance-token as a parameter
run_batch $batchFilePath $Param.'maintenance-token'
