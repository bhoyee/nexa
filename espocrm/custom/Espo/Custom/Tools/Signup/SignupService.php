<?php

namespace Espo\Custom\Tools\Signup;

use DateTimeImmutable;
use Espo\Core\Utils\Config;
use Espo\ORM\EntityManager;
use PDO;
use PDOException;
use Throwable;

/**
 * Owns the self-service tenant lifecycle.
 *
 * Platform tables and tenant-owned Espo records are written through one PDO
 * transaction so a workspace can never exist without its owner and plan.
 */
final class SignupService
{
    private const CRM_SERVICE_ID = '20000000-0000-4000-8000-000000000001';

    public function __construct(
        private EntityManager $entityManager,
        private Config $config,
        private SignupValidator $validator,
        private SignupMailer $mailer,
    ) {}

    /**
     * Creates an inactive tenant and owner, ready for email verification.
     *
     * @return array<string, mixed>
     */
    public function register(object $input, string $fingerprint): array
    {
        $data = $this->validator->validate($input);
        $pdo = $this->entityManager->getPDO();
        $this->enforceRateLimit($pdo, $fingerprint, 'register', 5);

        $plan = $this->findPlan($pdo, $data['plan']);
        $this->assertEmailAvailable($pdo, $data['email']);

        $tenantId = $this->uuid();
        $ownerId = $this->uuid();
        $userId = $this->entityId();
        $emailId = $this->entityId();
        $operationId = $this->uuid();
        $code = $this->verificationCode();
        $tokenHash = $this->codeHash($data['email'], $code);
        $slug = $this->slug($data['company']);
        $now = (new DateTimeImmutable())->format('Y-m-d H:i:s.u');
        $trialEnd = (new DateTimeImmutable('+14 days'))->format('Y-m-d H:i:s.u');
        $verificationEnd = (new DateTimeImmutable('+15 minutes'))->format('Y-m-d H:i:s.u');

        // Tenant, subscription, entitlements and owner identity form one unit.
        // Any failure rolls back the complete workspace rather than leaving partial data.
        try {
            $pdo->beginTransaction();

            $this->insert($pdo,
                'INSERT INTO nexa_tenant (id, slug, display_name, status, timezone) VALUES (?, ?, ?, ?, ?)',
                [$tenantId, $slug, $data['company'], 'pending_verification', $data['timezone']]
            );
            $this->insert($pdo,
                'INSERT INTO nexa_tenant_subscription (id, tenant_id, plan_id, status, period_starts_at, trial_ends_at) VALUES (?, ?, ?, ?, ?, ?)',
                [$this->uuid(), $tenantId, $plan['id'], 'trialing', $now, $trialEnd]
            );
            $this->insert($pdo,
                'INSERT INTO nexa_tenant_service (tenant_id, service_id, status, soft_limit_override, hard_limit_override, configuration_json, starts_at) SELECT ?, service_id, IF(is_enabled = 1, \'active\', \'disabled\'), soft_limit, hard_limit, configuration_json, ? FROM nexa_plan_service WHERE plan_id = ?',
                [$tenantId, $now, $plan['id']]
            );
            $this->insert($pdo,
                'INSERT INTO `user` (id, deleted, user_name, type, password, first_name, last_name, is_active, created_at, modified_at, delete_id, tenant_id, service_id) VALUES (?, 0, ?, \'admin\', ?, ?, ?, 0, ?, ?, \'0\', ?, ?)',
                [$userId, $data['email'], password_hash($data['password'], PASSWORD_BCRYPT), $data['firstName'], $data['lastName'], $now, $now, $tenantId, self::CRM_SERVICE_ID]
            );
            $this->insert($pdo,
                'INSERT INTO email_address (id, name, deleted, `lower`, invalid, opt_out, tenant_id, service_id) VALUES (?, ?, 0, ?, 0, 0, ?, ?)',
                [$emailId, $data['email'], $data['email'], $tenantId, self::CRM_SERVICE_ID]
            );
            $this->insert($pdo,
                'INSERT INTO entity_email_address (entity_id, email_address_id, entity_type, `primary`, deleted, tenant_id, service_id) VALUES (?, ?, \'User\', 1, 0, ?, ?)',
                [$userId, $emailId, $tenantId, self::CRM_SERVICE_ID]
            );
            $this->insert($pdo,
                'INSERT INTO nexa_tenant_owner_identity (id, tenant_id, owner_user_id, email, normalized_email, status, verification_token_hash, verification_expires_at) VALUES (?, ?, ?, ?, ?, \'pending_verification\', ?, ?)',
                [$ownerId, $tenantId, $userId, $data['email'], $data['email'], $tokenHash, $verificationEnd]
            );
            $this->insert($pdo,
                'INSERT INTO nexa_provisioning_operation (id, tenant_id, operation_type, status, idempotency_key, attempt_count) VALUES (?, ?, \'signup\', \'awaiting_verification\', ?, 1)',
                [$operationId, $tenantId, 'signup:' . $ownerId]
            );
            $this->audit($pdo, $tenantId, $userId, 'signup.requested');
            $pdo->commit();
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            if ($e instanceof PDOException && $e->getCode() === '23000') {
                throw new SignupProblem(409, 'email_in_use', 'An account already uses this email address.');
            }
            throw $e;
        }

        // Delivery is deliberately outside the transaction. A temporary SMTP
        // failure leaves a valid pending account that can use the resend flow.
        $emailSent = $this->mailer->sendVerification(
            $tenantId,
            $slug,
            $data['company'],
            $data['firstName'],
            $data['email'],
            $code
        );

        $result = [
            'status' => 'pending_verification',
            'email' => $this->maskEmail($data['email']),
            'plan' => $plan['plan_key'],
            'trialEndsAt' => $trialEnd,
            'emailSent' => $emailSent,
        ];
        if ($this->canExposeLocalVerification()) {
            $result['verificationCode'] = $code;
        }

        return $result;
    }

    /** @return array<string, mixed> */
    public function verify(string $email, string $code, string $fingerprint): array
    {
        $email = strtolower(trim($email));
        $code = trim($code);
        if (filter_var($email, FILTER_VALIDATE_EMAIL) === false || !preg_match('/^\d{8}$/', $code)) {
            throw new SignupProblem(400, 'invalid_code', 'Enter the valid eight-digit verification code.');
        }

        $pdo = $this->entityManager->getPDO();
        $this->enforceRateLimit($pdo, $fingerprint, 'verify', 8);
        $pdo->beginTransaction();

        // Lock the identity row so two clicks cannot activate the same tenant
        // concurrently or produce duplicate audit/provisioning transitions.
        try {
            $statement = $pdo->prepare('SELECT * FROM nexa_tenant_owner_identity WHERE normalized_email = ? AND verification_token_hash = ? FOR UPDATE');
            $statement->execute([$email, $this->codeHash($email, $code)]);
            $owner = $statement->fetch(PDO::FETCH_ASSOC);

            if (!$owner) {
                throw new SignupProblem(400, 'invalid_code', 'The verification code is invalid.');
            }
            if ($owner['status'] === 'active') {
                $pdo->commit();
                return ['status' => 'active', 'loginUrl' => '/?login=1&source=signup'];
            }
            if (new DateTimeImmutable($owner['verification_expires_at']) < new DateTimeImmutable()) {
                throw new SignupProblem(410, 'code_expired', 'This verification code has expired. Request a new code.');
            }

            $this->insert($pdo, 'UPDATE nexa_tenant_owner_identity SET status = \'active\', verification_token_hash = NULL, verification_expires_at = NULL, verified_at = CURRENT_TIMESTAMP(6) WHERE id = ?', [$owner['id']]);
            $this->insert($pdo, 'UPDATE nexa_tenant SET status = \'active\' WHERE id = ?', [$owner['tenant_id']]);
            $this->insert($pdo, 'UPDATE `user` SET is_active = 1, modified_at = CURRENT_TIMESTAMP WHERE id = ? AND tenant_id = ?', [$owner['owner_user_id'], $owner['tenant_id']]);
            $this->insert($pdo, 'UPDATE nexa_provisioning_operation SET status = \'completed\', completed_at = CURRENT_TIMESTAMP(6) WHERE tenant_id = ? AND operation_type = \'signup\'', [$owner['tenant_id']]);
            $this->audit($pdo, $owner['tenant_id'], $owner['owner_user_id'], 'signup.verified');
            $pdo->commit();
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            throw $e;
        }

        return ['status' => 'active', 'loginUrl' => '/?login=1&source=signup'];
    }

    /** @return array<string, mixed> */
    public function resend(string $email, string $fingerprint): array
    {
        $email = strtolower(trim($email));
        if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            throw new SignupProblem(422, 'validation_failed', 'Enter a valid email address.', ['email' => 'Enter a valid email address.']);
        }

        $pdo = $this->entityManager->getPDO();
        $this->enforceRateLimit($pdo, $fingerprint, 'resend', 3);
        $statement = $pdo->prepare('SELECT i.*, t.slug, t.display_name FROM nexa_tenant_owner_identity i JOIN nexa_tenant t ON t.id = i.tenant_id WHERE i.normalized_email = ? AND i.status = \'pending_verification\'');
        $statement->execute([$email]);
        $owner = $statement->fetch(PDO::FETCH_ASSOC);

        $result = ['status' => 'accepted', 'message' => 'If a pending account exists, a new verification code has been sent.'];
        // Always return the same public response. This prevents the resend API
        // from becoming an email-address discovery endpoint.
        if (!$owner) {
            return $result;
        }

        $code = $this->verificationCode();
        $this->insert($pdo, 'UPDATE nexa_tenant_owner_identity SET verification_token_hash = ?, verification_expires_at = DATE_ADD(CURRENT_TIMESTAMP(6), INTERVAL 15 MINUTE) WHERE id = ?', [$this->codeHash($email, $code), $owner['id']]);
        $this->mailer->sendVerification($owner['tenant_id'], $owner['slug'], $owner['display_name'], '', $email, $code);
        if ($this->canExposeLocalVerification()) {
            $result['verificationCode'] = $code;
        }

        return $result;
    }

    /** @return array{id:string,plan_key:string} */
    private function findPlan(PDO $pdo, string $key): array
    {
        $statement = $pdo->prepare('SELECT id, plan_key FROM nexa_plan_definition WHERE plan_key = ? AND status = \'active\'');
        $statement->execute([$key]);
        $plan = $statement->fetch(PDO::FETCH_ASSOC);
        if (!$plan) {
            throw new SignupProblem(422, 'plan_unavailable', 'The selected plan is unavailable.');
        }
        return $plan;
    }

    private function assertEmailAvailable(PDO $pdo, string $email): void
    {
        // Owner email is a platform-wide identity, unlike ordinary tenant users.
        // Check both the new registry and legacy user/email records during migration.
        $statement = $pdo->prepare('SELECT 1 FROM nexa_tenant_owner_identity WHERE normalized_email = ? UNION SELECT 1 FROM `user` WHERE LOWER(user_name) = ? AND deleted = 0 UNION SELECT 1 FROM email_address ea JOIN entity_email_address eea ON eea.email_address_id = ea.id AND eea.entity_type = \'User\' AND eea.deleted = 0 WHERE ea.`lower` = ? AND ea.deleted = 0 LIMIT 1');
        $statement->execute([$email, $email, $email]);
        if ($statement->fetchColumn()) {
            throw new SignupProblem(409, 'email_in_use', 'An account already uses this email address.');
        }
    }

    private function enforceRateLimit(PDO $pdo, string $fingerprint, string $action, int $limit): void
    {
        // Persisted counters work across PHP workers and container restarts.
        // The HMAC hides raw IP and user-agent values from the database.
        $key = hash_hmac('sha256', $fingerprint, (string) $this->config->get('hashSecretKey', 'nexa'));
        $pdo->beginTransaction();
        try {
            $statement = $pdo->prepare('SELECT * FROM nexa_signup_rate_limit WHERE fingerprint_hash = ? AND action_key = ? FOR UPDATE');
            $statement->execute([$key, $action]);
            $row = $statement->fetch(PDO::FETCH_ASSOC);
            $now = new DateTimeImmutable();
            if ($row && $row['blocked_until'] && new DateTimeImmutable($row['blocked_until']) > $now) {
                throw new SignupProblem(429, 'rate_limited', 'Too many attempts. Try again later.');
            }
            if (!$row || new DateTimeImmutable($row['window_started_at']) < $now->modify('-15 minutes')) {
                $this->insert($pdo, 'INSERT INTO nexa_signup_rate_limit (fingerprint_hash, action_key, window_started_at, attempt_count, blocked_until) VALUES (?, ?, CURRENT_TIMESTAMP(6), 1, NULL) ON DUPLICATE KEY UPDATE window_started_at = VALUES(window_started_at), attempt_count = 1, blocked_until = NULL', [$key, $action]);
            } else {
                $count = (int) $row['attempt_count'] + 1;
                $blocked = $count > $limit ? $now->modify('+30 minutes')->format('Y-m-d H:i:s.u') : null;
                $this->insert($pdo, 'UPDATE nexa_signup_rate_limit SET attempt_count = ?, blocked_until = ? WHERE fingerprint_hash = ? AND action_key = ?', [$count, $blocked, $key, $action]);
                if ($blocked !== null) {
                    $pdo->commit();
                    throw new SignupProblem(429, 'rate_limited', 'Too many attempts. Try again later.');
                }
            }
            if ($pdo->inTransaction()) {
                $pdo->commit();
            }
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            throw $e;
        }
    }

    private function audit(PDO $pdo, string $tenantId, string $userId, string $action): void
    {
        $this->insert($pdo, 'INSERT INTO nexa_audit_event (id, tenant_id, service_id, actor_type, actor_user_id, action, subject_type, subject_id, source, metadata_json) VALUES (?, ?, ?, \'user\', ?, ?, \'tenant\', ?, \'self-service-signup\', JSON_OBJECT())', [$this->uuid(), $tenantId, self::CRM_SERVICE_ID, $userId, $action, $tenantId]);
    }

    /** @param list<mixed> $params */
    private function insert(PDO $pdo, string $sql, array $params): void
    {
        $statement = $pdo->prepare($sql);
        $statement->execute($params);
    }

    private function canExposeLocalVerification(): bool
    {
        // This escape hatch exists only for local development without SMTP.
        // Both an explicit flag and a localhost site URL are required.
        if (filter_var(getenv('NEXA_SIGNUP_EXPOSE_VERIFICATION_CODE') ?: false, FILTER_VALIDATE_BOOL) !== true) {
            return false;
        }
        $host = strtolower((string) parse_url((string) $this->config->get('siteUrl', ''), PHP_URL_HOST));
        return in_array($host, ['localhost', '127.0.0.1', 'nexa.local'], true);
    }

    private function codeHash(string $email, string $code): string
    {
        // Bind the short-lived code to its email and store only a keyed digest.
        return hash_hmac('sha256', strtolower($email) . ':' . $code, (string) $this->config->get('hashSecretKey', 'nexa'));
    }

    private function verificationCode(): string
    {
        return str_pad((string) random_int(0, 99999999), 8, '0', STR_PAD_LEFT);
    }

    private function uuid(): string
    {
        $bytes = random_bytes(16);
        $bytes[6] = chr((ord($bytes[6]) & 0x0f) | 0x40);
        $bytes[8] = chr((ord($bytes[8]) & 0x3f) | 0x80);
        return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($bytes), 4));
    }

    private function entityId(): string
    {
        return substr(bin2hex(random_bytes(9)), 0, 17);
    }

    private function slug(string $company): string
    {
        $base = strtolower(trim((string) preg_replace('/[^a-z0-9]+/i', '-', $company), '-')) ?: 'workspace';
        return substr($base, 0, 54) . '-' . substr(bin2hex(random_bytes(4)), 0, 8);
    }

    private function maskEmail(string $email): string
    {
        [$local, $domain] = explode('@', $email, 2);
        return substr($local, 0, 1) . str_repeat('*', max(2, strlen($local) - 1)) . '@' . $domain;
    }
}
