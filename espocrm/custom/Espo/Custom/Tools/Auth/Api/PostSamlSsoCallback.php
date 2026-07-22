<?php

namespace Espo\Custom\Tools\Auth\Api;

use Espo\Core\Api\Action;
use Espo\Core\Api\Request;
use Espo\Core\Api\Response;
use Espo\Core\Api\ResponseComposer;
use Espo\Custom\Tools\Auth\EnterpriseSsoService;

final class PostSamlSsoCallback implements Action
{
    public function __construct(private EnterpriseSsoService $service) {}

    public function process(Request $request): Response
    {
        $body = $request->getParsedBody();
        $url = $this->service->samlCallback(
            (string) $request->getRouteParam('providerId'),
            (string) ($body->RelayState ?? ''),
            (string) ($body->SAMLResponse ?? ''),
        );

        return ResponseComposer::empty()->setStatus(302)->setHeader('Location', $url)->setHeader('Cache-Control', 'no-store');
    }
}
