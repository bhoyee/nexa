<?php

declare(strict_types=1);

require dirname(__DIR__) . '/bootstrap.php';

use Espo\Core\Application;
use Espo\Core\ORM\EntityManager;
use Espo\Core\Tenant\TenantResolver;

$password = getenv('NEXA_DEMO_ADMIN_PASSWORD') ?: getenv('ESPOCRM_ADMIN_PASSWORD');
$userName = getenv('NEXA_DEMO_ADMIN_USERNAME') ?: 'demo-admin';

if (!is_string($password) || strlen($password) < 12) {
    fwrite(STDERR, "Set NEXA_DEMO_ADMIN_PASSWORD to a password of at least 12 characters.\n");
    exit(1);
}

if (!is_string($userName) || $userName === '' || strlen($userName) > 50) {
    fwrite(STDERR, "NEXA_DEMO_ADMIN_USERNAME must contain between 1 and 50 characters.\n");
    exit(1);
}

$hosts = [
    'tenant-a.localhost',
    'tenant-b.localhost',
];

$application = new Application();
$container = $application->getContainer();
$entityManager = $container->getByClass(EntityManager::class);
$tenantResolver = $container->getByClass(TenantResolver::class);
$pdo = $entityManager->getPDO();

$find = $pdo->prepare(
    'SELECT id FROM user WHERE tenant_id = :tenantId AND user_name = :userName AND deleted = 0 LIMIT 1'
);
$insert = $pdo->prepare(
    'INSERT INTO user ' .
    '(id, deleted, user_name, type, password, first_name, last_name, is_active, created_at, modified_at, delete_id, tenant_id) ' .
    'VALUES (:id, 0, :userName, :type, :password, :firstName, :lastName, 1, UTC_TIMESTAMP(), UTC_TIMESTAMP(), :deleteId, :tenantId)'
);
$update = $pdo->prepare(
    'UPDATE user SET type = :type, password = :password, first_name = :firstName, ' .
    'last_name = :lastName, is_active = 1, modified_at = UTC_TIMESTAMP() ' .
    'WHERE id = :id AND tenant_id = :tenantId'
);

foreach ($hosts as $host) {
    $tenant = $tenantResolver->resolveHost($host);

    if ($tenant === null) {
        fwrite(STDERR, "Demo tenant for host {$host} is missing. Apply development seeds first.\n");
        exit(1);
    }

    $find->execute([
        'tenantId' => $tenant->tenantId,
        'userName' => $userName,
    ]);
    $id = $find->fetchColumn();
    $created = !is_string($id);

    if ($created) {
        $id = substr(bin2hex(random_bytes(9)), 0, 17);
        $insert->execute([
            'id' => $id,
            'userName' => $userName,
            'type' => 'admin',
            'password' => password_hash($password, PASSWORD_BCRYPT),
            'firstName' => 'Demo',
            'lastName' => 'Administrator',
            'deleteId' => '0',
            'tenantId' => $tenant->tenantId,
        ]);
    } else {
        $update->execute([
            'id' => $id,
            'type' => 'admin',
            'password' => password_hash($password, PASSWORD_BCRYPT),
            'firstName' => 'Demo',
            'lastName' => 'Administrator',
            'tenantId' => $tenant->tenantId,
        ]);
    }

    $action = $created ? 'created' : 'updated';
    fwrite(STDOUT, "{$action}: {$host} / {$userName} / {$tenant->tenantId}\n");
}