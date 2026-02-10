# Set script directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# Check if already activated (only for reset and add commands)
if ($args[0] -eq "reset" -or $args[0] -eq "add") {
    if (Test-Path Env:\_MY_ENV_ACTIVATED) {
        Write-Host "Error: Environment is already activated. Use \"my deactivate\" first."
        exit 1
    }
}

# my list - List environments
if ($args[0] -eq "list") {
    Write-Host "Environments available:"
    Write-Host "======================"
    Get-ChildItem -Path "$SCRIPT_DIR\envs" -Directory | ForEach-Object {
        Write-Host "  $($_.Name)"
    }
    exit 0
# my reset - Reset environment
} elseif ($args[0] -eq "reset") {
    if ($args.Count -lt 2) {
        Write-Host "Error: Usage: my reset [env_name]"
        exit 1
    }
    
    $env_name = $args[1]
    
    # Check if environment exists
    if (-not (Test-Path "$SCRIPT_DIR\envs\$env_name")) {
        Write-Host "Error: Environment \"$env_name\" does not exist."
        exit 1
    }
    
    # Save original environment if not already saved
    if (-not (Test-Path Env:\_MY_ENV_ACTIVATED)) {
        # Save PATH and PROMPT specifically
        $env:_MY_OLD_PATH = $env:PATH
        $env:_MY_OLD_PROMPT = $env:PROMPT
    }
    
    # Load environment variables
    if (Test-Path "$SCRIPT_DIR\envs\$env_name\path.ini") {
        # Read path.ini file line by line
        Get-Content "$SCRIPT_DIR\envs\$env_name\path.ini" | ForEach-Object {
            $line = $_.Trim()
            # Skip comment lines
            if (-not $line.StartsWith("#") -and -not [string]::IsNullOrEmpty($line)) {
                # Only add existing paths to PATH
                if (Test-Path $line) {
                    $env:PATH = "$line;$env:PATH"
                }
            }
        }
    }
    
    if (Test-Path "$SCRIPT_DIR\envs\$env_name\variable.ini") {
        # Read variable.ini file line by line
        Get-Content "$SCRIPT_DIR\envs\$env_name\variable.ini" | ForEach-Object {
            $line = $_.Trim()
            # Skip comment lines
            if (-not $line.StartsWith("#") -and -not [string]::IsNullOrEmpty($line)) {
                # Split line into key and value
                $parts = $line -split "=", 2
                if ($parts.Count -eq 2) {
                    $key = $parts[0].Trim()
                    $value = $parts[1].Trim()
                    Set-Item -Path Env:\$key -Value $value
                }
            }
        }
    }
    
    # Update prompt
    $env:PROMPT = "[$env_name] $env:PROMPT"
    
    # Mark as activated
    $env:_MY_ENV_ACTIVATED = "1"
    $env:_MY_CURRENT_ENV = $env_name
    
    Write-Host "Environment \"$env_name\" reset and activated."
    exit 0
# my add - Add environment
} elseif ($args[0] -eq "add") {
    if ($args.Count -lt 2) {
        Write-Host "Error: Usage: my add [env_name]"
        exit 1
    }
    
    $env_name = $args[1]
    
    # Check if environment exists
    if (-not (Test-Path "$SCRIPT_DIR\envs\$env_name")) {
        Write-Host "Error: Environment \"$env_name\" does not exist."
        exit 1
    }
    
    # Save original environment if not already saved
    if (-not (Test-Path Env:\_MY_ENV_ACTIVATED)) {
        # Save PATH and PROMPT specifically
        $env:_MY_OLD_PATH = $env:PATH
        $env:_MY_OLD_PROMPT = $env:PROMPT
    }
    
    # Load environment variables
    if (Test-Path "$SCRIPT_DIR\envs\$env_name\path.ini") {
        # Read path.ini file line by line
        Get-Content "$SCRIPT_DIR\envs\$env_name\path.ini" | ForEach-Object {
            $line = $_.Trim()
            # Skip comment lines
            if (-not $line.StartsWith("#") -and -not [string]::IsNullOrEmpty($line)) {
                # Only add existing paths to PATH
                if (Test-Path $line) {
                    $env:PATH = "$line;$env:PATH"
                }
            }
        }
    }
    
    if (Test-Path "$SCRIPT_DIR\envs\$env_name\variable.ini") {
        # Read variable.ini file line by line
        Get-Content "$SCRIPT_DIR\envs\$env_name\variable.ini" | ForEach-Object {
            $line = $_.Trim()
            # Skip comment lines
            if (-not $line.StartsWith("#") -and -not [string]::IsNullOrEmpty($line)) {
                # Split line into key and value
                $parts = $line -split "=", 2
                if ($parts.Count -eq 2) {
                    $key = $parts[0].Trim()
                    $value = $parts[1].Trim()
                    Set-Item -Path Env:\$key -Value $value
                }
            }
        }
    }
    
    # Update prompt
    $env:PROMPT = "[$env_name] $env:PROMPT"
    
    # Mark as activated
    $env:_MY_ENV_ACTIVATED = "1"
    $env:_MY_CURRENT_ENV = $env_name
    
    Write-Host "Environment \"$env_name\" added and activated."
    exit 0
# my deactivate - Deactivate environment
} elseif ($args[0] -eq "deactivate") {
    if (-not (Test-Path Env:\_MY_ENV_ACTIVATED)) {
        Write-Host "Error: No environment is activated."
        exit 1
    }
    
    # Restore original environment
    # Restore PATH and PROMPT specifically
    if (Test-Path Env:\_MY_OLD_PATH) {
        $env:PATH = $env:_MY_OLD_PATH
    }
    if (Test-Path Env:\_MY_OLD_PROMPT) {
        $env:PROMPT = $env:_MY_OLD_PROMPT
    }
    
    # Clear activation flags and old variables
    Remove-Item -Path Env:\_MY_ENV_ACTIVATED -ErrorAction SilentlyContinue
    Remove-Item -Path Env:\_MY_CURRENT_ENV -ErrorAction SilentlyContinue
    Remove-Item -Path Env:\_MY_OLD_PATH -ErrorAction SilentlyContinue
    Remove-Item -Path Env:\_MY_OLD_PROMPT -ErrorAction SilentlyContinue
    
    Write-Host "Environment deactivated."
    exit 0
# my help - Show help
} elseif ($args[0] -eq "help") {
    Write-Host "Usage:"
    Write-Host "  my list                - List available environments"
    Write-Host "  my reset [env_name]    - Reset and activate environment"
    Write-Host "  my add [env_name]      - Add and activate environment"
    Write-Host "  my deactivate          - Deactivate current environment"
    Write-Host "  my help                - Show this help message"
    exit 0
# No command specified
} elseif ($args.Count -eq 0) {
    Write-Host "Error: No command specified."
    Write-Host "Usage:"
    Write-Host "  my list                - List available environments"
    Write-Host "  my reset [env_name]    - Reset and activate environment"
    Write-Host "  my add [env_name]      - Add and activate environment"
    Write-Host "  my deactivate          - Deactivate current environment"
    Write-Host "  my help                - Show this help message"
    exit 1
# Unknown command
} else {
    Write-Host "Error: Unknown command \"$($args[0])\"."
    Write-Host "Usage:"
    Write-Host "  my list                - List available environments"
    Write-Host "  my reset [env_name]    - Reset and activate environment"
    Write-Host "  my add [env_name]      - Add and activate environment"
    Write-Host "  my deactivate          - Deactivate current environment"
    Write-Host "  my help                - Show this help message"
    exit 1
}