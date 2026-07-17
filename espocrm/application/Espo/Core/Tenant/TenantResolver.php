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

        return is_array($row) ? $this->contextFromRow($row, 'verified-host') : null;
    }

    public function resolveLoginIdentifier(string $identifier): ?TenantContext
    {
        $identifier = trim($identifier);

        if ($identifier === '' || strlen($identifier) > 255) {
            return null;
        }

        $statement = $this->entityManager->getPDO()->prepare(
            'SELECT DISTINCT t.id, t.slug, t.display_name FROM user u ' .
            'INNER JOIN nexa_tenant t ON t.id = u.tenant_id ' .
            'WHERE u.user_name = :identifier AND u.deleted = 0 AND u.is_active = 1 ' .
            'AND t.status = :active LIMIT 2'
        );
        $statement->execute([
            'identifier' => $identifier,
            'active' => 'active',
        ]);
        $rows = $statement->fetchAll(\PDO::FETCH_ASSOC);

        if (count($rows) !== 1) {
            return null;
        }

        return $this->contextFromRow($rows[0], 'login-identity');
    }

    /** @param array{id: string, slug: string, display_name: string} $row */
    private function contextFromRow(array $row, string $source): TenantContext
    {
        return new TenantContext($row['id'], $row['slug'], $source, $row['display_name']);
    }
}
