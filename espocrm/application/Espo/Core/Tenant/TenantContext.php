<?php

namespace Espo\Core\Tenant;

use InvalidArgumentException;

final readonly class TenantContext
{
    public function __construct(
        public string $tenantId,
        public string $slug,
        public string $source,
    ) {
        if (!preg_match('/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i', $tenantId)) {
            throw new InvalidArgumentException('Invalid tenant identifier.');
        }

        if ($slug === '' || $source === '') {
            throw new InvalidArgumentException('Tenant slug and source are required.');
        }
    }
}
