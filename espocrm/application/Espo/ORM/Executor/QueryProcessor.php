<?php

namespace Espo\ORM\Executor;

use Espo\ORM\Query\Query;

/**
 * Applies cross-cutting constraints to immutable ORM queries before SQL composition.
 */
interface QueryProcessor
{
    public function process(Query $query): Query;
}
