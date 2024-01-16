###
# Moss build system
#
# This powershell script is a simple CLI for building Moss Client
# Usage: .\Moss.ps1 build <module>
###

param (
    [string]$action,
    [string]$moduleType
)

$scriptLocation = $PSScriptRoot
$validModuleTypes = @("mod-list", "mrpack", "all")

###
# Setup build result locations
###

$targetLocation = (Get-Item $scriptLocation).parent.FullName
$outoutLocation = "$targetLocation\build"

if (-not (Test-Path -Path $outoutLocation -PathType Container)) {
    New-Item -Path $outoutLocation -ItemType Directory
}

###
# Setup source locations
###

$sourceLocation = "$targetLocation\pack"

###
# Setup build version
###

$version = (Get-Content -Path "$sourceLocation\pack.toml" | Select-String -Pattern '^version\s*=').ToString() -split '\"' | Select-Object -Index 1

###
# Import powershell scripts to build the mod-list and mrpack for modrinth
###

. "$scriptLocation\modules\PackwizLib.ps1"
. "$scriptLocation\modules\ModlistLib.ps1"

function Build-Module {
    param (
        [string]$moduleType
    )

    Write-Host "Starting build for Moss Client version $version"
    Write-Host "Building module: $moduleType"

    if ($moduleType -eq "mod-list") {
        Use-BuildModlist($targetLocation)
    } elseif ($moduleType -eq "mrpack") {
        Use-BuildMrpack($targetLocation)
    } elseif ($moduleType -eq "all") {
        Use-BuildMrpack($targetLocation)
        Use-BuildModlist($targetLocation)
    }
}

function Show-Help {
    Write-Host "Usage: .\Moss.ps1 build <module>"
    Write-Host "Supported modules: $($validModuleTypes -join ', ')"
}

if ($action -eq "build") {
    if ($validModuleTypes -contains $moduleType) {
        Build-Module -moduleType $moduleType
    } else {
        Write-Host "Invalid module type. Supported types: $($validModuleTypes -join ', ')"
        exit 1
    }
} elseif ($action -eq "help") {
    Show-Help
} else {
    Write-Host "Invalid action. Supported actions: build, help"
}
