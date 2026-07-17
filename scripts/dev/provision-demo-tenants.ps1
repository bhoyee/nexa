[CmdletBinding()]
param(
    [ValidateSet('Docker', 'Local')]
    [string] $Mode = 'Docker',
    [string] $PhpPath = 'php',
    [string] $TenantAUserName = 'demo-admin',
    [string] $TenantBUserName = 'demo-admin-b'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$environmentNames = @(
    'NEXA_TENANT_A_ADMIN_USERNAME',
    'NEXA_TENANT_A_ADMIN_PASSWORD',
    'NEXA_TENANT_B_ADMIN_USERNAME',
    'NEXA_TENANT_B_ADMIN_PASSWORD'
)
$previousEnvironment = @{}
foreach ($name in $environmentNames) {
    $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}

function Read-PlainTextPassword([string] $Prompt) {
    $securePassword = Read-Host $Prompt -AsSecureString
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)

    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}

try {
    if ($TenantAUserName -eq $TenantBUserName) {
        throw 'Tenant A and Tenant B demo administrator usernames must be different.'
    }

    if ($Mode -eq 'Docker') {
        if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
            throw 'Docker is unavailable.'
        }

        & docker compose --project-directory $root exec -T `
            -e "NEXA_TENANT_A_ADMIN_USERNAME=$TenantAUserName" `
            -e "NEXA_TENANT_B_ADMIN_USERNAME=$TenantBUserName" `
            espocrm php bin/provision-demo-tenants.php

        if ($LASTEXITCODE -ne 0) {
            throw 'Demo tenant administrator provisioning failed.'
        }

        return
    }

    if (-not (Get-Command $PhpPath -ErrorAction SilentlyContinue)) {
        throw "PHP executable not found: $PhpPath"
    }

    $env:NEXA_TENANT_A_ADMIN_USERNAME = $TenantAUserName
    $env:NEXA_TENANT_A_ADMIN_PASSWORD = Read-PlainTextPassword 'Tenant A administrator password'
    $env:NEXA_TENANT_B_ADMIN_USERNAME = $TenantBUserName
    $env:NEXA_TENANT_B_ADMIN_PASSWORD = Read-PlainTextPassword 'Tenant B administrator password'

    & $PhpPath (Join-Path $root 'espocrm\bin\provision-demo-tenants.php')

    if ($LASTEXITCODE -ne 0) {
        throw 'Demo tenant administrator provisioning failed.'
    }
}
finally {
    foreach ($name in $environmentNames) {
        [Environment]::SetEnvironmentVariable($name, $previousEnvironment[$name], 'Process')
    }
}
