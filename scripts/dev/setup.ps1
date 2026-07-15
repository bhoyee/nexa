[CmdletBinding()]
param(
    [string] $ArchivePath,
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
    Set-Content -LiteralPath $envPath -Value $content -Encoding ASCII
    Write-Host 'Created .env with local random credentials. Do not commit it.' -ForegroundColor Green
}
else {
    Write-Host 'Keeping the existing .env file.'
}

$bootstrap = Join-Path $PSScriptRoot 'bootstrap-espocrm.ps1'
if ($ArchivePath) { & $bootstrap -ArchivePath $ArchivePath } else { & $bootstrap }

& (Join-Path $PSScriptRoot 'check-environment.ps1')

if (-not $SkipStart) {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw 'Docker is unavailable. Use -SkipStart for an XAMPP setup.'
    }
    & docker compose --project-directory $root up -d
    if ($LASTEXITCODE -ne 0) { throw 'Docker Compose did not start successfully.' }
    & docker compose --project-directory $root ps
}

Write-Host 'Local setup is ready.' -ForegroundColor Green
