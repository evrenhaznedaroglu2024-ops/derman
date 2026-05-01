# Add Claude CLI to Windows PATH
# Run this script in PowerShell as Administrator if modifying the system PATH,
# or without elevation to update only your user PATH.

param(
    [switch]$System  # Pass -System to add to machine-wide PATH instead of user PATH
)

function Find-ClaudePath {
    # Check common npm global bin locations
    $candidates = @(
        "$env:APPDATA\npm",
        "$env:ProgramFiles\nodejs",
        "$env:ProgramFiles\nodejs\node_modules\.bin"
    )

    foreach ($dir in $candidates) {
        if (Test-Path "$dir\claude.cmd") {
            return $dir
        }
    }

    # Try resolving via npm directly
    try {
        $npmPrefix = (npm prefix -g 2>$null).Trim()
        if ($npmPrefix -and (Test-Path "$npmPrefix\claude.cmd")) {
            return $npmPrefix
        }
    } catch {}

    return $null
}

$claudeDir = Find-ClaudePath

if (-not $claudeDir) {
    Write-Warning "Could not locate claude.cmd automatically."
    Write-Host "Install Claude Code first with:  npm install -g @anthropic-ai/claude-code"
    exit 1
}

Write-Host "Found Claude CLI at: $claudeDir"

$scope = if ($System) { [System.EnvironmentVariableTarget]::Machine } `
         else          { [System.EnvironmentVariableTarget]::User   }

$current = [System.Environment]::GetEnvironmentVariable("PATH", $scope)

if ($current -split ";" | Where-Object { $_ -eq $claudeDir }) {
    Write-Host "PATH already contains '$claudeDir'. No changes needed."
    exit 0
}

$updated = ($current.TrimEnd(";") + ";" + $claudeDir)
[System.Environment]::SetEnvironmentVariable("PATH", $updated, $scope)

Write-Host "Added '$claudeDir' to the $(if ($System) { 'system' } else { 'user' }) PATH."
Write-Host "Restart your terminal (or open a new PowerShell window) and run:  claude"
