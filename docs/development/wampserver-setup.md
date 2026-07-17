# WampServer Development Setup

## Purpose

This guide gives a Nexa team member a repeatable Windows environment using WampServer Apache/PHP and MariaDB 10.11. WampServer is only a local web-server launcher; it uses the same repository, application code, database schema, migrations and verification commands as Docker and XAMPP.

A clone contains the complete application. Do not download a separate EspoCRM archive.

## Required Software

- Git for Windows.
- PowerShell 5.1 or later.
- WampServer 64-bit.
- PHP 8.2.x enabled in WampServer.
- MariaDB 10.11.

Required PHP extensions are `curl`, `json`, `mbstring`, `openssl`, `pdo_mysql` and `zip`.

WampServer package versions vary. If its bundled MariaDB is not 10.11, add a compatible MariaDB 10.11 version to WampServer or install MariaDB 10.11 separately. Do not silently use another database version as the project baseline.

## 1. Clone The Organization Repository

```powershell
Set-Location C:\wamp64\www
git clone https://github.com/NaxoCRM-Team/nexa.git
Set-Location nexa
```

The clone includes the complete application under `espocrm/`, including `application/`, `client/`, `custom/`, `install/`, `public/` and `vendor/`, together with all Nexa changes and shared-schema migrations.

## 2. Select PHP 8.2

Use the WampServer tray menu to select PHP 8.2.x, then restart all WampServer services.

Locate the matching CLI executable. The exact minor-version directory may differ:

```powershell
Get-ChildItem C:\wamp64\bin\php -Directory
$php = 'C:\wamp64\bin\php\php8.2.x\php.exe'
& $php -v
```

Confirm the required extensions:

```powershell
& $php -m
```

Temporarily add that PHP directory to the current terminal and prepare the repository without starting Docker:

```powershell
$env:Path = (Split-Path $php) + ";$env:Path"
powershell -ExecutionPolicy Bypass -File scripts/dev/setup.ps1 -SkipStart
```

Update the ignored `.env` file:

```text
ESPOCRM_SITE_URL=http://nexa.local
```

Never commit `.env`.

## 3. Configure MariaDB 10.11

Use the WampServer tray menu to confirm MariaDB 10.11 is active. If a separate MariaDB 10.11 Windows service is used, stop the conflicting WampServer MySQL/MariaDB service or configure distinct ports.

Locate the MariaDB client. A WampServer installation commonly uses a path similar to:

```powershell
Get-ChildItem C:\wamp64\bin\mariadb -Directory
$mariadb = 'C:\wamp64\bin\mariadb\mariadb10.11.x\bin\mariadb.exe'
& $mariadb --version
```

Connect as the local database administrator:

```powershell
& $mariadb -u root -p
```

Create the independent local database and application user. Replace `<DB_PASSWORD>` with `DB_PASSWORD` from `.env`:

```sql
CREATE DATABASE espocrm
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER 'espocrm'@'localhost'
    IDENTIFIED BY '<DB_PASSWORD>';

GRANT ALL PRIVILEGES ON espocrm.*
    TO 'espocrm'@'localhost';

FLUSH PRIVILEGES;
```

If the database or user already exists, stop and determine whether it belongs to a previous installation. Do not delete an unknown database.

## 4. Configure Apache Virtual Host

Enable Apache `mod_rewrite` from the WampServer tray menu.

Use WampServer's **Add a Virtual Host** interface or add an equivalent virtual host configuration:

```apache
<VirtualHost *:80>
    ServerName nexa.local
    DocumentRoot "C:/wamp64/www/nexa/espocrm"

    <Directory "C:/wamp64/www/nexa/espocrm">
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

Add this entry to `C:\Windows\System32\drivers\etc\hosts` as Administrator:

```text
127.0.0.1 nexa.local
```

Restart all WampServer services. Open <http://nexa.local/install>.

## 5. Complete Browser Installation

Use these installer values:

| Installer setting | Value |
|---|---|
| Database platform | MySQL/MariaDB |
| Host | `127.0.0.1` |
| Port | MariaDB 10.11 port, normally `3306` |
| Database | `espocrm` |
| Database user | `espocrm` |
| Database password | `DB_PASSWORD` from `.env` |
| Administrator username | `ADMIN_USERNAME` from `.env` |
| Administrator password | `ADMIN_PASSWORD` from `.env` |

The browser installer creates the pinned EspoCRM 9.1.9 baseline tables.

## 6. Apply The Nexa Shared Schema

Run the same checksum-aware migration tool used by Docker and XAMPP. It prompts for the `espocrm` database user's password:

```powershell
Set-Location C:\wamp64\www\nexa
powershell -ExecutionPolicy Bypass -File scripts/dev/apply-shared-schema.ps1 `
  -Mode Local `
  -ClientPath $mariadb `
  -Database espocrm `
  -User espocrm `
  -IncludeDevelopmentSeeds
```

This applies the Nexa foundation and mass tenant expansion, records migration checksums and skips migrations already applied.

Provision the two local demo workspaces, their separate administrators and their tenant-scoped CRM fixtures. The command prompts for the two passwords stored in the ignored `.env` file:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/dev/provision-demo-tenants.ps1 `
  -Mode Local `
  -PhpPath $php
```

## 7. Rebuild And Verify

```powershell
Set-Location C:\wamp64\www\nexa\espocrm
& $php rebuild.php
& $php clear_cache.php

Set-Location C:\wamp64\www\nexa
powershell -ExecutionPolicy Bypass -File scripts/dev/check-environment.ps1
powershell -ExecutionPolicy Bypass -File scripts/dev/verify.ps1
```

Open <http://nexa.local>, sign in and confirm Accounts, Contacts, Leads and Opportunities load.

## 8. Configure Scheduled Jobs

Create a Windows Task Scheduler task that runs every minute:

```text
Program: C:\wamp64\bin\php\php8.2.x\php.exe
Arguments: C:\wamp64\www\nexa\espocrm\cron.php
Start in: C:\wamp64\www\nexa\espocrm
```

Run it manually once and inspect `espocrm/data/logs/` if it fails.

## Updating A Local Checkout

```powershell
Set-Location C:\wamp64\www\nexa
git switch main
git pull --ff-only

powershell -ExecutionPolicy Bypass -File scripts/dev/apply-shared-schema.ps1 `
  -Mode Local `
  -ClientPath $mariadb `
  -Database espocrm `
  -User espocrm

Set-Location espocrm
& $php rebuild.php
& $php clear_cache.php

Set-Location ..
powershell -ExecutionPolicy Bypass -File scripts/dev/verify.ps1
```

## Database Collaboration Rules

- Each developer has an independent local `espocrm` database.
- Database structure moves through `database/shared/migrations/`.
- Safe reference data moves through synthetic seeds.
- Never exchange live database files or full development dumps for routine collaboration.
- Never commit credentials, personal data, customer records, logs, cache, uploads or attachments.

## Common Problems

### Apache Shows A Blank Or Forbidden Page

- Confirm the virtual host points to `C:/wamp64/www/nexa/espocrm`.
- Confirm `mod_rewrite` is enabled.
- Confirm `AllowOverride All` and `Require all granted` are active.
- Restart all WampServer services and inspect Apache and Espo logs.

### Wrong PHP Version

The tray-selected Apache PHP and terminal PHP must both be 8.2.x. Run `& $php -v` and make sure `$env:Path` starts with the same PHP directory.

### Database Connection Fails

- Confirm MariaDB 10.11 is running.
- Confirm MySQL and MariaDB are not competing for port 3306.
- Confirm the application user has privileges on `espocrm`.
- Run `& $mariadb --version` and test the same host, port and user manually.

### Migration Checksum Mismatch

Do not edit a migration already applied. Pull the reviewed repository state and resolve the mismatch through a new forward migration.

## Acceptance Check

WampServer setup is complete when:

- <http://nexa.local> loads and login works.
- PHP reports 8.2.x with all required extensions.
- MariaDB reports 10.11.x.
- `apply-shared-schema.ps1` reports migrations current.
- Repository verification passes.
- Scheduled jobs run without errors.
