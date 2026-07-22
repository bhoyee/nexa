<?php

namespace Espo\Custom\Tools\Auth;

use DateTimeImmutable;
use Espo\Core\Authentication\AuthToken\Data as AuthTokenData;
use Espo\Core\Authentication\AuthToken\Manager as AuthTokenManager;
use Espo\Core\Authentication\Jwt\Token;
use Espo\Core\Authentication\Jwt\Validator;
use Espo\Core\Authentication\Oidc\TokenValidator;
use Espo\Core\Tenant\TenantContext;
use Espo\Core\Tenant\TenantContextStore;
use Espo\Core\Utils\Config;
use Espo\ORM\EntityManager;
use PDO;
use RuntimeException;
use Throwable;

/**
 * Completes Google OIDC without trusting provider email as an account-link key.
 * Only a stored provider subject may sign in to an existing Nexa user.
 */
final class SocialAuthService
{
    private const CRM_SERVICE_ID = '20000000-0000-4000-8000-000000000001';

    public function __construct(
        private Config $config,
        private EntityManager $entityManager,
        private Validator $jwtValidator,
        private TokenValidator $tokenValidator,
        private AuthTokenManager $authTokenManager,
        private TenantContextStore $tenantContextStore,
        private AuthProviderRegistry $providerRegistry,
    ) {}

    /** @param array<string, string|array<scalar, mixed>> $query */
    public function start(string $provider, array $query): string
    {
        $this->assertProvider($provider);
        $intent = ($query['intent'] ?? 'login') === 'signup' ? 'signup' : 'login';
        $payload = ['intent' => $intent];

        if ($intent === 'signup') {
            $company = trim((string) ($query['company'] ?? ''));
            $plan = trim((string) ($query['plan'] ?? 'growth'));
            $terms = ($query['terms'] ?? '') === '1';
            if (mb_strlen($company) < 2 || mb_strlen($company) > 120 || !$terms) {
                throw new RuntimeException('Complete the company and terms fields before continuing with Google.');
            }
            $payload += [
                'company' => $company,
                'plan' => $plan,
                'timezone' => trim((string) ($query['timezone'] ?? 'UTC')) ?: 'UTC',
            ];
        }

        $state = $this->randomUrlToken();
        $nonce = $this->randomUrlToken();
        $pdo = $this->entityManager->getPDO();
        $statement = $pdo->prepare(
            'INSERT INTO nexa_social_auth_attempt (id, provider, intent, state_hash, nonce_hash, payload_json, expires_at) '
            . 'VALUES (?, ?, ?, ?, ?, ?, DATE_ADD(CURRENT_TIMESTAMP(6), INTERVAL 10 MINUTE))'
        );
        $statement->execute([
            $this->uuid(), $provider, $intent, hash('sha256', $state), hash('sha256', $nonce),
            json_encode($payload, JSON_THROW_ON_ERROR),
        ]);

        return 'https://accounts.google.com/o/oauth2/v2/auth?' . http_build_query([
            'client_id' => $this->clientId(),
            'redirect_uri' => $this->callbackUrl($provider),
            'response_type' => 'code',
            'scope' => 'openid email profile',
            'state' => $state,
            'nonce' => $nonce,
            'prompt' => 'select_account',
        ]);
    }

    public function callback(string $provider, string $state, string $code): string
    {
        $this->assertProvider($provider);
        if ($state === '' || $code === '') {
            return $this->failureUrl('provider_cancelled');
        }

        try {
            $attempt = $this->consumeAttempt($provider, $state);
            $rawToken = $this->exchangeCode($code, $provider);
            $token = Token::create($rawToken);
            $this->jwtValidator->validate($token);
            $this->tokenValidator->validateFields($token);
            $this->tokenValidator->validateSignature($token);

            $claims = $token->getPayload();
            if (!in_array($claims->getIss(), ['https://accounts.google.com', 'accounts.google.com'], true) ||
                !hash_equals($attempt['nonce_hash'], hash('sha256', (string) $claims->getNonce())) ||
                $claims->get('email_verified') !== true) {
                throw new RuntimeException('Google identity validation failed.');
            }

            $profile = [
                'subject' => (string) $claims->getSub(),
                'email' => strtolower(trim((string) $claims->get('email'))),
                'firstName' => trim((string) $claims->get('given_name')),
                'lastName' => trim((string) $claims->get('family_name')),
                'picture' => trim((string) $claims->get('picture')),
            ];
            if (!filter_var($profile['email'], FILTER_VALIDATE_EMAIL) || $profile['subject'] === '') {
                throw new RuntimeException('Google did not return a verified email identity.');
            }

            $identity = $attempt['intent'] === 'signup'
                ? $this->signup($provider, $profile, $attempt['payload'])
                : $this->findIdentity($provider, $profile['subject']);

            if ($identity === null) {
                return $this->failureUrl('social_account_not_linked');
            }

            return $this->sessionUrl($identity);
        } catch (Throwable) {
            return $this->failureUrl('social_auth_failed');
        }
    }

    /** @return array{intent:string,nonce_hash:string,payload:array<string,mixed>} */
    private function consumeAttempt(string $provider, string $state): array
    {
        $pdo = $this->entityManager->getPDO();
        $pdo->beginTransaction();
        try {
            $statement = $pdo->prepare(
                'SELECT * FROM nexa_social_auth_attempt WHERE provider = ? AND state_hash = ? FOR UPDATE'
            );
            $statement->execute([$provider, hash('sha256', $state)]);
            $row = $statement->fetch(PDO::FETCH_ASSOC);
            if (!$row || $row['consumed_at'] !== null || new DateTimeImmutable($row['expires_at']) < new DateTimeImmutable()) {
                throw new RuntimeException('OAuth state is invalid or expired.');
            }
            $pdo->prepare('UPDATE nexa_social_auth_attempt SET consumed_at = CURRENT_TIMESTAMP(6) WHERE id = ?')
                ->execute([$row['id']]);
            $pdo->commit();
            return [
                'intent' => $row['intent'],
                'nonce_hash' => $row['nonce_hash'],
                'payload' => (array) json_decode($row['payload_json'], true, 512, JSON_THROW_ON_ERROR),
            ];
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            throw $e;
        }
    }

    private function exchangeCode(string $code, string $provider): string
    {
        $curl = curl_init('https://oauth2.googleapis.com/token');
        curl_setopt_array($curl, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 15,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => http_build_query([
                'client_id' => $this->clientId(),
                'client_secret' => $this->clientSecret(),
                'code' => $code,
                'grant_type' => 'authorization_code',
                'redirect_uri' => $this->callbackUrl($provider),
            ]),
            CURLOPT_HTTPHEADER => ['Content-Type: application/x-www-form-urlencoded'],
            CURLOPT_PROTOCOLS => CURLPROTO_HTTPS,
        ]);
        $response = curl_exec($curl);
        $status = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        $error = curl_error($curl);
        curl_close($curl);
        $data = is_string($response) ? json_decode($response, true) : null;
        if ($error !== '' || $status !== 200 || !is_array($data) || !is_string($data['id_token'] ?? null)) {
            throw new RuntimeException('Google token exchange failed.');
        }
        return $data['id_token'];
    }

    /** @param array<string,string> $profile @param array<string,mixed> $payload */
    private function signup(string $provider, array $profile, array $payload): ?array
    {
        $existing = $this->findIdentity($provider, $profile['subject']);
        if ($existing !== null) return $existing;

        $pdo = $this->entityManager->getPDO();
        $emailCheck = $pdo->prepare('SELECT 1 FROM nexa_tenant_owner_identity WHERE normalized_email = ? LIMIT 1');
        $emailCheck->execute([$profile['email']]);
        if ($emailCheck->fetchColumn()) {
            // Never link a Google subject to a password account based on email alone.
            throw new RuntimeException('An account already uses this email. Sign in with its existing method.');
        }
        $planStatement = $pdo->prepare('SELECT id FROM nexa_plan_definition WHERE plan_key = ? AND status = \'active\'');
        $planStatement->execute([(string) ($payload['plan'] ?? 'growth')]);
        $planId = $planStatement->fetchColumn();
        if (!$planId) throw new RuntimeException('The selected plan is unavailable.');

        $tenantId = $this->uuid();
        $userId = $this->entityId();
        $ownerId = $this->uuid();
        $company = trim((string) ($payload['company'] ?? ''));
        $slug = $this->slug($company);
        $now = (new DateTimeImmutable())->format('Y-m-d H:i:s.u');
        $trialEnd = (new DateTimeImmutable('+14 days'))->format('Y-m-d H:i:s.u');
        $profileJson = json_encode($profile, JSON_THROW_ON_ERROR);

        $pdo->beginTransaction();
        try {
            $this->sql($pdo, 'INSERT INTO nexa_tenant (id, slug, display_name, status, timezone) VALUES (?, ?, ?, \'active\', ?)', [$tenantId, $slug, $company, (string) ($payload['timezone'] ?? 'UTC')]);
            $this->sql($pdo, 'INSERT INTO nexa_tenant_subscription (id, tenant_id, plan_id, status, period_starts_at, trial_ends_at) VALUES (?, ?, ?, \'trialing\', ?, ?)', [$this->uuid(), $tenantId, $planId, $now, $trialEnd]);
            $this->sql($pdo, 'INSERT INTO nexa_tenant_service (tenant_id, service_id, status, soft_limit_override, hard_limit_override, configuration_json, starts_at) SELECT ?, service_id, IF(is_enabled = 1, \'active\', \'disabled\'), soft_limit, hard_limit, configuration_json, ? FROM nexa_plan_service WHERE plan_id = ?', [$tenantId, $now, $planId]);
            $this->sql($pdo, 'INSERT INTO `user` (id, deleted, user_name, type, password, first_name, last_name, is_active, created_at, modified_at, delete_id, tenant_id, service_id) VALUES (?, 0, ?, \'admin\', ?, ?, ?, 1, ?, ?, \'0\', ?, ?)', [$userId, $profile['email'], password_hash(bin2hex(random_bytes(32)), PASSWORD_BCRYPT), $profile['firstName'], $profile['lastName'], $now, $now, $tenantId, self::CRM_SERVICE_ID]);
            $emailId = $this->entityId();
            $this->sql($pdo, 'INSERT INTO email_address (id, name, deleted, `lower`, invalid, opt_out, tenant_id, service_id) VALUES (?, ?, 0, ?, 0, 0, ?, ?)', [$emailId, $profile['email'], $profile['email'], $tenantId, self::CRM_SERVICE_ID]);
            $this->sql($pdo, 'INSERT INTO entity_email_address (entity_id, email_address_id, entity_type, `primary`, deleted, tenant_id, service_id) VALUES (?, ?, \'User\', 1, 0, ?, ?)', [$userId, $emailId, $tenantId, self::CRM_SERVICE_ID]);
            $this->sql($pdo, 'INSERT INTO nexa_tenant_owner_identity (id, tenant_id, owner_user_id, email, normalized_email, status, verified_at) VALUES (?, ?, ?, ?, ?, \'active\', CURRENT_TIMESTAMP(6))', [$ownerId, $tenantId, $userId, $profile['email'], $profile['email']]);
            $this->sql($pdo, 'INSERT INTO nexa_provisioning_operation (id, tenant_id, operation_type, status, idempotency_key, attempt_count, completed_at) VALUES (?, ?, \'social_signup\', \'completed\', ?, 1, CURRENT_TIMESTAMP(6))', [$this->uuid(), $tenantId, 'social-signup:' . $ownerId]);
            $this->sql($pdo, 'INSERT INTO nexa_external_identity (id, tenant_id, user_id, provider, provider_subject, normalized_email, profile_json, last_login_at) VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP(6))', [$this->uuid(), $tenantId, $userId, $provider, $profile['subject'], $profile['email'], $profileJson]);
            $pdo->commit();
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            throw $e;
        }

        return ['tenant_id' => $tenantId, 'slug' => $slug, 'display_name' => $company, 'user_id' => $userId, 'user_name' => $profile['email']];
    }

    /** @return array<string,string>|null */
    private function findIdentity(string $provider, string $subject): ?array
    {
        $statement = $this->entityManager->getPDO()->prepare(
            'SELECT i.tenant_id, i.user_id, u.user_name, t.slug, t.display_name FROM nexa_external_identity i '
            . 'JOIN nexa_tenant t ON t.id = i.tenant_id JOIN `user` u ON u.id = i.user_id AND u.tenant_id = i.tenant_id '
            . 'WHERE i.provider = ? AND i.provider_subject = ? AND t.status = \'active\' AND u.is_active = 1 AND u.deleted = 0'
        );
        $statement->execute([$provider, $subject]);
        $identity = $statement->fetch(PDO::FETCH_ASSOC);
        if (!$identity) return null;
        $this->entityManager->getPDO()->prepare('UPDATE nexa_external_identity SET last_login_at = CURRENT_TIMESTAMP(6) WHERE provider = ? AND provider_subject = ?')->execute([$provider, $subject]);
        return $identity;
    }

    /** @param array<string,string> $identity */
    private function sessionUrl(array $identity): string
    {
        $context = new TenantContext($identity['tenant_id'], $identity['slug'], 'google-social-auth', $identity['display_name']);
        $token = $this->tenantContextStore->runWith($context, fn () => $this->authTokenManager->create(
            AuthTokenData::create(['userId' => $identity['user_id']])
        ));
        $this->sql(
            $this->entityManager->getPDO(),
            'INSERT INTO nexa_audit_event (id, tenant_id, service_id, actor_type, actor_user_id, action, subject_type, subject_id, source, metadata_json) VALUES (?, ?, ?, \'user\', ?, \'auth.social.login\', \'user\', ?, \'google-oidc\', JSON_OBJECT())',
            [$this->uuid(), $identity['tenant_id'], self::CRM_SERVICE_ID, $identity['user_id'], $identity['user_id']]
        );
        $payload = rtrim(strtr(base64_encode(json_encode([
            'userName' => $identity['user_name'], 'token' => $token->getToken(),
        ], JSON_THROW_ON_ERROR)), '+/', '-_'), '=');
        return rtrim((string) $this->config->get('siteUrl'), '/') . '/?login=1#nexa-social=' . $payload;
    }

    private function failureUrl(string $reason): string
    {
        return rtrim((string) $this->config->get('siteUrl'), '/') . '/?login=1&socialError=' . rawurlencode($reason);
    }

    private function assertProvider(string $provider): void
    {
        $enabled = array_column($this->providerRegistry->getPublicProviders(), 'key');
        if ($provider !== 'google' || !in_array($provider, $enabled, true)) {
            throw new RuntimeException('This identity provider is not configured.');
        }
    }

    private function callbackUrl(string $provider): string
    {
        $configured = trim((string) (getenv('NEXA_AUTH_GOOGLE_REDIRECT_URI') ?: $this->config->get('nexaGoogleRedirectUri', '')));
        return $configured !== ''
            ? $configured
            : rtrim((string) $this->config->get('siteUrl'), '/') . '/api/v1/Nexa/auth/provider/' . $provider . '/callback';
    }

    private function clientId(): string { return trim((string) (getenv('NEXA_AUTH_GOOGLE_CLIENT_ID') ?: $this->config->get('oidcClientId', ''))); }
    private function clientSecret(): string { return trim((string) (getenv('NEXA_AUTH_GOOGLE_CLIENT_SECRET') ?: $this->config->get('oidcClientSecret', ''))); }
    private function randomUrlToken(): string { return rtrim(strtr(base64_encode(random_bytes(32)), '+/', '-_'), '='); }
    private function entityId(): string { return substr(bin2hex(random_bytes(9)), 0, 17); }
    private function slug(string $company): string { return substr(strtolower(trim((string) preg_replace('/[^a-z0-9]+/i', '-', $company), '-')) ?: 'workspace', 0, 54) . '-' . bin2hex(random_bytes(4)); }
    private function uuid(): string { $b = random_bytes(16); $b[6] = chr((ord($b[6]) & 15) | 64); $b[8] = chr((ord($b[8]) & 63) | 128); return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($b), 4)); }
    /** @param list<mixed> $params */
    private function sql(PDO $pdo, string $sql, array $params): void { $statement = $pdo->prepare($sql); $statement->execute($params); }
}
