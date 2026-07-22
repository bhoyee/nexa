<?php

declare(strict_types=1);

$root = dirname(__DIR__, 2);
$assert = static function (bool $condition, string $message): void {
    if (!$condition) {
        fwrite(STDERR, '[FAIL] ' . $message . PHP_EOL);
        exit(1);
    }
};

$lock = json_decode((string) file_get_contents($root . '/packages/sso/composer.lock'), true, 512, JSON_THROW_ON_ERROR);
$versions = [];
foreach ($lock['packages'] ?? [] as $package) {
    $versions[$package['name']] = $package['version'];
}
$assert(($versions['onelogin/php-saml'] ?? null) === '4.3.2', 'The audited SAML toolkit version must remain pinned.');
$assert(($versions['robrichards/xmlseclibs'] ?? null) === '3.1.5', 'The patched XML signature library must remain pinned.');

$migration = (string) file_get_contents($root . '/database/shared/migrations/0008_identity_security.sql');
foreach (['nexa_identity_provider', 'nexa_tenant_auth_policy', 'nexa_identity_provider_domain', 'nexa_identity_link_request', 'nexa_mfa_recovery_code'] as $table) {
    $assert(str_contains($migration, 'CREATE TABLE IF NOT EXISTS ' . $table), "Missing identity table {$table}.");
}
$assert(str_contains($migration, 'encrypted_client_secret'), 'Provider secrets must never be stored as plaintext.');
$assert(str_contains($migration, "protocol IN ('oidc', 'saml')"), 'Only approved federation protocols may be configured.');

$sso = (string) file_get_contents($root . '/espocrm/custom/Espo/Custom/Tools/Auth/EnterpriseSsoService.php');
$assert(str_contains($sso, 'rejectUnsolicitedResponsesWithInResponseTo'), 'SAML must reject unsolicited or mismatched responses.');
$assert(str_contains($sso, 'wantAssertionsSigned') && str_contains($sso, "'strict' => true"), 'SAML assertions must be signed and strictly validated.');
$assert(str_contains($sso, 'consumed_at') && str_contains($sso, 'FOR UPDATE'), 'Federated callback state must be consumed atomically.');
$assert(str_contains($sso, 'social_account_not_linked'), 'Unlinked identities must not be matched by email.');
$assert(!str_contains($sso, 'WHERE normalized_email=?'), 'Federated login must never auto-link on email.');

$oidc = (string) file_get_contents($root . '/espocrm/custom/Espo/Custom/Tools/Auth/GenericOidcTokenValidator.php');
foreach (['getIss()', 'getAud()', 'getNonce()', "getAlg() !== 'RS256'", 'validate($token)', '->verify($token)'] as $contract) {
    $assert(str_contains($oidc, $contract), 'OIDC validation contract is incomplete: ' . $contract);
}
$assert(str_contains($oidc, "array_intersect(\$methods, ['mfa', 'otp', 'hwk', 'swk'])"), 'Tenant OIDC MFA policy must validate the amr claim.');
$assert(str_contains($sso, 'requestedAuthnContext'), 'Tenant SAML MFA policy must request an approved authentication context.');
$policyHook = (string) file_get_contents($root . '/espocrm/custom/Espo/Custom/Tools/Auth/TenantAuthPolicyHook.php');
$assert(str_contains($policyHook, 'allow_password_login') && str_contains($policyHook, 'require_mfa'), 'Tenant password and MFA policy hook is incomplete.');

$mfa = (string) file_get_contents($root . '/espocrm/custom/Espo/Custom/Tools/Auth/MfaRecoveryService.php');
$assert(str_contains($mfa, 'password_hash($code, PASSWORD_BCRYPT)'), 'Recovery codes must be irreversibly hashed.');
$assert(str_contains($mfa, 'consumed_at=CURRENT_TIMESTAMP(6)') && str_contains($mfa, 'FOR UPDATE'), 'Recovery codes must be single-use and atomic.');
$lockout = (string) file_get_contents($root . '/espocrm/application/Espo/Core/Authentication/Hook/Hooks/FailedCodeAttemptsLimit.php');
$assert(str_contains($lockout, 'getMaxFailedAttemptNumber'), 'MFA failed-code lockout hook must remain enabled.');

$docs = (string) file_get_contents($root . '/docs/development/identity-provider-testing.md')
    . (string) file_get_contents($root . '/docs/operations/identity-incident-recovery.md');
foreach (['OIDC', 'SAML', 'NEXA_AUTH_SECRET_KEY', 'certificate', 'recovery codes', 'revoke'] as $term) {
    $assert(stripos($docs, $term) !== false, 'Identity operations documentation is missing: ' . $term);
}

$dbName = getenv('NEXA_TEST_DB_NAME');
if ($dbName) {
    $pdo = new PDO(
        'mysql:host=' . (getenv('NEXA_TEST_DB_HOST') ?: '127.0.0.1') . ';dbname=' . $dbName . ';charset=utf8mb4',
        getenv('NEXA_TEST_DB_USER') ?: 'root',
        getenv('NEXA_TEST_DB_PASSWORD') ?: '',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION],
    );
    $tenantA = '30000000-0000-4000-8000-000000000001';
    $providerId = '91000000-0000-4000-8000-000000000001';
    $pdo->prepare(
        'INSERT INTO nexa_identity_provider '
        . '(id,tenant_id,provider_key,protocol,display_name,issuer,allowed_email_domains,attribute_mapping,is_enabled) '
        . 'VALUES (?,?,\'test-oidc\',\'oidc\',\'Test OIDC\',\'https://idp.example.test\',\'["example.test"]\',\'{}\',1)'
    )->execute([$providerId, $tenantA]);
    $pdo->prepare('INSERT INTO nexa_identity_provider_domain (domain_name,tenant_id,provider_id) VALUES (\'example.test\',?,?)')
        ->execute([$tenantA, $providerId]);
    try {
        $pdo->prepare('INSERT INTO nexa_identity_provider_domain (domain_name,tenant_id,provider_id) VALUES (\'example.test\',?,?)')
            ->execute(['30000000-0000-4000-8000-000000000002', $providerId]);
        $assert(false, 'A discovery domain must not be claimable by two tenants.');
    } catch (PDOException) {
        // Expected global domain-ownership constraint.
    }
    $pdo->prepare('INSERT INTO nexa_tenant_auth_policy (tenant_id,require_mfa) VALUES (?,1)')->execute([$tenantA]);

    $state = hash('sha256', 'one-use-state');
    $pdo->prepare(
        'INSERT INTO nexa_social_auth_attempt (id,provider,intent,state_hash,nonce_hash,payload_json,expires_at) '
        . 'VALUES (\'92000000-0000-4000-8000-000000000001\',?,\'login\',?,SHA2(\'nonce\',256),\'{}\',DATE_ADD(NOW(6),INTERVAL 10 MINUTE))'
    )->execute(['oidc:' . $providerId, $state]);
    $first = $pdo->prepare('UPDATE nexa_social_auth_attempt SET consumed_at=NOW(6) WHERE state_hash=? AND consumed_at IS NULL AND expires_at>NOW(6)');
    $first->execute([$state]);
    $assert($first->rowCount() === 1, 'Fresh callback state should be consumable once.');
    $first->execute([$state]);
    $assert($first->rowCount() === 0, 'Replayed callback state must be rejected.');

    $expired = hash('sha256', 'expired-state');
    $pdo->prepare(
        'INSERT INTO nexa_social_auth_attempt (id,provider,intent,state_hash,nonce_hash,payload_json,expires_at) '
        . 'VALUES (\'92000000-0000-4000-8000-000000000002\',?,\'login\',?,SHA2(\'nonce\',256),\'{}\',DATE_SUB(NOW(6),INTERVAL 1 SECOND))'
    )->execute(['oidc:' . $providerId, $expired]);
    $first->execute([$expired]);
    $assert($first->rowCount() === 0, 'Expired callback state must be rejected.');

    $codeHash = password_hash('ABCD-1234-EF56', PASSWORD_BCRYPT);
    $pdo->prepare(
        'INSERT INTO nexa_mfa_recovery_code (id,tenant_id,user_id,code_hash) '
        . 'VALUES (\'93000000-0000-4000-8000-000000000001\',?,\'iso-user-a-000001\',?)'
    )->execute([$tenantA, $codeHash]);
    $consume = $pdo->prepare(
        'UPDATE nexa_mfa_recovery_code SET consumed_at=NOW(6) '
        . 'WHERE id=\'93000000-0000-4000-8000-000000000001\' AND tenant_id=? AND consumed_at IS NULL'
    );
    $consume->execute([$tenantA]);
    $assert($consume->rowCount() === 1, 'Recovery code should be consumable once.');
    $consume->execute([$tenantA]);
    $assert($consume->rowCount() === 0, 'Consumed recovery code must reject replay.');

    $pdo->prepare(
        'INSERT INTO nexa_audit_event (id,tenant_id,actor_type,action,subject_type,source,metadata_json) '
        . 'VALUES (\'94000000-0000-4000-8000-000000000001\',?,\'system\',\'auth.test.callback\',\'identity-provider\',\'contract-test\',\'{}\')'
    )->execute([$tenantA]);
    $assert((int) $pdo->query("SELECT COUNT(*) FROM nexa_audit_event WHERE action='auth.test.callback'")->fetchColumn() === 1, 'Authentication outcomes must be auditable.');
}

fwrite(STDOUT, 'Identity security contract suite passed.' . PHP_EOL);
