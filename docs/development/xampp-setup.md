# XAMPP Development Setup

## Purpose

This guide gives a designated Nexa team member a repeatable Windows environment using XAMPP Apache/PHP and MariaDB 10.11. It produces the same application release, Nexa custom code and database definitions as the Docker workflow while keeping local credentials and records independent.

## Required Software

- Git for Windows
- PowerShell 5.1 or later
- XAMPP with PHP 8.2
- MariaDB 10.11

Required PHP extensions are `curl`, `json`, `mbstring`, `openssl`, `pdo_mysql` and `zip`.

Do not use an upgrade archive as the application package. Do not use XAMPP MariaDB 10.4 as the compatibility baseline.

## Installation

### Clone

```powershell
Set-Location C:\xampp\htdocs
git clone https://github.com/bhoyee/nexa.git
Set-Location nexa
```

### Prepare Files

Run:

```powershell
$env:Path = "C:\xampp\php;$env:Path"
powershell -ExecutionPolicy Bypass -File scripts/dev/setup.ps1 `
  -SkipStart
```

The complete application tree and Nexa changes are already in the clone. The command creates local environment settings and must report that version 9.1.9 and the required extensions pass. Update `ESPOCRM_SITE_URL` in the generated `.env` to `http://nexa.local`.

Local `data/` configuration, caches, logs, temporary files, uploads and credentials remain untracked. The verified download option in `bootstrap-espocrm.ps1` is for recovery only and must not replace the versioned team code during normal setup.

### Create Database

Start the MariaDB 10.11 service and connect as its administrator:

```powershell
& 'C:\Program Files\MariaDB 10.11\bin\mariadb.exe' -u root -p
```

Use the generated `DB_PASSWORD` value:

```sql
CREATE DATABASE espocrm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'espocrm'@'localhost' IDENTIFIED BY '<DB_PASSWORD>';
GRANT ALL PRIVILEGES ON espocrm.* TO 'espocrm'@'localhost';
FLUSH PRIVILEGES;
```

If the database or user already exists, stop and determine whether it belongs to an earlier local installation. Do not delete an unknown database.

### Configure Apache

Enable `mod_rewrite` and virtual hosts in `C:\xampp\apache\conf\httpd.conf`:

```apache
LoadModule rewrite_module modules/mod_rewrite.so
Include conf/extra/httpd-vhosts.conf
```

Add to `C:\xampp\apache\conf\extra\httpd-vhosts.conf`:

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

Add `127.0.0.1 nexa.local` to the Windows hosts file as Administrator. Start Apache and confirm <http://nexa.local/install> loads.

### Install Application

Use database host `127.0.0.1`, database `espocrm`, user `espocrm` and the generated `DB_PASSWORD`. Use the generated `ADMIN_USERNAME` and `ADMIN_PASSWORD` for the local administrator.

After browser installation:

```powershell
Set-Location C:\xampp\htdocs\nexa\espocrm
& 'C:\xampp\php\php.exe' rebuild.php
& 'C:\xampp\php\php.exe' clear_cache.php

Set-Location C:\xampp\htdocs\nexa
powershell -ExecutionPolicy Bypass -File scripts/dev/verify.ps1
```

## Scheduled Jobs

Create a Windows Task Scheduler task that runs every minute:

```text
Program: C:\xampp\php\php.exe
Arguments: C:\xampp\htdocs\nexa\espocrm\cron.php
Start in: C:\xampp\htdocs\nexa\espocrm
```

Run the task once manually and inspect `espocrm/data/logs/` if it fails. Logs are local runtime data and must not be committed.

## Database Collaboration

- Each developer maintains a separate local `espocrm` database.
- Never exchange full database dumps for daily synchronization.
- Espo entity structure moves through custom metadata and rebuild.
- Nexa schema changes move through immutable files under `database/`.
- Approved test records move through synthetic seed files.
- Real names, emails, credentials and customer records must never appear in fixtures.

## Updating a Local Checkout

```powershell
git switch main
git pull --ff-only

Set-Location espocrm
& 'C:\xampp\php\php.exe' rebuild.php
& 'C:\xampp\php\php.exe' clear_cache.php

Set-Location ..
powershell -ExecutionPolicy Bypass -File scripts/dev/verify.ps1
```

Read each pull request for migration and backfill instructions before applying it locally.

## Common Problems

### Blank Page

- Confirm Apache `mod_rewrite` is enabled.
- Confirm the virtual host has `AllowOverride All`.
- Inspect Apache error logs and `espocrm/data/logs/`.
- Run rebuild and clear cache again.

### Database Connection Fails

- Confirm MariaDB 10.11 is running.
- Confirm XAMPP MySQL is not competing for the same port.
- Confirm host, port, database, user and password.
- Test with the MariaDB CLI using the same application user.

### PHP Extension Missing

Enable the extension in `C:\xampp\php\php.ini`, restart Apache and rerun `scripts/dev/check-environment.ps1`.

### Local Data Needs Reset

Do not drop databases casually. Confirm the database name and create a backup when records matter. A destructive reset must be intentional and affects only that developer's local environment.

## Acceptance Check

The XAMPP environment is ready when:

- `http://nexa.local` loads and login succeeds.
- Accounts, Contacts, Leads and Opportunities open.
- Rebuild and cache clearing complete without errors.
- The scheduled job runs.
- `scripts/dev/verify.ps1` passes.
- `git status --short` contains no generated or secret files.
