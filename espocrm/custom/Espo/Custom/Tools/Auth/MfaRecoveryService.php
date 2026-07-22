<?php

namespace Espo\Custom\Tools\Auth;

use Espo\Core\Tenant\TenantContextStore;
use Espo\Entities\User;
use Espo\ORM\EntityManager;
use PDO;
use RuntimeException;
use Throwable;

/** Issues and consumes single-use MFA recovery codes scoped to one tenant user. */
final class MfaRecoveryService
{
    private const CODE_COUNT = 10;

    public function __construct(
        private EntityManager $entityManager,
        private TenantContextStore $tenantContextStore,
    ) {}

    /** @return list<string> */
    public function regenerate(User $user): array
    {
        $tenantId = $this->tenantContextStore->require()->tenantId;
        $pdo = $this->entityManager->getPDO();
        $pdo->beginTransaction();
        try {
            $pdo->prepare('DELETE FROM nexa_mfa_recovery_code WHERE tenant_id=? AND user_id=?')
                ->execute([$tenantId, $user->getId()]);
            $statement = $pdo->prepare(
                'INSERT INTO nexa_mfa_recovery_code (id,tenant_id,user_id,code_hash) VALUES (?,?,?,?)'
            );
            $codes = [];
            for ($index = 0; $index < self::CODE_COUNT; $index++) {
                $code = strtoupper(implode('-', str_split(bin2hex(random_bytes(6)), 4)));
                $statement->execute([$this->uuid(), $tenantId, $user->getId(), password_hash($code, PASSWORD_BCRYPT)]);
                $codes[] = $code;
            }
            $this->audit($pdo, $tenantId, $user->getId(), 'auth.mfa.recovery.regenerated');
            $pdo->commit();

            return $codes;
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            throw $e;
        }
    }

    public function consume(string $tenantId, string $userId, string $code): bool
    {
        $normalized = strtoupper(trim($code));
        if (!preg_match('/^[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}$/', $normalized)) {
            return false;
        }
        $pdo = $this->entityManager->getPDO();
        $pdo->beginTransaction();
        try {
            $statement = $pdo->prepare(
                'SELECT id,code_hash FROM nexa_mfa_recovery_code '
                . 'WHERE tenant_id=? AND user_id=? AND consumed_at IS NULL FOR UPDATE'
            );
            $statement->execute([$tenantId, $userId]);
            foreach ($statement->fetchAll(PDO::FETCH_ASSOC) as $row) {
                if (!password_verify($normalized, $row['code_hash'])) {
                    continue;
                }
                $pdo->prepare('UPDATE nexa_mfa_recovery_code SET consumed_at=CURRENT_TIMESTAMP(6) WHERE id=? AND consumed_at IS NULL')
                    ->execute([$row['id']]);
                $this->audit($pdo, $tenantId, $userId, 'auth.mfa.recovery.used');
                $pdo->commit();

                return true;
            }
            $pdo->rollBack();

            return false;
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            throw $e;
        }
    }

    private function audit(PDO $pdo, string $tenantId, string $userId, string $action): void
    {
        $statement = $pdo->prepare(
            'INSERT INTO nexa_audit_event (id,tenant_id,actor_type,actor_user_id,action,subject_type,subject_id,source,metadata_json) '
            . 'VALUES (?,?,' . "'user'" . ',?,?,' . "'user'" . ',?,' . "'mfa'" . ',JSON_OBJECT())'
        );
        $statement->execute([$this->uuid(), $tenantId, $userId, $action, $userId]);
    }

    private function uuid(): string
    {
        $bytes = random_bytes(16);
        $bytes[6] = chr((ord($bytes[6]) & 15) | 64);
        $bytes[8] = chr((ord($bytes[8]) & 63) | 128);

        return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($bytes), 4));
    }
}
