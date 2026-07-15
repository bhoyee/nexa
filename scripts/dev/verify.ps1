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
    '.env.example', '.gitattributes', '.gitignore', 'CONTRIBUTING.md', 'SECURITY.md',
    'compose.yaml', 'database/control-plane/migrations/0001_initial_control_plane.sql',
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

$php = Get-Command php -ErrorAction SilentlyContinue
$phpFiles = Get-ChildItem -LiteralPath (Join-Path $root 'espocrm\custom'), (Join-Path $root 'espocrm\client\custom') -Filter '*.php' -File -Recurse -ErrorAction SilentlyContinue
if ($php) {
    foreach ($file in $phpFiles) {
        & php -l $file.FullName *> $null
        if ($LASTEXITCODE -eq 0) { Pass "PHP $($file.Name)" } else { Fail "PHP syntax: $($file.FullName)" }
    }
} elseif ($phpFiles.Count -gt 0) {
    Fail 'PHP is required to lint custom PHP files.'
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
