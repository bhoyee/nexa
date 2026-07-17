<?php

namespace Espo\Core\Tenant;

use Espo\ORM\EntityManager;

final class TenantResolver
{
    public function __construct(private EntityManager $entityManager)
    {}

    public function resolveHost(string $host): ?TenantContext
    {
        $host = strtolower(rtrim(trim($host), '.'));

        if ($host === '' || (!filter_var($host, FILTER_VALIDATE_DOMAIN, FILTER_FLAG_HOSTNAME) && !filter_var($host, FILTER_VALIDATE_IP))) {
            return null;
        }

        $statement = $this->entityManager->getPDO()->prepare(
            'SELECT t.id, t.slug, t.display_name FROM nexa_tenant_domain d ' .
            'INNER JOIN nexa_tenant t ON t.id = d.tenant_id ' .
            'WHERE d.hostname = :hostname AND d.verification_status = :verified ' .
            'AND t.status = :active LIMIT 1'
        );
        $statement->execute([
            'hostname' => $host,
            'verified' => 'verified',
            'active' => 'active',
        ]);
        $row = $statement->fetch(\PDO::FETCH_ASSOC);

        return is_array($row)
            ? new TenantContext($row['id'], $row['slug'], 'verified-host', $row['display_name'])
            : null;
    }
}
