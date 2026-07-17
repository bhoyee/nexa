<?php

namespace Espo\Custom\Tools\Signup\Api;

use Espo\Core\Api\Request;
use Espo\Core\Api\Response;
use Espo\Core\Api\ResponseComposer;
use Espo\Core\Utils\Log;
use Espo\Custom\Tools\Signup\SignupProblem;
use Throwable;

/**
 * Shared HTTP boundary for public signup actions. It keeps transport security,
 * fingerprints and error response shapes consistent across all endpoints.
 */
final class SignupApiSupport
{
    public function __construct(private Log $log)
    {}

    public function assertJsonRequest(Request $request): void
    {
        $contentType = strtolower((string) $request->getHeader('Content-Type'));
        if (!str_starts_with($contentType, 'application/json')) {
            throw new SignupProblem(415, 'unsupported_media_type', 'Send the request as JSON.');
        }

        $origin = trim((string) $request->getHeader('Origin'));
        if ($origin === '') {
            return;
        }

        $originParts = parse_url($origin);
        $uri = $request->getUri();
        $originPort = $originParts['port'] ?? (($originParts['scheme'] ?? '') === 'https' ? 443 : 80);
        $requestPort = $uri->getPort() ?? ($uri->getScheme() === 'https' ? 443 : 80);

        // Signup uses cookie-capable same-origin requests. Reject foreign browser
        // origins explicitly instead of relying on CORS behavior alone.
        if (($originParts['scheme'] ?? '') !== $uri->getScheme()
            || strtolower((string) ($originParts['host'] ?? '')) !== strtolower($uri->getHost())
            || $originPort !== $requestPort) {
            throw new SignupProblem(403, 'origin_rejected', 'The request origin is not allowed.');
        }
    }

    public function fingerprint(Request $request): string
    {
        return (string) $request->getServerParam('REMOTE_ADDR') . '|' . (string) $request->getHeader('User-Agent');
    }

    public function success(array $data, int $status = 200): Response
    {
        return ResponseComposer::json($data)->setStatus($status);
    }

    public function problem(Throwable $error): Response
    {
        if ($error instanceof SignupProblem) {
            return ResponseComposer::json([
                'error' => $error->error,
                'message' => $error->getMessage(),
                'fields' => (object) $error->fields,
            ])->setStatus($error->status);
        }

        $this->log->error('Nexa signup API failed: ' . $error->getMessage(), ['exception' => $error]);
        return ResponseComposer::json([
            'error' => 'signup_failed',
            'message' => 'We could not create the workspace. Please try again.',
        ])->setStatus(500);
    }
}
