<?php

namespace Espo\Core\Tenant\Api;

use Espo\Core\Exceptions\Forbidden;
use Espo\Core\Tenant\TenantContextStore;
use Espo\Core\Tenant\TenantResolver;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;

final class TenantContextMiddleware implements MiddlewareInterface
{
    public function __construct(
        private TenantResolver $tenantResolver,
        private TenantContextStore $tenantContextStore,
    ) {}

    public function process(ServerRequestInterface $request, RequestHandlerInterface $handler): ResponseInterface
    {
        $tenant = $this->tenantResolver->resolveHost($request->getUri()->getHost());

        if ($tenant === null) {
            throw new Forbidden('The request host is not assigned to an active tenant.');
        }

        return $this->tenantContextStore->runWith(
            $tenant,
            fn () => $handler->handle($request->withAttribute('nexaTenant', $tenant))
        );
    }
}
