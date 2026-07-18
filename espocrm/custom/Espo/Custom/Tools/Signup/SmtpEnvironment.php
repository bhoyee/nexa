<?php

namespace Espo\Custom\Tools\Signup;

use RuntimeException;

/**
 * Converts the team SMTP environment contract into Espo system-mail config.
 */
final class SmtpEnvironment
{
    /** @return array<string, mixed>|null */
    public static function load(string $path): ?array
    {
        if (!is_file($path)) {
            throw new RuntimeException("Environment file not found: {$path}");
        }

        $values = self::parse((string) file_get_contents($path));
        $host = trim($values['SMTP_HOST'] ?? '');

        // Empty SMTP_HOST deliberately leaves system mail unconfigured for
        // local environments that use the localhost verification fallback.
        if ($host === '') {
            return null;
        }

        $portValue = trim($values['SMTP_PORT'] ?? '587');
        $port = filter_var($portValue, FILTER_VALIDATE_INT, [
            'options' => ['min_range' => 1, 'max_range' => 65535],
        ]);
        if ($port === false) {
            throw new RuntimeException('SMTP_PORT must be an integer from 1 to 65535.');
        }

        $security = strtoupper(trim($values['SMTP_SECURITY'] ?? 'TLS'));
        if (!in_array($security, ['TLS', 'SSL', 'NONE'], true)) {
            throw new RuntimeException('SMTP_SECURITY must be TLS, SSL or NONE.');
        }

        $auth = filter_var(
            $values['SMTP_AUTH'] ?? 'true',
            FILTER_VALIDATE_BOOL,
            FILTER_NULL_ON_FAILURE
        );
        if ($auth === null) {
            throw new RuntimeException('SMTP_AUTH must be true or false.');
        }

        $username = trim($values['SMTP_USERNAME'] ?? '');
        $password = $values['SMTP_PASSWORD'] ?? '';
        if ($auth && ($username === '' || $password === '')) {
            throw new RuntimeException(
                'SMTP_USERNAME and SMTP_PASSWORD are required when SMTP_AUTH is true.'
            );
        }

        $fromAddress = strtolower(trim($values['SMTP_FROM_EMAIL'] ?? ''));
        if (filter_var($fromAddress, FILTER_VALIDATE_EMAIL) === false) {
            throw new RuntimeException('SMTP_FROM_EMAIL must be a valid email address.');
        }

        $fromName = trim($values['SMTP_FROM_NAME'] ?? 'Nexa CRM');
        if ($fromName === '') {
            throw new RuntimeException('SMTP_FROM_NAME cannot be empty.');
        }

        return [
            'smtpServer' => $host,
            'smtpPort' => $port,
            'smtpSecurity' => $security === 'NONE' ? null : $security,
            'smtpAuth' => $auth,
            'smtpUsername' => $auth ? $username : null,
            'smtpPassword' => $auth ? $password : null,
            'outboundEmailFromAddress' => $fromAddress,
            'outboundEmailFromName' => $fromName,
            'outboundEmailIsShared' => true,
        ];
    }

    /** @return array<string, string> */
    private static function parse(string $contents): array
    {
        $values = [];

        foreach (preg_split('/\R/', $contents) ?: [] as $line) {
            $line = trim($line);
            if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) {
                continue;
            }

            [$name, $value] = explode('=', $line, 2);
            $name = trim($name);
            $value = trim($value);
            if (!preg_match('/^[A-Za-z_][A-Za-z0-9_]*$/', $name)) {
                continue;
            }

            if (strlen($value) >= 2) {
                $quote = $value[0];
                if (($quote === '"' || $quote === "'") && str_ends_with($value, $quote)) {
                    $value = substr($value, 1, -1);
                }
            }

            $values[$name] = $value;
        }

        return $values;
    }
}
