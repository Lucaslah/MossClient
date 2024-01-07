# Run packwiz commands

$scriptLocation = $PSScriptRoot
. "$scriptLocation\PackwizLib.ps1"
$arguments = $args -join ' '
Use-Packwiz $arguments