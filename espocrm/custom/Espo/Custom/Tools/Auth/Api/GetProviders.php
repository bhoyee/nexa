<?php

namespace Espo\Custom\Tools\Auth\Api;

use Espo\Core\Api\Action;
use Espo\Core\Api\Request;
use Espo\Core\Api\Response;
use Espo\Core\Api\ResponseComposer;
use Espo\Custom\Tools\Auth\AuthProviderRegistry;

final class GetProviders implements Action
{
    public function __construct(private AuthProviderRegistry $registry)
    {}

    public function process(Request $request): Response
    {
        return ResponseComposer::json(['providers' => $this->registry->getPublicProviders()]);
    }
}
