[CmdletBinding()]
param([switch] $Ci)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$failures = New-Object System.Collections.Generic.List[string]

function Fail([string] $message) {
    $script:failures.Add($message)
    Write-Host "[FAIL] $message" -ForegroundColor Red
}

function Pass([string] $message) {
    Write-Host "[PASS] $message" -ForegroundColor Green
}

$required = @(
    '.env.example', '.gitattributes', '.gitignore', '.github/CODEOWNERS',
    '.github/workflows/release.yml', 'CHANGELOG.md', 'CONTRIBUTING.md', 'SECURITY.md', 'VERSION',
    'docs/development/delivery-management.md', 'docs/development/wampserver-setup.md',
    'compose.yaml', 'scripts/dev/apply-shared-schema.ps1', 'scripts/dev/provision-demo-tenants.ps1',
    'database/shared/testing/0000_espocrm_9_1_9_schema.sql',
    'database/shared/migrations/0001_initial_shared_saas.sql', 'database/shared/migrations/0002_expand_espocrm_tenant_scope.sql',
    'database/shared/migrations/0003_enforce_tenant_runtime.sql', 'database/shared/migrations/0004_tenant_qualified_user_identity.sql',
    'database/shared/seeds/0002_two_tenant_isolation.sql', 'espocrm/bin/provision-demo-tenants.php',
    'database/shared/table-ownership-manifest.json', 'espocrm/application/Espo/Resources/tenant-table-ownership.json',
    'tests/tenant/TenantRuntimeTest.php',
    'espocrm/bootstrap.php', 'espocrm/application/Espo/Core/Application.php',
    'espocrm/client/lib/espo-main.js', 'espocrm/client/res/templates/login.tpl',
    'espocrm/install/entry.php', 'espocrm/public/index.php', 'espocrm/vendor/autoload.php'
)
foreach ($relative in $required) {
    if (Test-Path (Join-Path $root $relative)) { Pass "$relative exists" } else { Fail "$relative is missing" }
}

$jsonFiles = Get-ChildItem -LiteralPath (Join-Path $root 'espocrm\custom'), (Join-Path $root 'espocrm\client\custom') -Filter '*.json' -File -Recurse -ErrorAction SilentlyContinue
foreach ($file in $jsonFiles) {
    try { Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json | Out-Null; Pass "JSON $($file.Name)" }
    catch { Fail "Invalid JSON: $($file.FullName)" }
}

$ownershipManifest = Join-Path $root 'database\shared\table-ownership-manifest.json'
try {
    $manifest = Get-Content -LiteralPath $ownershipManifest -Raw | ConvertFrom-Json
    if ($manifest.unclassifiedBehavior -ne 'deny') { Fail 'Table ownership manifest must deny unclassified tables.' }
    elseif ($manifest.tables.Count -lt 1) { Fail 'Table ownership manifest has no classified tables.' }
    elseif ($manifest.espoCoreConversion.tenantScopedTableCount -ne 133) { Fail 'Espo tenant table inventory must contain 133 tables.' }
    else {
        Pass 'Shared-schema table ownership manifest'
        $runtimeOwnership = Get-Content -LiteralPath (Join-Path $root 'espocrm/application/Espo/Resources/tenant-table-ownership.json') -Raw | ConvertFrom-Json
        $expected = @($manifest.espoCoreConversion.tenantScopedTables | Sort-Object)
        $actual = @($runtimeOwnership.tenantScopedTables | Sort-Object)
        if (Compare-Object $expected $actual) { Fail 'Runtime tenant ownership metadata differs from the database manifest.' }
        else { Pass 'Runtime tenant ownership metadata' }
    }
} catch {
    Fail "Invalid table ownership manifest: $ownershipManifest"
}
$php = Get-Command php -ErrorAction SilentlyContinue
$phpRoots = @(
    (Join-Path $root 'espocrm\custom'),
    (Join-Path $root 'espocrm\client\custom'),
    (Join-Path $root 'espocrm\application\Espo\Core\Tenant')
)
$phpFiles = Get-ChildItem -LiteralPath $phpRoots -Filter '*.php' -File -Recurse -ErrorAction SilentlyContinue
$phpFiles += Get-Item -LiteralPath (Join-Path $root 'espocrm\bin\provision-demo-tenants.php')
if ($php) {
    foreach ($file in $phpFiles) {
        & php -l $file.FullName *> $null
        if ($LASTEXITCODE -eq 0) { Pass "PHP $($file.Name)" } else { Fail "PHP syntax: $($file.FullName)" }
    }
} elseif ($phpFiles.Count -gt 0) {
    Fail 'PHP is required to lint product PHP files.'
}

if ($php) {
    & php (Join-Path $root 'tests\tenant\TenantRuntimeTest.php')
    if ($LASTEXITCODE -eq 0) { Pass 'Tenant runtime isolation suite' } else { Fail 'Tenant runtime isolation suite failed.' }
}

$tracked = & git -C $root ls-files
foreach ($prohibited in @('.env', '.env.local', 'espocrm/data/config.php', 'espocrm/data/config-internal.php')) {
    if ($tracked -contains $prohibited) { Fail "$prohibited must not be tracked" }
}
if (-not ($tracked -contains '.env')) { Pass '.env is not tracked' }

$shareablePaths = & git -C $root ls-files --cached --others --exclude-standard
$textExtensions = @('.css', '.env', '.example', '.html', '.ini', '.js', '.json', '.md', '.php', '.ps1', '.sh', '.sql', '.txt', '.xml', '.yaml', '.yml')
$shareableTextFiles = $shareablePaths |
    ForEach-Object { Join-Path $root $_ } |
    Where-Object { (Test-Path -LiteralPath $_ -PathType Leaf) -and ($textExtensions -contains [System.IO.Path]::GetExtension($_).ToLowerInvariant()) }
$privateKeyFiles = @()
# The pinned vendor snapshot is audited at import; scan product and team-owned text on every run.
$keyMarkerTextFiles = $shareableTextFiles | Where-Object {
    $_ -notmatch '[\\/]espocrm[\\/]vendor[\\/]'
}
if ($keyMarkerTextFiles) {
    $privateKeyFiles = Select-String -LiteralPath $keyMarkerTextFiles -Pattern 'BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY' -List
}
$keyFileExtensions = @('.key', '.pem', '.p12', '.pfx')
$keyFiles = $shareablePaths |
    ForEach-Object { Join-Path $root $_ } |
    Where-Object { (Test-Path -LiteralPath $_ -PathType Leaf) -and ($keyFileExtensions -contains [System.IO.Path]::GetExtension($_).ToLowerInvariant()) }
if ($privateKeyFiles -or $keyFiles) { Fail 'A private key or key file exists in a shareable path.' } else { Pass 'No private keys found' }

$migrationNames = Get-ChildItem -LiteralPath (Join-Path $root 'database') -Filter '*.sql' -File -Recurse | Select-Object -ExpandProperty Name
foreach ($name in $migrationNames) {
    if ($name -notmatch '^\d{4}_[a-z0-9_]+\.sql$') { Fail "Migration/seed filename is not canonical: $name" }
}

if (-not $Ci -and (Get-Command docker -ErrorAction SilentlyContinue)) {
    & docker compose --project-directory $root config --quiet
    if ($LASTEXITCODE -eq 0) { Pass 'Compose configuration' } else { Fail 'Compose configuration is invalid' }
}

if ($failures.Count -gt 0) {
    Write-Host "$($failures.Count) verification check(s) failed." -ForegroundColor Red
    exit 1
}

Write-Host 'Repository verification passed.' -ForegroundColor Green
