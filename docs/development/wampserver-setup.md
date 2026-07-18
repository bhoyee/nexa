# WampServer Development Setup

## Purpose

This guide creates the same complete Nexa development environment as Docker and
XAMPP while using WampServer Apache/PHP 8.2 and MariaDB 10.11. The repository
already contains the full application; no separate EspoCRM download is needed.

A completed setup contains all 150 current tables, all tenant and service
columns, every migration, the local bootstrap administrator, two demo tenants,
and tenant-scoped demo CRM data.

## Required Software

- Git for Windows
- PowerShell 5.1 or later
- WampServer with Apache and PHP 8.2
- MariaDB 10.11 available through WampServer or a separate Windows service

The Apache PHP version and command-line PHP version must both be 8.2.x. Enable
`curl`, `gd`, `mbstring`, `mysqli`, `openssl`, `pdo_mysql` and `zip`. Set
`max_execution_time` and `max_input_time` to at least `180`, then restart all
WampServer services.

## 1. Clone And Prepare

```powershell
Set-Location C:\wamp64\www
git clone https://github.com/NaxoCRM-Team/nexa.git
Set-Location nexa

$php = 'C:\wamp64\bin\php\php8.2.x\php.exe'
$env:Path = (Split-Path $php) + ';' + $env:Path
powershell -ExecutionPolicy Bypass -File scripts/dev/setup.ps1 -SkipStart
```

Replace `php8.2.x` with the installed WampServer folder. Set this value in the
ignored `.env`:

```text
ESPOCRM_SITE_URL=http://nexa.local
```

The ignored `.env` stores the database password, local bootstrap administrator,
and separate Tenant A and Tenant B demo credentials. Never commit it.

For real signup verification delivery, add provider-issued SMTP values:

```dotenv
SMTP_HOST=smtp.provider.example
SMTP_PORT=587
SMTP_SECURITY=TLS
SMTP_AUTH=true
SMTP_USERNAME=provider-user
SMTP_PASSWORD=provider-password
SMTP_FROM_EMAIL=verified-sender@example.com
SMTP_FROM_NAME=Nexa CRM
```

The From address or domain must be verified by the selected provider. Leave
`SMTP_HOST` empty when local delivery is intentionally disabled.

## 2. Select MariaDB 10.11

Use the WampServer tray menu to activate MariaDB 10.11, or run a separate
MariaDB 10.11 Windows service. Do not let another MySQL/MariaDB service compete
for the same port.

Locate and verify the client:

```powershell
Get-ChildItem C:\wamp64\bin\mariadb -Directory
$mariadb = 'C:\wamp64\bin\mariadb\mariadb10.11.x\bin\mariadb.exe'
& $mariadb --version
```

The output must report MariaDB 10.11.x.

## 3. Create The Empty Database

```powershell
& $mariadb -u root -p
```

Use `DB_PASSWORD` from `.env` in place of `<DB_PASSWORD>`:

```sql
CREATE DATABASE espocrm
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'espocrm'@'localhost' IDENTIFIED BY '<DB_PASSWORD>';
CREATE USER IF NOT EXISTS 'espocrm'@'127.0.0.1' IDENTIFIED BY '<DB_PASSWORD>';
GRANT ALL PRIVILEGES ON espocrm.* TO 'espocrm'@'localhost';
GRANT ALL PRIVILEGES ON espocrm.* TO 'espocrm'@'127.0.0.1';
FLUSH PRIVILEGES;
```

The database must be empty. Do not delete or reuse an unknown database.

## 4. Initialize All Tables

Run this before opening the browser installer:

```powershell
Set-Location C:\wamp64\www\nexa
powershell -ExecutionPolicy Bypass -File scripts/dev/initialize-local-database.ps1 `
  -ClientPath $mariadb
```

The command reads `DB_PASSWORD` from `.env`, loads the pinned base schema,
applies every migration in order, verifies checksums, and registers
`nexa.local`. It refuses to initialize a non-empty database.

Expected result: at least 150 tables, 141 tenant columns, 138 service columns,
and all five current migrations.

## 5. Configure Apache

Enable `mod_rewrite` from the WampServer tray menu. Add the virtual host through
WampServer's **Add a Virtual Host** interface or use the equivalent configuration:

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

Restart all WampServer services. Do not add obsolete Apache directives such as
`ClearModuleList` or `AddModule mod_rewrite.c`.

## 6. Complete The Browser Installer

Open <http://nexa.local/install/> and use:

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

The administrator requested here is the **local bootstrap administrator** needed
by the underlying framework. It is assigned to the seeded local workspace and
is not a customer tenant administrator. Customer tenant administrators are
created through signup or tenant provisioning.

Complete every page until the installer success page appears.

## 7. Install Demo Tenants And Verify

Run one command after browser installation:

```powershell
Set-Location C:\wamp64\www\nexa
powershell -ExecutionPolicy Bypass -File scripts/dev/complete-local-setup.ps1 `
  -PhpPath $php
```

This command uses the installed application's database connection and `.env` to:

- validate and apply SMTP settings when `SMTP_HOST` is configured;
- load development seeds in dependency order;
- provision both demo tenant administrators;
- create tenant-scoped accounts, contacts, leads, opportunities, tasks and meetings;
- rebuild and clear cache;
- verify table, tenant-column, service-column and migration counts;
- prove that both tenants have administrators and CRM data;
- run repository verification.

Both tenants sign in through <http://nexa.local/?login=1>. Use the
`DEMO_TENANT_A_ADMIN_*` or `DEMO_TENANT_B_ADMIN_*` values from `.env`.

Reapply SMTP settings after editing `.env`:

```powershell
& $php scripts/dev/configure-smtp.php --env=.env
```

The command never prints the SMTP password. Send a test message from
Administration > Outbound Emails after configuration.

## 8. Configure Scheduled Jobs

Create a Windows Task Scheduler task that runs every minute:

```text
Program: C:\wamp64\bin\php\php8.2.x\php.exe
Arguments: C:\wamp64\www\nexa\espocrm\cron.php
Start in: C:\wamp64\www\nexa\espocrm
```

Run it manually once and inspect `espocrm/data/logs/` if it fails.

## Updating A Checkout

```powershell
Set-Location C:\wamp64\www\nexa
git switch main
git pull --ff-only

powershell -ExecutionPolicy Bypass -File scripts/dev/apply-shared-schema.ps1 `
  -Mode Local `
  -ClientPath $mariadb `
  -User espocrm

Set-Location espocrm
& $php rebuild.php
& $php clear_cache.php

Set-Location ..
powershell -ExecutionPolicy Bypass -File scripts/dev/verify.ps1
```

Do not use `-InitializeBaseSchema` on an existing database.

## Common Problems

### API Is Unavailable

Confirm `mod_rewrite`, `AllowOverride All`, and the hosts entry. HTTP `401` from
`/api/v1/` means rewriting and tenant routing work; the installer accepts `200`
or `401`. HTTP `403` normally means the local tenant host was not registered.

### Blank Installer Page

Inspect the newest file in `espocrm/data/logs/`. Confirm Step 4 completed before
the browser installer. Check browser completion with:

```powershell
& $php scripts/dev/verify-local-install.php --before-demo
```

### Wrong PHP Version

The tray-selected Apache PHP and `$php -v` must both report PHP 8.2.x with the
required extensions.

### Database Connection Fails

Confirm MariaDB 10.11 is running, no other database server owns its port, and
the `espocrm` user has privileges on the `espocrm` database.

### Migration Checksum Mismatch

Do not edit an applied migration. Pull the reviewed repository state and add a
new forward migration for further changes.

## Acceptance Check

WampServer setup is complete only when:

- <http://nexa.local/?login=1> loads;
- `complete-local-setup.ps1` passes;
- validation reports at least 150 tables, 141 tenant columns, 138 service
  columns and all migrations;
- both demo accounts authenticate on the same login page;
- each tenant sees only its own CRM data;
- scheduled jobs run without errors.
