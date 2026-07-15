[CmdletBinding()]
param(
    [string] $Version = '9.1.9'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$target = Join-Path $root 'espocrm'

$requiredFiles = @(
    'bootstrap.php',
    'application\Espo\Core\Application.php',
    'client\lib\espo-main.js',
    'client\res\templates\login.tpl',
    'install\entry.php',
    'public\index.php',
    'vendor\autoload.php'
)

$missing = $requiredFiles | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $target $_) -PathType Leaf)
}

if ($missing) {
    $list = $missing -join ', '
    throw "The tracked application codebase is incomplete: $list. Restore the files from Git or clone the repository again."
}

$defaults = Join-Path $target 'application\Espo\Resources\defaults\config.php'
if (-not (Select-String -LiteralPath $defaults -SimpleMatch $Version -Quiet)) {
    throw "The tracked application is not the required version $Version."
}

Write-Host "Tracked application codebase $Version is complete at $target." -ForegroundColor Green
