<?php
/************************************************************************
 * This file is part of EspoCRM.
 *
 * EspoCRM – Open Source CRM application.
 * Copyright (C) 2014-2025 Yurii Kuznietsov, Taras Machyshyn, Oleksii Avramenko
 * Website: https://www.espocrm.com
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * The interactive user interfaces in modified source and object code versions
 * of this program must display Appropriate Legal Notices, as required under
 * Section 5 of the GNU Affero General Public License version 3.
 *
 * In accordance with Section 7(b) of the GNU Affero General Public License version 3,
 * these Appropriate Legal Notices must retain the display of the "EspoCRM" word.
 ************************************************************************/

namespace Espo\Tools\UserSecurity\Api;

use Espo\Core\Api\Action;
use Espo\Core\Api\Request;
use Espo\Core\Api\Response;
use Espo\Core\Api\ResponseComposer;
use Espo\Core\Exceptions\BadRequest;
use Espo\Core\Exceptions\NotFound;
use Espo\Core\Tenant\TenantContextStore;
use Espo\Core\Tenant\TenantResolver;
use Espo\Tools\UserSecurity\Password\Service;

/**
 * Changes a password in a recovery process.
 */
class PostChangePasswordByRequest implements Action
{
    public function __construct(
        private Service $service,
        private TenantResolver $tenantResolver,
        private TenantContextStore $tenantContextStore,
    ) {}

    public function process(Request $request): Response
    {
        $data = $request->getParsedBody();

        $requestId = $data->requestId ?? null;
        $password = $data->password ?? null;

        if (!$requestId || $password === null) {
            throw new BadRequest();
        }

        // A reset request is submitted on the shared login domain, where the
        // host cannot identify its tenant. Resolve the opaque single-use token
        // before any tenant-scoped request, user or password write is made.
        $tenant = $this->tenantResolver->resolvePasswordChangeRequest($requestId);

        if ($tenant === null) {
            throw new NotFound("Password recovery: Request not found by id.");
        }

        $url = $this->tenantContextStore->runWith(
            $tenant,
            fn () => $this->service->changePasswordByRecovery($requestId, $password)
        );

        return ResponseComposer::json(['url' => $url]);
    }
}
