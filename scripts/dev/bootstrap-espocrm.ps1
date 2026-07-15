[CmdletBinding()]
param(
    [string] $Version = '9.1.9',
    [string] $ArchivePath,
    [switch] $Download,
    [switch] $Force
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$target = Join-Path $root 'espocrm'
$bootstrapFile = Join-Path $target 'bootstrap.php'
$marker = Join-Path $target '.nexa-source-version'
$downloads = Join-Path $root 'downloads'

$releasePackages = @{
    '9.1.9' = @{
        Url = 'https://github.com/espocrm/espocrm/releases/download/9.1.9/EspoCRM-9.1.9.zip'
        Sha256 = 'fa846ee8e5e684255b05def8cc38ee0a027831f7af251e6d59e628ff3ee65646'
    }
}

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

function Expand-ApplicationArchive([string] $path) {
    Expand-Archive -LiteralPath $path -DestinationPath $temporary -Force
    $bootstrap = Get-ChildItem -LiteralPath $temporary -Filter 'bootstrap.php' -File -Recurse | Select-Object -First 1
    if (-not $bootstrap) { throw 'The archive does not contain a packaged EspoCRM application.' }
    Copy-UpstreamTree $bootstrap.Directory.FullName
}

function Get-VerifiedReleaseArchive {
    if (-not $releasePackages.ContainsKey($Version)) {
        throw "No verified application package is configured for version $Version."
    }

    $release = $releasePackages[$Version]
    New-Item -ItemType Directory -Path $downloads -Force | Out-Null
    $archive = Join-Path $downloads "EspoCRM-$Version.zip"
    $partial = "$archive.part"

    if (Test-Path $archive) {
        $existingHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($existingHash -eq $release.Sha256) {
            Write-Host "Using verified cached package $archive."
            return $archive
        }
        throw "The cached package checksum is invalid: $archive. Remove it and run setup again."
    }

    Write-Host "Downloading the approved EspoCRM $Version application package..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $release.Url -OutFile $partial
        $actualHash = (Get-FileHash -LiteralPath $partial -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -ne $release.Sha256) {
            throw "Downloaded package checksum mismatch. Expected $($release.Sha256), received $actualHash."
        }
        Move-Item -LiteralPath $partial -Destination $archive -Force
    }
    finally {
        if (Test-Path $partial) { Remove-Item -LiteralPath $partial -Force }
    }

    Write-Host "Verified SHA-256 $($release.Sha256)."
    return $archive
}

try {
    if ($ArchivePath) {
        $resolvedArchive = (Resolve-Path $ArchivePath).Path
        Expand-ApplicationArchive $resolvedArchive
    }
    elseif ($Download -or -not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Expand-ApplicationArchive (Get-VerifiedReleaseArchive)
    }
    else {
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
