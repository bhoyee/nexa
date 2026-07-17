<?php

namespace Espo\Core\Tenant;

use Espo\Core\Utils\Log;
use InvalidArgumentException;

final class PlatformExecutionGateway
{
    public function __construct(
        private TenantContextStore $tenantContextStore,
        private Log $log,
    ) {}

    public function run(string $reason, callable $callback): mixed
    {
        if (trim($reason) === '') {
            throw new InvalidArgumentException('A platform execution reason is required.');
        }

        $this->log->notice('Nexa platform tenant bypass: ' . $reason);

        return $this->tenantContextStore->runAsPlatform($callback);
    }
}
