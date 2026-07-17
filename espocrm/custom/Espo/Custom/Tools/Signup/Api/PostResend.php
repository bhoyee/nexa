<?php

namespace Espo\Custom\Tools\Signup\Api;

use Espo\Core\Api\Action;
use Espo\Core\Api\Request;
use Espo\Core\Api\Response;
use Espo\Custom\Tools\Signup\SignupService;
use Throwable;

final class PostResend implements Action
{
    public function __construct(
        private SignupService $service,
        private SignupApiSupport $support,
    ) {}

    public function process(Request $request): Response
    {
        try {
            $this->support->assertJsonRequest($request);
            return $this->support->success($this->service->resend(
                (string) ($request->getParsedBody()->email ?? ''),
                $this->support->fingerprint($request)
            ));
        } catch (Throwable $e) {
            return $this->support->problem($e);
        }
    }
}
