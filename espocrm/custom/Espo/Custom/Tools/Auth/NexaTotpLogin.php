<?php

namespace Espo\Custom\Tools\Auth;

use Espo\Core\Api\Request;
use Espo\Core\Authentication\HeaderKey;
use Espo\Core\Authentication\Result;
use Espo\Core\Authentication\Result\Data as ResultData;
use Espo\Core\Authentication\Result\FailReason;
use Espo\Core\Authentication\TwoFactor\Login;
use Espo\Core\Authentication\TwoFactor\Totp\Util;
use Espo\Core\Tenant\TenantContextStore;
use Espo\Entities\UserData;
use Espo\ORM\EntityManager;
use RuntimeException;

/** Adds single-use recovery codes to Espo's proven TOTP second-step flow. */
final class NexaTotpLogin implements Login
{
    public function __construct(
        private EntityManager $entityManager,
        private Util $totp,
        private TenantContextStore $tenantContextStore,
        private MfaRecoveryService $recoveryService,
    ) {}

    public function login(Result $result, Request $request): Result
    {
        $user = $result->getUser();
        if (!$user) {
            throw new RuntimeException('No user.');
        }
        $code = trim((string) $request->getHeader(HeaderKey::AUTHORIZATION_CODE));
        if ($code === '') {
            return Result::secondStepRequired($user, ResultData::createWithMessage('enterTotpOrRecoveryCode'));
        }
        $userData = $this->entityManager->getRDBRepository(UserData::ENTITY_TYPE)
            ->where(['userId' => $user->getId()])
            ->findOne();
        if (!$userData || !$userData->get('auth2FA') || $userData->get('auth2FAMethod') !== 'Totp') {
            return Result::fail(FailReason::CODE_NOT_VERIFIED);
        }
        $secret = (string) $userData->get('auth2FATotpSecret');
        if ($secret !== '' && $this->totp->verifyCode($secret, str_replace(' ', '', $code))) {
            return $result;
        }
        $tenantId = $this->tenantContextStore->require()->tenantId;
        if ($this->recoveryService->consume($tenantId, $user->getId(), $code)) {
            return $result;
        }

        return Result::fail(FailReason::CODE_NOT_VERIFIED);
    }
}
