<?php

namespace Espo\Custom\Tools\Auth\Api;

use Espo\Core\Api\Action;
use Espo\Core\Api\Request;
use Espo\Core\Api\Response;
use Espo\Core\Api\ResponseComposer;
use Espo\Custom\Tools\Auth\IdentityProviderStore;

/** Discovers tenant SSO from an email domain without checking account existence. */
final class GetDiscovery implements Action
{
    public function __construct(private IdentityProviderStore $store) {}

    public function process(Request $request): Response
    {
        return ResponseComposer::json([
            'providers' => $this->store->discover((string) $request->getQueryParam('email')),
        ])->setHeader('Cache-Control', 'no-store');
    }
}
