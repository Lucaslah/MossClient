###
# Packwiz wrapper
# This script downloads (if needed) and loads packwiz from the cache to execute CLI commands
###

$scriptLocation = $PSScriptRoot
. "$scriptLocation\modules\PackwizLib.ps1"
$arguments = $args -join ' '
Use-Packwiz $arguments