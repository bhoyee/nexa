<?php

namespace Espo\Custom\Tools\App\AppParams;

use Espo\Core\Tenant\TenantContextStore;
use Espo\Tools\App\AppParam;

final class TenantIdentity implements AppParam
{
    public function __construct(private TenantContextStore $tenantContextStore)
    {}

    /** @return array{id: string, slug: string, displayName: string} */
    public function get(): array
    {
        $tenant = $this->tenantContextStore->require();

        return [
            'id' => $tenant->tenantId,
            'slug' => $tenant->slug,
            'displayName' => $tenant->displayName ?: $tenant->slug,
        ];
    }
}