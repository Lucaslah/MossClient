function Get-Modlist {
    $scriptLocation = $PSScriptRoot
    $targetLocation = (Get-Item $scriptLocation).parent.FullName
    $modsPath = "$targetLocation\mods"
    $outputPath = "$targetLocation\build\mods.html"
    $buildPath = "$targetLocation\build"

    $list = New-Object System.Collections.ArrayList

    Get-ChildItem -Path $modsPath -File | ForEach-Object {
        try {
            $rawContent = Get-Content -Path $_.FullName -Raw

            $modIdRegex = '\[update.modrinth\]\s*mod-id\s*=\s*"([^"]+)"'
            $modIdMatch = [regex]::Match($rawContent, $modIdRegex)

            $name = [regex]::Match($rawContent, 'name\s*=\s*"([^"]+)"').Groups[1].Value

            if ($modIdMatch.Success) {
                $modId = $modIdMatch.Groups[1].Value
            }

            $list.Add("<li><a href='https://modrinth.com/mod/$modId'>$name</a></li>")
        } catch {
            Write-Host "Error reading file $($_.FullName): $_"
        }
    }
    
    $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<body>
    <ul>
        $($list -join "`n") 
    </ul>
</body>
</html>
"@

    if (-not (Test-Path -Path $buildPath -PathType Container)) {
        New-Item -Path $buildPath -ItemType Directory
        Write-Host "Directory created: $buildPath"
    }

    $htmlContent | Set-Content -Path "$outputPath"

    Write-Host "Build HTML mod-list to $outputPath"
}