<?php

namespace Espo\Custom\Tools\Signup\Api;

use Espo\Core\Api\Action;
use Espo\Core\Api\Request;
use Espo\Core\Api\Response;
use Espo\Custom\Tools\Signup\SignupProblem;
use Espo\Custom\Tools\Signup\SignupService;
use Throwable;

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
            $token = trim((string) ($request->getParsedBody()->token ?? ''));
            if ($token === '') {
                throw new SignupProblem(422, 'validation_failed', 'A verification token is required.');
            }
            return $this->support->success($this->service->verify($token));
        } catch (Throwable $e) {
            return $this->support->problem($e);
        }
    }
}
