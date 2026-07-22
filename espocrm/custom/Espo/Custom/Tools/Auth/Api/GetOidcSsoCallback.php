<?php

namespace Espo\Custom\Tools\Auth\Api;

use Espo\Core\Api\Action;
use Espo\Core\Api\Request;
use Espo\Core\Api\Response;
use Espo\Core\Api\ResponseComposer;
use Espo\Custom\Tools\Auth\EnterpriseSsoService;

final class GetOidcSsoCallback implements Action
{
    public function __construct(private EnterpriseSsoService $service) {}

    public function process(Request $request): Response
    {
        $url = $this->service->oidcCallback(
            (string) $request->getRouteParam('providerId'),
            (string) $request->getQueryParam('state'),
            (string) $request->getQueryParam('code'),
        );

        return ResponseComposer::empty()->setStatus(302)->setHeader('Location', $url)->setHeader('Cache-Control', 'no-store');
    }
}
