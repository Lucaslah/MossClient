<#
.SYNOPSIS
    Locates or downloads then runs packwiz

.DESCRIPTION
    Function for using packwiz commands from powershell

.PARAMETER arguments
    packwiz command arguments

.EXAMPLE
    Example 1:
    -----------------
    Use-Packwiz "modrinth export"

.NOTES
    Author: Lucaslah
    Date: January 7, 2024
#>
function Use-Packwiz {
    param (
        [array] $arguments
    )

    $scriptLocation = $PSScriptRoot
    $cacheLocation = "$scriptLocation\.cache"

    # First check for packwiz in cache location
    if (Test-Path "$cacheLocation\packwiz.exe" -PathType Leaf) {
        # Found! run the command
        $command = "& `"$cacheLocation\packwiz.exe`" $($arguments -join ' ')"
        Invoke-Expression $command
    } else {
        $packwizExists = Get-Command -Name packwiz -ErrorAction SilentlyContinue
        $ghExists = Get-Command -Name gh -ErrorAction SilentlyContinue

        # Check if packwiz is installed on the system
        if ($packwizExists) {
            $command = "& `"$src`" $($arguments -join ' ')"
            Invoke-Expression $command
        } else {
            # Download packwiz from GitHub
            if ($ghExists) {
                $artifactName = "Windows 64-bit"

                $tempDirName = Join-Path $env:TEMP ("tempdir" + (Get-Random))
                New-Item -ItemType Directory -Path $tempDirName -Force

                # Download
                gh run download --repo packwiz/packwiz --name $artifactName --dir $tempDirName

                $packwizDownloadPath = "$tempDirName\packwiz.exe"

                New-Item -ItemType Directory -Path $cacheLocation -Force

                if (Test-Path $packwizDownloadPath -PathType Leaf) {
                    Copy-Item -Path $packwizDownloadPath -Destination $cacheLocation -Force
                } else {
                    Write-Host "packwiz download failed."
                }

                # Cleanup
                Remove-Item -Path $tempDirName -Recurse -Force

                # Run
                $command = "& `"$cacheLocation\packwiz.exe`" $($arguments -join ' ')"
                Invoke-Expression $command
            } else {
                throw "MossInit failed to locate or download packwiz, please install packwiz or the GitHub CLI (make sure to login with gh auth login)"
            }
        }
    }
}