function Get-NexaMariaDbVersion([string] $VersionText, [string] $Component = 'MariaDB') {
    if ($VersionText -notmatch '(?i)(?<major>\d+)\.(?<minor>\d+)(?:\.\d+)?-MariaDB') {
        throw "$Component is not a recognizable MariaDB version: $VersionText"
    }

    return [pscustomobject]@{
        Major = [int] $matches['major']
        Minor = [int] $matches['minor']
        Text = $VersionText
    }
}

function Assert-NexaMariaDbVersion([string] $VersionText, [string] $Component = 'MariaDB') {
    $version = Get-NexaMariaDbVersion $VersionText $Component
    $supported = ($version.Major -eq 10 -and $version.Minor -ge 11) -or $version.Major -eq 11

    if (-not $supported) {
        throw "$Component version is unsupported: $VersionText. Nexa supports MariaDB 10.11.x and 11.x."
    }

    return $version
}
