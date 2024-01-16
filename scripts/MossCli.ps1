param(
    [string]$Command
)

$scriptLocation = $PSScriptRoot

# import packwiz
. "$scriptLocation\PackwizLib.ps1"
. "$scriptLocation\ModlistLib.ps1"

switch ($Command) {
    "Build-Mrpack" {
        Write-Host "Starting modrinth build..."

        $targetLocation = (Get-Item $scriptLocation).parent.FullName
        $outoutLocation = "$targetLocation\build"

        if (-not (Test-Path -Path $outoutLocation -PathType Container)) {
            New-Item -Path $outoutLocation -ItemType Directory
        }

        Push-Location $targetLocation

        $version = (Get-Content -Path "$scriptLocation\..\pack.toml" | Select-String -Pattern '^version\s*=').ToString() -split '\"' | Select-Object -Index 1

        Use-Packwiz "modrinth export --output build\MossClient-$version.mrpack"
        Pop-Location
    }
    "Build-Mostlist" {
        Write-Host "Starting mod list build..."
        Get-Modlist
    }
    default {
        Write-Host "Unknown command: $Command"
    }
}