<?php

namespace Espo\Custom\Tools\Signup\Api;

use Espo\Core\Api\Action;
use Espo\Core\Api\Request;
use Espo\Core\Api\Response;
use Espo\Custom\Tools\Signup\SignupProblem;
use Espo\Custom\Tools\Signup\SignupService;
use Throwable;

/** Verifies the email proof and atomically provisions the workspace. */
final class PostVerify implements Action
{
    public function __construct(
        private SignupService $service,
        private SignupApiSupport $support,
    ) {}

    public function process(Request $request): Response
    {
        try {
            $this->support->assertJsonRequest($request);
            $body = $request->getParsedBody();
            $token = trim((string) ($body->attemptToken ?? ''));
            $code = trim((string) ($body->code ?? ''));

            if ($token === '' || $code === '') {
                throw new SignupProblem(
                    422,
                    'validation_failed',
                    'Signup session and verification code are required.',
                );
            }

            return $this->support->success(
                $this->service->verify(
                    $token,
                    $code,
                    $this->support->fingerprint($request),
                ),
            );
        } catch (Throwable $e) {
            return $this->support->problem($e);
        }
    }
}