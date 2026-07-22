<?php

namespace Espo\Custom\Tools\Auth\Api;

use Espo\Core\Api\Action;
use Espo\Core\Api\Request;
use Espo\Core\Api\Response;
use Espo\Core\Api\ResponseComposer;
use Espo\Custom\Tools\Auth\AuthProblem;
use Espo\Custom\Tools\Auth\RecoveryService;
use Espo\Custom\Tools\Signup\Api\SignupApiSupport;
use Throwable;

final class PostRecovery implements Action
{
    public function __construct(
        private RecoveryService $service,
        private SignupApiSupport $support,
    ) {}

    public function process(Request $request): Response
    {
        try {
            $this->support->assertJsonRequest($request);
            $input = $request->getParsedBody();

            return ResponseComposer::json($this->service->request(
                (string) ($input->username ?? ''),
                (string) ($input->email ?? '')
            ))->setStatus(202);
        } catch (AuthProblem $e) {
            return ResponseComposer::json([
                'error' => $e->error,
                'message' => $e->getMessage(),
                'fields' => (object) $e->fields,
            ])->setStatus($e->status);
        } catch (Throwable $e) {
            return ResponseComposer::json([
                'status' => 'accepted',
                'message' => 'If the details match an account, password reset instructions will be sent.',
            ])->setStatus(202);
        }
    }
}
