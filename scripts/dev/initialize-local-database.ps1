[CmdletBinding()]
param(
    [string] $ClientPath = 'mariadb',
    [string] $Database = 'espocrm',
    [string] $DatabaseHost = '127.0.0.1',
    [int] $Port = 3306,
    [string] $User = 'espocrm',
    [string] $EnvironmentFile = '.env'
)

$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'apply-shared-schema.ps1'

& $script `
    -Mode Local `
    -ClientPath $ClientPath `
    -Database $Database `
    -DatabaseHost $DatabaseHost `
    -Port $Port `
    -User $User `
    -EnvironmentFile $EnvironmentFile `
    -InitializeBaseSchema

if ($LASTEXITCODE -ne 0) {
    throw 'Local product schema initialization failed.'
}

Write-Host 'Local database schema is ready for the browser installer.' -ForegroundColor Green
