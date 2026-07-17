<?php

namespace Espo\Core\Tenant;

final class TenantResourceKey
{
    public function __construct(private TenantContextStore $tenantContextStore)
    {}

    public function for(string $resource, string $localKey): string
    {
        $tenant = $this->tenantContextStore->require();

        return sprintf('tenant/%s/%s/%s', $tenant->tenantId, trim($resource, '/'), ltrim($localKey, '/'));
    }
}
