<?php

namespace Espo\Core\Tenant;

use Espo\Core\Tenant\Exception\TenantScopeViolation;
use Espo\ORM\Executor\QueryProcessor;
use Espo\ORM\Metadata;
use Espo\ORM\Query\Delete;
use Espo\ORM\Query\Insert;
use Espo\ORM\Query\Query;
use Espo\ORM\Query\Select;
use Espo\ORM\Query\SelectingQuery;
use Espo\ORM\Query\Union;
use Espo\ORM\Query\Update;

final class TenantQueryProcessor implements QueryProcessor
{
    public function __construct(
        private TenantContextStore $contextStore,
        private EntityOwnershipRegistry $ownership,
        private Metadata $metadata,
    ) {}

    public function process(Query $query): Query
    {
        if ($this->contextStore->isPlatform()) {
            return $query;
        }

        return match (true) {
            $query instanceof Select => $this->processSelect($query),
            $query instanceof Update => $this->processWrite($query, $query->getIn()),
            $query instanceof Delete => $this->processWrite($query, $query->getFrom()),
            $query instanceof Insert => $this->processInsert($query),
            $query instanceof Union => $this->processUnion($query),
            default => $query,
        };
    }

    private function processSelect(Select $query): Select
    {
        $raw = $query->getRaw();

        if (($raw['fromQuery'] ?? null) instanceof SelectingQuery) {
            $raw['fromQuery'] = $this->process($raw['fromQuery']);
        }

        $entityType = $query->getFrom();

        if ($entityType !== null) {
            $this->assertKnown($entityType);

            if ($this->ownership->isTenantEntity($entityType)) {
                $alias = $query->getFromAlias();
                $raw['whereClause'] = $this->addScope(
                    $raw['whereClause'] ?? [],
                    ($alias ? $alias . '.' : '') . 'tenantId'
                );
            }

            $raw = $this->scopeJoins($raw, $entityType);
        }

        return Select::fromRaw($raw);
    }

    private function processWrite(Update|Delete $query, string $entityType): Update|Delete
    {
        $this->assertKnown($entityType);

        if ($this->ownership->isPlatformEntity($entityType)) {
            throw new TenantScopeViolation("Platform table '{$entityType}' cannot be changed in a tenant request.");
        }

        $raw = $query->getRaw();
        $alias = $raw['fromAlias'] ?? null;
        $raw['whereClause'] = $this->addScope(
            $raw['whereClause'] ?? [],
            ($alias ? $alias . '.' : '') . 'tenantId'
        );
        $raw = $this->scopeJoins($raw, $entityType);

        if ($query instanceof Update && $this->containsTenantKey($raw['set'] ?? [])) {
            throw new TenantScopeViolation('The tenant identifier cannot be changed.');
        }

        return $query instanceof Update ? Update::fromRaw($raw) : Delete::fromRaw($raw);
    }

    private function processInsert(Insert $query): Insert
    {
        $raw = $query->getRaw();
        $entityType = $raw['into'];
        $this->assertKnown($entityType);

        if ($this->ownership->isPlatformEntity($entityType)) {
            throw new TenantScopeViolation("Platform table '{$entityType}' cannot be changed in a tenant request.");
        }

        if (isset($raw['valuesQuery'])) {
            throw new TenantScopeViolation('Tenant-owned INSERT SELECT must use an audited platform gateway.');
        }

        if (in_array('tenantId', $raw['columns'] ?? [], true)) {
            throw new TenantScopeViolation('Callers cannot provide a tenant identifier.');
        }

        $tenantId = $this->contextStore->require()->tenantId;
        $raw['columns'][] = 'tenantId';
        $isMass = isset($raw['values'][0]) && is_array($raw['values'][0]);

        if ($isMass) {
            foreach ($raw['values'] as &$values) {
                $values['tenantId'] = $tenantId;
            }
            unset($values);
        } else {
            $raw['values']['tenantId'] = $tenantId;
        }

        if ($this->containsTenantKey($raw['updateSet'] ?? [])) {
            throw new TenantScopeViolation('The tenant identifier cannot be changed.');
        }

        return Insert::fromRaw($raw);
    }

    private function processUnion(Union $query): Union
    {
        $raw = $query->getRaw();

        foreach ($raw['queries'] as &$item) {
            if ($item instanceof Query) {
                $item = $this->process($item);
            }
        }
        unset($item);

        return Union::fromRaw($raw);
    }

    /** @param array<string, mixed> $raw @return array<string, mixed> */
    private function scopeJoins(array $raw, string $rootEntityType): array
    {
        foreach (['joins', 'leftJoins'] as $joinKey) {
            foreach ($raw[$joinKey] ?? [] as $index => $join) {
                $wasString = is_string($join);
                $item = $wasString ? [$join] : $join;
                $target = $item[0] ?? null;

                if ($target instanceof Select) {
                    $item[0] = $this->processSelect($target);
                } elseif (is_string($target)) {
                    $isTable = ucfirst($target) === $target;
                    $foreignType = $isTable
                        ? $target
                        : $this->metadata->getDefs()->getEntity($rootEntityType)
                            ->tryGetRelation($target)?->tryGetForeignEntityType();

                    if ($foreignType && $this->ownership->isTenantEntity($foreignType) && $isTable) {
                        $alias = $item[1] ?? $target;
                        $item[2] = $this->addScope($item[2] ?? [], $alias . '.tenantId');
                    }
                }

                $raw[$joinKey][$index] = $wasString ? $join : $item;
            }
        }

        return $raw;
    }

    /** @param array<string|int, mixed> $where @return array<string|int, mixed> */
    private function addScope(array $where, string $attribute): array
    {
        $scope = [$attribute => $this->contextStore->require()->tenantId];

        if ($where === []) {
            return $scope;
        }

        $where[] = $scope;

        return $where;
    }

    /** @param array<string, mixed> $values */
    private function containsTenantKey(array $values): bool
    {
        foreach (array_keys($values) as $key) {
            if (rtrim((string) $key, ':') === 'tenantId') {
                return true;
            }
        }

        return false;
    }

    private function assertKnown(string $entityType): void
    {
        if (!$this->ownership->isKnownEntity($entityType)) {
            throw new TenantScopeViolation("Entity '{$entityType}' has no tenant ownership classification.");
        }
    }
}
