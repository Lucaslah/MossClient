# Moss Init

$scriptLocation = $PSScriptRoot

# import packwiz
. "$scriptLocation\PackwizLib.ps1"
. "$scriptLocation\ModlistLib.ps1"

function Show-Menu {
    Clear-Host
    Write-Host "=== Menu ==="
    Write-Host "1. Build Modrinth (mrpack)"
    Write-Host "2. Build Mod List (html)"
    Write-Host "Q. Quit"
}

while ($true) {
    Show-Menu
    $choice = Read-Host "Select an option"

    Switch ($choice) {
        '1' {
            Write-Host "Starting modrinth build..."

            $targetLocation = (Get-Item $scriptLocation).parent.FullName
            $outoutLocation = "$targetLocation\build"

            if (-not (Test-Path -Path $outoutLocation -PathType Container)) {
                New-Item -Path $outoutLocation -ItemType Directory
            }

            Push-Location $targetLocation
            Use-Packwiz "modrinth export --output build\MossClient.mrpack"
            Pop-Location

            Pause
        }
        '2' {
            Write-Host "Starting mod list build..."
            Get-Modlist
            Pause
        }
        'Q' {
            Write-Host "Goodbye from MossInit"
            return
        }
        default {
            Write-Host "Invalid choice. Please try again."
            Pause
        }
    }
}
