<?php

namespace Espo\Custom\Tools\Auth;

use Espo\Core\Api\Request;
use Espo\Core\Authentication\AuthenticationData;
use Espo\Core\Authentication\HeaderKey;
use Espo\Core\Authentication\Hook\OnLogin;
use Espo\Core\Authentication\Result;
use Espo\Core\Exceptions\Forbidden;
use Espo\Core\Tenant\TenantContextStore;
use Espo\Entities\UserData;
use Espo\ORM\EntityManager;

/** Enforces tenant password and MFA policy after credentials are verified. */
final class TenantAuthPolicyHook implements OnLogin
{
    public function __construct(
        private EntityManager $entityManager,
        private TenantContextStore $tenantContextStore,
    ) {}

    public function process(Result $result, AuthenticationData $data, Request $request): void
    {
        if ($request->getHeader(HeaderKey::AUTHORIZATION_BY_TOKEN) === 'true') {
            return;
        }
        $tenantId = $this->tenantContextStore->getTenantId();
        $user = $result->getUser();
        if ($tenantId === null || !$user) {
            return;
        }
        $statement = $this->entityManager->getPDO()->prepare(
            'SELECT allow_password_login,require_mfa FROM nexa_tenant_auth_policy WHERE tenant_id=?'
        );
        $statement->execute([$tenantId]);
        $policy = $statement->fetch(\PDO::FETCH_ASSOC);
        if (!$policy) {
            return;
        }
        if (!(bool) $policy['allow_password_login']) {
            throw new Forbidden('Password login is disabled by workspace policy.');
        }
        if (!(bool) $policy['require_mfa'] || $result->isSecondStepRequired()) {
            return;
        }
        $userData = $this->entityManager->getRDBRepository(UserData::ENTITY_TYPE)
            ->where(['userId' => $user->getId()])
            ->findOne();
        if (!$userData || !(bool) $userData->get('auth2FA')) {
            throw new Forbidden('Multi-factor authentication enrollment is required by workspace policy.');
        }
    }
}
