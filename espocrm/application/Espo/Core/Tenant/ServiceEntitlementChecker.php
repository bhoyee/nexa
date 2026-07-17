<?php

namespace Espo\Core\Tenant;

use Espo\ORM\EntityManager;

final class ServiceEntitlementChecker
{
    public function __construct(
        private TenantContextStore $tenantContextStore,
        private EntityManager $entityManager,
    ) {}

    public function isEnabled(string $serviceKey): bool
    {
        $statement = $this->entityManager->getPDO()->prepare(
            'SELECT 1 FROM nexa_tenant_service ts ' .
            'INNER JOIN nexa_service_definition sd ON sd.id = ts.service_id ' .
            'WHERE ts.tenant_id = :tenantId AND sd.service_key = :serviceKey ' .
            'AND ts.status = :active AND sd.status = :active ' .
            'AND (ts.starts_at IS NULL OR ts.starts_at <= CURRENT_TIMESTAMP(6)) ' .
            'AND (ts.ends_at IS NULL OR ts.ends_at > CURRENT_TIMESTAMP(6)) LIMIT 1'
        );
        $statement->execute([
            'tenantId' => $this->tenantContextStore->require()->tenantId,
            'serviceKey' => $serviceKey,
            'active' => 'active',
        ]);

        return (bool) $statement->fetchColumn();
    }
}
