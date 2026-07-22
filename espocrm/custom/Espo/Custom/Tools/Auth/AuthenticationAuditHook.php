<?php

namespace Espo\Custom\Tools\Auth;

use Espo\Core\Api\Request;
use Espo\Core\Authentication\AuthenticationData;
use Espo\Core\Authentication\Hook\OnResult;
use Espo\Core\Authentication\Result;
use Espo\Core\Tenant\TenantContextStore;
use Espo\ORM\EntityManager;
use Throwable;

/** Records tenant-aware password and MFA outcomes without storing credentials. */
final class AuthenticationAuditHook implements OnResult
{
    public function __construct(
        private EntityManager $entityManager,
        private TenantContextStore $tenantContextStore,
    ) {}

    public function process(Result $result, AuthenticationData $data, Request $request): void
    {
        $tenantId = $this->tenantContextStore->getTenantId();
        if ($tenantId === null) {
            return;
        }
        $action = match ($result->getStatus()) {
            Result::STATUS_SUCCESS => 'auth.password.succeeded',
            Result::STATUS_SECOND_STEP_REQUIRED => 'auth.mfa.challenged',
            default => $request->getHeader('Espo-Authorization-Code') !== null
                ? 'auth.mfa.failed'
                : 'auth.password.failed',
        };
        $userId = $result->getUser()?->getId();
        try {
            $statement = $this->entityManager->getPDO()->prepare(
                'INSERT INTO nexa_audit_event (id,tenant_id,actor_type,actor_user_id,action,subject_type,subject_id,source,metadata_json) '
                . 'VALUES (?,?,\'user\',?,?,\'user\',?,\'authentication\',JSON_OBJECT(\'remoteHash\',?))'
            );
            $statement->execute([
                $this->uuid(), $tenantId, $userId, $action, $userId,
                substr(hash('sha256', (string) $request->getServerParam('REMOTE_ADDR')), 0, 16),
            ]);
        } catch (Throwable) {
            // Authentication availability must not depend on audit storage health.
        }
    }

    private function uuid(): string
    {
        $bytes = random_bytes(16);
        $bytes[6] = chr((ord($bytes[6]) & 15) | 64);
        $bytes[8] = chr((ord($bytes[8]) & 63) | 128);

        return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($bytes), 4));
    }
}
