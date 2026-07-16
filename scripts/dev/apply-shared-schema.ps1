[CmdletBinding()]
param(
    [ValidateSet('Docker', 'Local')]
    [string] $Mode = 'Docker',
    [string] $Database = 'espocrm',
    [string] $ClientPath = 'mariadb',
    [string] $DatabaseHost = '127.0.0.1',
    [int] $Port = 3306,
    [string] $User = 'root',
    [switch] $IncludeDevelopmentSeeds
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$migrationRoot = Join-Path $root 'database\shared\migrations'
$seedRoot = Join-Path $root 'database\shared\seeds'
$localPassword = $null

function Invoke-DockerQuery([string] $Sql) {
    $output = @($Sql | docker compose --project-directory $root exec -T database sh -lc 'mariadb --user=root --password="$MARIADB_ROOT_PASSWORD" --batch --skip-column-names')
    if ($LASTEXITCODE -ne 0) { throw 'Docker MariaDB query failed.' }
    return $output
}

function Invoke-DockerFile([IO.FileInfo] $File) {
    $command = 'mariadb --user=root --password="$MARIADB_ROOT_PASSWORD" ' + $Database
    Get-Content -LiteralPath $File.FullName -Raw | docker compose --project-directory $root exec -T database sh -lc $command
    if ($LASTEXITCODE -ne 0) { throw "Migration failed: $($File.Name)" }
}

function Get-LocalArguments([switch] $SkipDatabase) {
    $arguments = @('--batch', '--skip-column-names', "--host=$DatabaseHost", "--port=$Port", "--user=$User")
    if (-not $SkipDatabase) { $arguments += $Database }
    return $arguments
}

function Invoke-LocalQuery([string] $Sql) {
    $output = @($Sql | & $ClientPath @(Get-LocalArguments -SkipDatabase))
    if ($LASTEXITCODE -ne 0) { throw 'Local MariaDB query failed.' }
    return $output
}

function Invoke-LocalFile([IO.FileInfo] $File) {
    Get-Content -LiteralPath $File.FullName -Raw | & $ClientPath @(Get-LocalArguments)
    if ($LASTEXITCODE -ne 0) { throw "Migration failed: $($File.Name)" }
}

function Invoke-Query([string] $Sql) {
    if ($Mode -eq 'Docker') { return Invoke-DockerQuery $Sql }
    return Invoke-LocalQuery $Sql
}

function Invoke-SqlFile([IO.FileInfo] $File) {
    if ($Mode -eq 'Docker') { Invoke-DockerFile $File; return }
    Invoke-LocalFile $File
}

try {
    if ($Mode -eq 'Docker') {
        if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Docker is unavailable.' }
        & docker compose --project-directory $root up -d database
        if ($LASTEXITCODE -ne 0) { throw 'The Docker database service did not start.' }
    }
    else {
        if (-not (Get-Command $ClientPath -ErrorAction SilentlyContinue)) { throw "MariaDB client not found: $ClientPath" }
        $securePassword = Read-Host "MariaDB password for $User" -AsSecureString
        $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        try { $localPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
        $env:MYSQL_PWD = $localPassword
    }

    $migrations = @(Get-ChildItem -LiteralPath $migrationRoot -Filter '*.sql' -File | Sort-Object Name)
    foreach ($migration in $migrations) {
        $checksum = (Get-FileHash -LiteralPath $migration.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        $trackingExists = @((Invoke-Query "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$Database' AND table_name='nexa_schema_migration';"))[0] -eq '1'
        if ($trackingExists) {
            $stored = @((Invoke-Query "SELECT checksum_sha256 FROM $Database.nexa_schema_migration WHERE migration_id='$($migration.Name)';"))
            if ($stored.Count -gt 0) {
                if ($stored[0] -ne $checksum) { throw "Checksum mismatch for applied migration $($migration.Name)." }
                Write-Host "[SKIP] $($migration.Name)" -ForegroundColor DarkGray
                continue
            }
        }

        Write-Host "[APPLY] $($migration.Name)" -ForegroundColor Cyan
        $started = Get-Date
        Invoke-SqlFile $migration
        $elapsed = [int]((Get-Date) - $started).TotalMilliseconds
        $trackingSql = "INSERT INTO $Database.nexa_schema_migration (migration_id, checksum_sha256, execution_ms, applied_by) VALUES ('$($migration.Name)', '$checksum', $elapsed, '$($Mode.ToLowerInvariant())') ON DUPLICATE KEY UPDATE checksum_sha256=VALUES(checksum_sha256), execution_ms=VALUES(execution_ms), applied_at=CURRENT_TIMESTAMP(6), applied_by=VALUES(applied_by);"
        Invoke-Query $trackingSql | Out-Null
    }

    if ($IncludeDevelopmentSeeds) {
        foreach ($seed in @(Get-ChildItem -LiteralPath $seedRoot -Filter '*.sql' -File | Sort-Object Name)) {
            Write-Host "[SEED] $($seed.Name)" -ForegroundColor Yellow
            Invoke-SqlFile $seed
        }
    }

    Write-Host 'Shared-schema database migrations are current.' -ForegroundColor Green
}
finally {
    if ($Mode -eq 'Local') {
        Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
        $localPassword = $null
    }
}
