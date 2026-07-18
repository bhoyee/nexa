# XAMPP Development Setup

## Purpose

This guide creates a complete Nexa development environment on Windows using
XAMPP Apache/PHP 8.2 and MariaDB 10.11. A successful setup contains the full
tracked application, all 150 current database tables, all migrations, the local
bootstrap administrator, two demo tenants, and tenant-scoped demo CRM records.

No application archive or EspoCRM download is required. Git supplies the exact
application and Nexa code used by the team.

## Required Software

- Git for Windows
- PowerShell 5.1 or later
- XAMPP with PHP 8.2
- MariaDB 10.11 ([Windows MSI archive](https://archive.mariadb.org/mariadb-10.11.16/winx64-packages/mariadb-10.11.16-winx64.msi))

Use the separate MariaDB 10.11 service on port `3306` and keep XAMPP MySQL
stopped. XAMPP's bundled MariaDB 10.4 is not the project database baseline.

Enable these PHP extensions in `C:\xampp\php\php.ini`:

```ini
extension=curl
extension=gd
extension=mbstring
extension=mysqli
extension=openssl
extension=pdo_mysql
extension=zip
```

Use these minimum local installer limits, then restart Apache:

```ini
max_execution_time=180
max_input_time=180
```

## 1. Clone And Prepare

```powershell
Set-Location C:\xampp\htdocs
git clone https://github.com/NaxoCRM-Team/nexa.git
Set-Location nexa

$env:Path = "C:\xampp\php;$env:Path"
powershell -ExecutionPolicy Bypass -File scripts/dev/setup.ps1 -SkipStart
```

The setup command verifies the tracked application and creates an ignored
`.env` with random local credentials. Set this value in `.env`:

```text
ESPOCRM_SITE_URL=http://nexa.local
```

Never commit `.env`. It contains:

- `DB_PASSWORD`: local `espocrm` database-user password.
- `ADMIN_USERNAME` and `ADMIN_PASSWORD`: local bootstrap administrator.
- `DEMO_TENANT_A_ADMIN_*`: Tenant A development login.
- `DEMO_TENANT_B_ADMIN_*`: Tenant B development login.

For real signup email delivery, also configure:

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

Use credentials issued by the selected transactional email provider. The From
address or domain must be verified with that provider. Leave `SMTP_HOST` empty
when local email delivery is intentionally disabled.

## 2. Start MariaDB 10.11

Install the MariaDB MSI with **Database instance**, **Install as service** and
**Enable networking** selected. Locate and verify its client:

```powershell
$candidates = @(
    'C:\Program Files\MariaDB 10.11\bin\mariadb.exe',
    'C:\Program Files\MariaDB 10.11\bin\mysql.exe'
)
$mariadb = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $mariadb) { throw 'MariaDB 10.11 is not installed.' }

& $mariadb --version
Get-Service -Name MariaDB
```

The version must contain `10.11` and the `MariaDB` service must be running.

## 3. Create The Empty Database

Connect with the root password selected during MariaDB installation:

```powershell
& $mariadb -u root -p
```

Use the generated `DB_PASSWORD` from `.env` in place of `<DB_PASSWORD>`:

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

The database must be empty. Do not delete or reuse a database until its contents
and ownership are known.

## 4. Initialize All Tables

Run this once before opening the browser installer:

```powershell
Set-Location C:\xampp\htdocs\nexa
powershell -ExecutionPolicy Bypass -File scripts/dev/initialize-local-database.ps1 `
  -ClientPath $mariadb
```

The command reads `DB_PASSWORD` from the ignored `.env`, loads the pinned base
schema, applies every migration in order, verifies migration checksums, and
registers `nexa.local` for the seeded local tenant. It refuses to initialize a
non-empty database.

Expected result at this stage:

- 150 database tables
- 141 `tenant_id` columns
- 138 `service_id` columns
- 5 applied migrations

## 5. Configure Apache

Confirm these lines are enabled in `C:\xampp\apache\conf\httpd.conf`:

```apache
LoadModule rewrite_module modules/mod_rewrite.so
Include conf/extra/httpd-vhosts.conf
```

Do not add `ClearModuleList` or `AddModule mod_rewrite.c`; those belong to old
Apache versions and are not used by Apache 2.4.

Add this block to `C:\xampp\apache\conf\extra\httpd-vhosts.conf`:

```apache
<VirtualHost *:80>
    ServerName nexa.local
    DocumentRoot "C:/xampp/htdocs/nexa/espocrm"

    <Directory "C:/xampp/htdocs/nexa/espocrm">
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

Start Apache from XAMPP and keep XAMPP MySQL stopped. Check Apache before
continuing:

```powershell
& 'C:\xampp\apache\bin\httpd.exe' -t
& 'C:\xampp\apache\bin\httpd.exe' -M | Select-String rewrite_module
```

## 6. Complete The Browser Installer

Open <http://nexa.local/install/> and use:

| Installer setting | Value |
|---|---|
| Database platform | MySQL/MariaDB |
| Host | `127.0.0.1` |
| Port | `3306` |
| Database | `espocrm` |
| Database user | `espocrm` |
| Database password | `DB_PASSWORD` from `.env` |
| Administrator username | `ADMIN_USERNAME` from `.env` |
| Administrator password | `ADMIN_PASSWORD` from `.env` |

The requested administrator is required to finish the underlying framework. In
Nexa it is the **local bootstrap administrator** assigned to the seeded local
workspace. It is not a customer tenant administrator. Customer tenant admins are
created through signup or tenant provisioning.

Complete every installer page until the success page appears. Do not close the
browser immediately after entering the administrator password.

## 7. Install Demo Tenants And Verify

Run one command after the browser installer succeeds:

```powershell
Set-Location C:\xampp\htdocs\nexa
powershell -ExecutionPolicy Bypass -File scripts/dev/complete-local-setup.ps1 `
  -PhpPath 'C:\xampp\php\php.exe'
```

The command uses the installed application's database connection and the
ignored `.env`. It performs all remaining work:

- validates and applies SMTP settings when `SMTP_HOST` is configured;
- loads development catalog and tenant seeds in order;
- creates or refreshes two separate demo tenant administrators;
- adds accounts, contacts, leads, opportunities, tasks and meetings per tenant;
- rebuilds the application and clears cache;
- checks table, tenant-column, service-column and migration counts;
- proves both demo tenants have administrators and CRM data;
- runs repository verification.

Both demo accounts sign in through <http://nexa.local/?login=1>. Use the
`DEMO_TENANT_A_ADMIN_*` or `DEMO_TENANT_B_ADMIN_*` values from `.env`. The
submitted login identity selects the tenant; separate login domains are not
required.

Reapply SMTP settings after changing `.env`:

```powershell
& 'C:\xampp\php\php.exe' scripts/dev/configure-smtp.php --env=.env
```

The command never prints the SMTP password. Use Administration > Outbound
Emails to send a test message after configuration.

## 8. Configure Scheduled Jobs

Create a Windows Task Scheduler task that runs every minute:

```text
Program: C:\xampp\php\php.exe
Arguments: C:\xampp\htdocs\nexa\espocrm\cron.php
Start in: C:\xampp\htdocs\nexa\espocrm
```

Run the task manually once and inspect `espocrm/data/logs/` if it fails.

## Updating A Checkout

```powershell
Set-Location C:\xampp\htdocs\nexa
git switch main
git pull --ff-only

powershell -ExecutionPolicy Bypass -File scripts/dev/apply-shared-schema.ps1 `
  -Mode Local `
  -ClientPath $mariadb `
  -User espocrm

Set-Location espocrm
& 'C:\xampp\php\php.exe' rebuild.php
& 'C:\xampp\php\php.exe' clear_cache.php

Set-Location ..
powershell -ExecutionPolicy Bypass -File scripts/dev/verify.ps1
```

Do not use `-InitializeBaseSchema` when updating an existing database.

## Common Problems

### API Is Unavailable

Run `httpd.exe -t` and confirm `rewrite_module` is listed. If `/api/v1/` returns
HTTP `401`, rewriting and tenant routing are working; the installer accepts
`200` or `401`. A `403` normally means `nexa.local` was not registered, so rerun
Step 4 only on a fresh database or inspect `nexa_tenant_domain` on an existing
installation.

### Blank Installer Page

Inspect the newest file under `espocrm/data/logs/`. Confirm Step 4 completed
before the browser installer and that the final success page was reached. Run
`verify-local-install.php --before-demo` to check completion:

```powershell
& 'C:\xampp\php\php.exe' scripts/dev/verify-local-install.php --before-demo
```

### MariaDB Will Not Start

Only one database server can use port `3306`. Keep XAMPP MySQL stopped while the
MariaDB 10.11 Windows service is running.

### phpMyAdmin Cannot Connect

phpMyAdmin must target the running MariaDB 10.11 server and use cookie
authentication or valid MariaDB credentials. This does not affect Nexa when the
application connection itself is valid.

### Missing PHP Extensions Or Limits

Edit `C:\xampp\php\php.ini`, restart Apache, and rerun:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/dev/check-environment.ps1
```

## Acceptance Check

The environment is complete only when:

- <http://nexa.local/?login=1> loads;
- `complete-local-setup.ps1` finishes successfully;
- the verifier reports at least 150 tables, 141 tenant columns, 138 service
  columns and all migrations;
- both demo accounts authenticate through the same login page;
- demo CRM records are visible only inside their assigned tenant;
- scheduled jobs run without errors.
