<?php

namespace Espo\Custom\Tools\Auth\Api;

use Espo\Core\Api\Action;
use Espo\Core\Api\Request;
use Espo\Core\Api\Response;
use Espo\Core\Api\ResponseComposer;
use Espo\Custom\Tools\Auth\MfaRecoveryService;
use Espo\Entities\User;

/** Regenerates recovery codes for the authenticated user and displays them once. */
final class PostMfaRecoveryCodes implements Action
{
    public function __construct(
        private MfaRecoveryService $service,
        private User $user,
    ) {}

    public function process(Request $request): Response
    {
        return ResponseComposer::json([
            'codes' => $this->service->regenerate($this->user),
            'message' => 'Store these recovery codes securely. Each code can be used once.',
        ])->setHeader('Cache-Control', 'no-store');
    }
}
