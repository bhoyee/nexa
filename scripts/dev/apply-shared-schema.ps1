[CmdletBinding()]
param(
    [ValidateSet('Docker', 'Local')]
    [string] $Mode = 'Docker',
    [string] $Database = 'espocrm',
    [string] $ClientPath = 'mariadb',
    [string] $DatabaseHost = '127.0.0.1',
    [int] $Port = 3306,
    [string] $User = 'root',
    [string] $EnvironmentFile = '.env',
    [switch] $InitializeBaseSchema,
    [switch] $IncludeDevelopmentSeeds
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$migrationRoot = Join-Path $root 'database\shared\migrations'
$seedRoot = Join-Path $root 'database\shared\seeds'
$baseSchema = Join-Path $root 'database\shared\testing\0000_espocrm_9_1_9_schema.sql'
$localPassword = $null
$previousMysqlPassword = [Environment]::GetEnvironmentVariable('MYSQL_PWD', 'Process')

function Read-EnvironmentFile([string] $Path) {
    $values = @{}

    if (-not (Test-Path -LiteralPath $Path)) { return $values }

    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^\s*#' -or $line -notmatch '^\s*([A-Za-z_][A-Za-z0-9_]*)=(.*)$') { continue }
        $values[$matches[1]] = $matches[2].Trim().Trim('"').Trim("'")
    }

    return $values
}

function Read-PlainTextPassword([string] $Prompt) {
    $securePassword = Read-Host $Prompt -AsSecureString
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)

    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
}

function Resolve-LocalMariaDbClient([string] $RequestedClient) {
    $command = Get-Command $RequestedClient -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $candidates = @(
        'C:\Program Files\MariaDB 10.11\bin\mariadb.exe',
        'C:\Program Files\MariaDB 10.11\bin\mysql.exe'
    )
    $installed = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($installed) { return $installed }

    throw "MariaDB 10.11 client not found. Install the Windows x64 MSI with a database instance, or pass its executable with -ClientPath. XAMPP's bundled MariaDB 10.4 is not supported."
}

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
        $ClientPath = Resolve-LocalMariaDbClient $ClientPath
        $clientVersion = (& $ClientPath --version 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -ne 0 -or $clientVersion -notmatch 'Distrib 10\.11|\b10\.11\.') {
            throw "Unsupported database client: $clientVersion. Nexa local development requires MariaDB 10.11.x."
        }
        Write-Host "Using $ClientPath ($clientVersion)" -ForegroundColor DarkGray
        $environmentPath = if ([IO.Path]::IsPathRooted($EnvironmentFile)) {
            $EnvironmentFile
        } else {
            Join-Path $root $EnvironmentFile
        }
        $environment = Read-EnvironmentFile $environmentPath
        $passwordName = if ($User -eq 'espocrm') { 'DB_PASSWORD' } elseif ($User -eq 'root') { 'DB_ROOT_PASSWORD' } else { $null }
        $localPassword = if ($passwordName -and $environment.ContainsKey($passwordName)) {
            $environment[$passwordName]
        } elseif ($previousMysqlPassword) {
            $previousMysqlPassword
        } else {
            Read-PlainTextPassword "MariaDB password for $User"
        }

        if ([string]::IsNullOrWhiteSpace($localPassword)) {
            throw "No MariaDB password is available for $User. Add $passwordName to the ignored .env file or enter it when prompted."
        }

        $env:MYSQL_PWD = $localPassword
    }

    if ($InitializeBaseSchema) {
        $tableCount = @((Invoke-Query "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$Database';"))[0]

        if ([int] $tableCount -ne 0) {
            throw "Base-schema initialization requires an empty database. '$Database' currently contains $tableCount tables."
        }

        Write-Host '[BASE] EspoCRM 9.1.9 schema' -ForegroundColor Cyan
        Invoke-SqlFile (Get-Item -LiteralPath $baseSchema)
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

    if ($InitializeBaseSchema -and $Mode -eq 'Local') {
        $localHostSql = @"
INSERT INTO $Database.nexa_tenant_domain
    (id, tenant_id, hostname, domain_type, verification_status, is_primary, verified_at)
VALUES
    ('00000000-0000-4000-8100-000000000003',
     '00000000-0000-4000-8000-000000000001',
     'nexa.local', 'local', 'verified', 0, CURRENT_TIMESTAMP(6))
ON DUPLICATE KEY UPDATE
    tenant_id = VALUES(tenant_id),
    domain_type = VALUES(domain_type),
    verification_status = VALUES(verification_status),
    verified_at = VALUES(verified_at);
"@
        Invoke-Query $localHostSql | Out-Null
        Write-Host '[LOCAL] nexa.local tenant host' -ForegroundColor Cyan
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
        if ($null -eq $previousMysqlPassword) {
            Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
        } else {
            $env:MYSQL_PWD = $previousMysqlPassword
        }
        $localPassword = $null
    }
}
