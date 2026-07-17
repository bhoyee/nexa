<?php

namespace Espo\Core\Tenant;

use Espo\Core\Tenant\Exception\TenantScopeViolation;
use Espo\ORM\Executor\SqlExecutor;
use PDOStatement;

final class TenantSqlExecutor implements SqlExecutor
{
    public function __construct(
        private SqlExecutor $inner,
        private TenantContextStore $tenantContextStore,
    ) {}

    public function execute(string $sql, bool $rerunIfDeadlock = false): PDOStatement
    {
        if (!$rerunIfDeadlock && !$this->tenantContextStore->isPlatform()) {
            throw new TenantScopeViolation(
                'Direct SQL is blocked during tenant execution; use ORM queries or an audited platform gateway.'
            );
        }

        return $this->inner->execute($sql, $rerunIfDeadlock);
    }
}
