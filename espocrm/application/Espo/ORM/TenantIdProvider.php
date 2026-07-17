<?php

namespace Espo\ORM;

interface TenantIdProvider
{
    public function getTenantId(): ?string;
}