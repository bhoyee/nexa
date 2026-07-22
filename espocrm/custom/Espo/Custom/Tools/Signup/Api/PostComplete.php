<?php

namespace Espo\Custom\Tools\Signup\Api;

use Espo\Core\Api\Action;
use Espo\Core\Api\Request;
use Espo\Core\Api\Response;
use Espo\Custom\Tools\Signup\SignupService;
use Throwable;

/** Completes the workspace profile for an opaque signup attempt. */
final class PostComplete implements Action
{
    public function __construct(
        private SignupService $service,
        private SignupApiSupport $support,
    ) {}

    public function process(Request $request): Response
    {
        try {
            $this->support->assertJsonRequest($request);

            return $this->support->success(
                $this->service->complete(
                    $request->getParsedBody(),
                    $this->support->fingerprint($request),
                ),
            );
        } catch (Throwable $e) {
            return $this->support->problem($e);
        }
    }
}