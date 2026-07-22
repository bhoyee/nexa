<?php

declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/espocrm/custom/Espo/Custom/Tools/Auth/AuthProviderRegistry.php';

use Espo\Custom\Tools\Auth\AuthProviderRegistry;

$assert = static function (bool $condition, string $message): void {
    if (!$condition) {
        fwrite(STDERR, '[FAIL] ' . $message . PHP_EOL);
        exit(1);
    }
};

$assert(AuthProviderRegistry::normalize([]) === [], 'Providers must be hidden by default.');
$assert(AuthProviderRegistry::normalize(['google' => false]) === [], 'Disabled providers must be hidden.');

$providers = AuthProviderRegistry::normalize([
    'google' => true,
    'unknown' => true,
]);
$assert(count($providers) === 1, 'Only allow-listed enabled providers may be published.');
$assert($providers[0]['key'] === 'google', 'Google provider metadata is missing.');
$assert(
    $providers[0]['startUrl'] === '/api/v1/Nexa/auth/provider/google/start',
    'Provider entry point must remain behind the M04 contract.'
);

$signupSource = file_get_contents(
    dirname(__DIR__, 2) . '/espocrm/custom/Espo/Custom/Tools/Signup/SignupService.php'
);
$assert(str_contains($signupSource, 'random_int(0, 99999999)'), 'Verification must use an eight-digit random code.');
$assert(str_contains($signupSource, "INTERVAL 15 MINUTE"), 'Resent codes must expire after 15 minutes.');
$assert(
    str_contains($signupSource, 'strtolower($email)') && str_contains($signupSource, '$code'),
    'Code digests must be bound to email.'
);

$recoverySource = file_get_contents(
    dirname(__DIR__, 2) . '/espocrm/custom/Espo/Custom/Tools/Auth/RecoveryService.php'
);
$assert(str_contains($recoverySource, 'If the details match an account'), 'Recovery response must be neutral.');
$assert(str_contains($recoverySource, 'count($rows) !== 1'), 'Recovery must require one unambiguous tenant identity.');

$tenantResolverSource = file_get_contents(
    dirname(__DIR__, 2) . '/espocrm/application/Espo/Core/Tenant/TenantResolver.php'
);
$assert(
    str_contains($tenantResolverSource, 'resolvePasswordChangeRequest'),
    'Shared-domain password reset must resolve tenant from its opaque request ID.'
);

fwrite(STDOUT, 'Authentication experience contract suite passed.' . PHP_EOL);
