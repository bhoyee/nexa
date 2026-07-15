[CmdletBinding()]
param(
    [string] $Version = '9.1.9',
    [string] $ArchivePath,
    [switch] $Force
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$target = Join-Path $root 'espocrm'
$bootstrapFile = Join-Path $target 'bootstrap.php'
$marker = Join-Path $target '.nexa-source-version'

if ((Test-Path $bootstrapFile) -and -not $Force) {
    $defaults = Join-Path $target 'application\Espo\Resources\defaults\config.php'
    if (-not (Test-Path $defaults) -or -not (Select-String -LiteralPath $defaults -SimpleMatch $Version -Quiet)) {
        throw ('The existing EspoCRM tree is not the required version {0}.' -f $Version)
    }
    Write-Host "EspoCRM source already exists at $target."
    exit 0
}

$temporary = Join-Path ([System.IO.Path]::GetTempPath()) ("nexa-espocrm-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporary | Out-Null

function Copy-UpstreamTree([string] $source) {
    if (-not (Test-Path (Join-Path $source 'bootstrap.php'))) {
        throw "The source at $source is not a packaged EspoCRM application."
    }

    New-Item -ItemType Directory -Path $target -Force | Out-Null
    Get-ChildItem -LiteralPath $source -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force
    }
}

try {
    if ($ArchivePath) {
        $resolvedArchive = (Resolve-Path $ArchivePath).Path
        Expand-Archive -LiteralPath $resolvedArchive -DestinationPath $temporary -Force
        $bootstrap = Get-ChildItem -LiteralPath $temporary -Filter 'bootstrap.php' -File -Recurse | Select-Object -First 1
        if (-not $bootstrap) { throw 'The archive does not contain a packaged EspoCRM application.' }
        Copy-UpstreamTree $bootstrap.Directory.FullName
    }
    else {
        if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
            throw 'Docker is unavailable. Pass -ArchivePath with the packaged EspoCRM 9.1.9 release archive.'
        }

        $image = "espocrm/espocrm:$Version"
        & docker image inspect $image *> $null
        if ($LASTEXITCODE -ne 0) { & docker pull $image; if ($LASTEXITCODE -ne 0) { throw "Could not pull $image." } }

        $container = (& docker create $image).Trim()
        if (-not $container) { throw "Could not create a temporary container from $image." }
        try {
            & docker cp "${container}:/usr/src/espocrm/." $temporary
            if ($LASTEXITCODE -ne 0) { throw 'Could not extract EspoCRM from the temporary container.' }
        }
        finally {
            & docker rm $container *> $null
        }
        Copy-UpstreamTree $temporary
    }

    Set-Content -LiteralPath $marker -Value $Version -Encoding ASCII
    Write-Host "EspoCRM $Version source is ready at $target." -ForegroundColor Green
}
finally {
    if (Test-Path $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
}
