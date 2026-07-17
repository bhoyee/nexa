<?php

namespace Espo\Core\Tenant\Api;

use Espo\Core\Tenant\TenantContextStore;
use Espo\Core\Tenant\TenantResolver;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;
use Slim\Psr7\Response;

final class TenantContextMiddleware implements MiddlewareInterface
{
    public function __construct(
        private TenantResolver $tenantResolver,
        private TenantContextStore $tenantContextStore,
    ) {}

    public function process(ServerRequestInterface $request, RequestHandlerInterface $handler): ResponseInterface
    {
        $identifier = $this->extractLoginIdentifier($request);

        if ($identifier !== null) {
            $tenant = $this->tenantResolver->resolveLoginIdentifier($identifier);

            if ($tenant === null) {
                return $this->errorResponse(401, 'Unauthorized');
            }
        } else {
            $tenant = $this->tenantResolver->resolveHost($request->getUri()->getHost());

            if ($tenant === null) {
                return $this->errorResponse(403, 'Tenant unavailable');
            }
        }

        return $this->tenantContextStore->runWith(
            $tenant,
            fn () => $handler->handle($request->withAttribute('nexaTenant', $tenant))
        );
    }

    private function errorResponse(int $status, string $message): ResponseInterface
    {
        $response = new Response($status);
        $response->getBody()->write(json_encode(['message' => $message], JSON_THROW_ON_ERROR));

        return $response->withHeader('Content-Type', 'application/json');
    }

    private function extractLoginIdentifier(ServerRequestInterface $request): ?string
    {
        $value = trim($request->getHeaderLine('Espo-Authorization'));

        if ($value === '') {
            $value = trim($request->getHeaderLine('Authorization'));

            if (str_starts_with(strtolower($value), 'basic ')) {
                $value = trim(substr($value, 6));
            }
        }

        if ($value === '') {
            return null;
        }

        $decoded = base64_decode($value, true);

        if (!is_string($decoded)) {
            return null;
        }

        $separator = strpos($decoded, ':');

        if ($separator === false) {
            return null;
        }

        $identifier = trim(substr($decoded, 0, $separator));

        return $identifier !== '' ? $identifier : null;
    }
}
