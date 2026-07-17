<?php

namespace Espo\Core\Tenant;

use Espo\Core\Utils\Util;
use RuntimeException;

final class EntityOwnershipRegistry
{
    /** @var array<string, true> */
    private array $tenantTables = [];
    /** @var array<string, true> */
    private array $platformTables = [];

    public function __construct()
    {
        $file = dirname(__DIR__, 2) . '/Resources/tenant-table-ownership.json';
        $data = json_decode((string) file_get_contents($file), true, flags: JSON_THROW_ON_ERROR);

        foreach ($data['tenantScopedTables'] ?? [] as $table) {
            $this->tenantTables[$table] = true;
        }

        foreach ($data['platformGlobalTables'] ?? [] as $table) {
            $this->platformTables[$table] = true;
        }

        if ($this->tenantTables === []) {
            throw new RuntimeException('Tenant table ownership metadata is empty.');
        }
    }

    public function tableForEntity(string $entityType): string
    {
        return Util::camelCaseToUnderscore($entityType);
    }

    public function isTenantEntity(string $entityType): bool
    {
        return isset($this->tenantTables[$this->tableForEntity($entityType)]);
    }

    public function isPlatformEntity(string $entityType): bool
    {
        return isset($this->platformTables[$this->tableForEntity($entityType)]);
    }

    public function isKnownEntity(string $entityType): bool
    {
        return $this->isTenantEntity($entityType) || $this->isPlatformEntity($entityType);
    }
}
