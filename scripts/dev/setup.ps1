[CmdletBinding()]
param(
    [switch] $SkipStart
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$envPath = Join-Path $root '.env'
$envExample = Join-Path $root '.env.example'

function New-RandomSecret {
    $bytes = New-Object byte[] 32
    $generator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $generator.GetBytes($bytes) } finally { $generator.Dispose() }
    return [Convert]::ToBase64String($bytes).Replace('+', 'A').Replace('/', 'B').TrimEnd('=')
}

if (-not (Test-Path $envPath)) {
    $content = Get-Content -LiteralPath $envExample -Raw
    $content = $content.Replace('replace_with_a_long_random_password', (New-RandomSecret))
    $content = $content.Replace('replace_with_a_different_long_random_password', (New-RandomSecret))
    $content = $content.Replace('replace_with_a_third_long_random_password', (New-RandomSecret))
    $content = $content.Replace('replace_with_a_strong_admin_password', (New-RandomSecret))
    $content = $content.Replace('replace_with_a_demo_tenant_admin_password', (New-RandomSecret))
    Set-Content -LiteralPath $envPath -Value $content -Encoding ASCII
    Write-Host 'Created .env with local random credentials. Do not commit it.' -ForegroundColor Green
}
else {
    Write-Host 'Keeping the existing .env file.'
}

& (Join-Path $PSScriptRoot 'bootstrap-espocrm.ps1')
& (Join-Path $PSScriptRoot 'check-environment.ps1')

if (-not $SkipStart) {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw 'Docker is unavailable. Use -SkipStart for an XAMPP or WampServer setup.'
    }
    & docker compose --project-directory $root up -d --wait
    if ($LASTEXITCODE -ne 0) { throw 'Docker Compose did not become healthy.' }
    & (Join-Path $PSScriptRoot 'apply-shared-schema.ps1') -Mode Docker -IncludeDevelopmentSeeds
    if ($LASTEXITCODE -ne 0) { throw 'Shared-schema migration failed.' }
    & (Join-Path $PSScriptRoot 'provision-demo-tenants.ps1') -Mode Docker
    if ($LASTEXITCODE -ne 0) { throw 'Demo tenant provisioning failed.' }
    & docker compose --project-directory $root ps
}

Write-Host 'Local setup is ready.' -ForegroundColor Green
