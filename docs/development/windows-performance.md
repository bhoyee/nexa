# Windows Development Performance

Native XAMPP or WampServer is the reference fast path on Windows. It uses PHP 8.2, MariaDB 10.11, the same migrations and the same synthetic tenants as Docker without Windows bind-mount translation.

## Reference Check

Complete the local setup, enable PHP OPcache, exclude only the repository runtime cache and database data directories from real-time antivirus scanning when company policy permits, and stop unused web/database containers. Then run:

```powershell
.\scripts\dev\measure-local-performance.ps1 -BaseUrl http://nexa.local
```

The command performs one cold warm-up followed by five measured requests. The shared login p95 must remain at or below two seconds. When demo credentials are present only in the ignored `.env`, it also checks the authenticated tenant API without printing credentials.

## Reference Evidence

On 18 July 2026 the native XAMPP path completed five warm requests with a shared-login average of 0.231 seconds and p95 of 0.274 seconds. The authenticated tenant API averaged 0.710 seconds with p95 of 0.746 seconds. Static, login and API routes returned their expected status codes and no new application error was logged. The earlier Docker bind-mount baseline was 2.15 to 5.44 seconds for the PHP login entry, so native XAMPP is the supported reference path for this Windows machine.

## Diagnostics

- Static assets fast but PHP slow: confirm OPcache is enabled for Apache and restart Apache.
- All requests slow: check antivirus activity, DNS/hosts resolution and competing Apache or database services.
- Intermittent requests exceed ten seconds: inspect `espocrm/data/logs`, confirm MariaDB health and stop unrelated containers.
- Authenticated API only is slow: inspect tenant query plans and background jobs rather than increasing PHP timeouts.

Notification polling uses a 30-second interval so a normal request completes before the next idle poll. Performance failures are fixed at their source; PHP execution limits are not raised to hide repeated timeouts.

## Recovery

Performance configuration does not change tenant data. Restore the previous Apache `php.ini`, restart Apache and rerun the command. For schema or application failures, restore the database backup taken before migrations and check `nexa_schema_migration` before retrying.
