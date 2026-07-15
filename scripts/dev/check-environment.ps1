[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$failed = $false

function Write-Check([string] $Name, [bool] $Passed, [string] $Details) {
    $label = if ($Passed) { 'PASS' } else { 'FAIL' }
    $color = if ($Passed) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1}: {2}" -f $label, $Name, $Details) -ForegroundColor $color
    if (-not $Passed) { $script:failed = $true }
}

$php = Get-Command php -ErrorAction SilentlyContinue
if ($php) {
    $version = & php -r "echo PHP_VERSION;"
    Write-Check 'PHP' ($version -like '8.2.*') "$version (expected 8.2.x)"
    $loaded = & php -r "echo implode(PHP_EOL, get_loaded_extensions());"
    foreach ($extension in @('curl', 'json', 'mbstring', 'openssl', 'pdo_mysql', 'zip')) {
        Write-Check "PHP extension $extension" ($loaded -contains $extension) 'required'
    }
} else {
    Write-Check 'PHP' $false 'php is not available on PATH'
}

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Write-Check 'Compose configuration' (Test-Path (Join-Path $root 'compose.yaml')) 'compose.yaml'
Write-Check 'Environment template' (Test-Path (Join-Path $root '.env.example')) '.env.example'
Write-Check 'Control migration' (Test-Path (Join-Path $root 'database\control-plane\migrations\0001_initial_control_plane.sql')) '0001_initial_control_plane.sql'

$espoDefaults = Join-Path $root 'espocrm\application\Espo\Resources\defaults\config.php'
$espoVersionMatches = (Test-Path -LiteralPath $espoDefaults) -and
    (Select-String -LiteralPath $espoDefaults -SimpleMatch "'version' => '9.1.9'" -Quiet)
Write-Check 'EspoCRM source' $espoVersionMatches 'expected materialized version 9.1.9'

$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    & git -C $root rev-parse --show-toplevel *> $null
    Write-Check 'Git repository' ($LASTEXITCODE -eq 0) $(if ($LASTEXITCODE -eq 0) { $root } else { 'run git init and add the public remote' })
} else {
    Write-Check 'Git' $false 'git is not available on PATH'
}

if ($failed) { Write-Host 'Environment checks failed.' -ForegroundColor Red; exit 1 }
Write-Host 'Environment checks passed.' -ForegroundColor Green
