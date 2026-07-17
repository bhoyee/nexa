<?php

declare(strict_types=1);

require dirname(__DIR__) . '/bootstrap.php';

use Espo\Core\Application;
use Espo\Core\ORM\EntityManager;
use Espo\Core\Tenant\TenantResolver;

$accounts = [
    [
        'host' => 'tenant-a.localhost',
        'userName' => getenv('NEXA_TENANT_A_ADMIN_USERNAME') ?: 'demo-admin',
        'password' => getenv('NEXA_TENANT_A_ADMIN_PASSWORD'),
        'firstName' => 'Tenant A',
    ],
    [
        'host' => 'tenant-b.localhost',
        'userName' => getenv('NEXA_TENANT_B_ADMIN_USERNAME') ?: 'demo-admin-b',
        'password' => getenv('NEXA_TENANT_B_ADMIN_PASSWORD'),
        'firstName' => 'Tenant B',
    ],
];

foreach ($accounts as $account) {
    if (!is_string($account['password']) || strlen($account['password']) < 12) {
        fwrite(STDERR, "Set a password of at least 12 characters for {$account['host']}.\n");
        exit(1);
    }

    if (!is_string($account['userName']) || $account['userName'] === '' || strlen($account['userName']) > 50) {
        fwrite(STDERR, "The demo administrator username for {$account['host']} must contain between 1 and 50 characters.\n");
        exit(1);
    }
}

if ($accounts[0]['userName'] === $accounts[1]['userName']) {
    fwrite(STDERR, "Tenant A and Tenant B demo administrator usernames must be different.\n");
    exit(1);
}

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
$deactivateOtherDemoAccount = $pdo->prepare(
    'UPDATE user SET is_active = 0, modified_at = UTC_TIMESTAMP() ' .
    'WHERE tenant_id = :tenantId AND user_name = :otherUserName AND deleted = 0'
);

foreach ($accounts as $index => $account) {
    $tenant = $tenantResolver->resolveHost($account['host']);

    if ($tenant === null) {
        fwrite(STDERR, "Demo tenant for host {$account['host']} is missing. Apply development seeds first.\n");
        exit(1);
    }

    $find->execute([
        'tenantId' => $tenant->tenantId,
        'userName' => $account['userName'],
    ]);
    $id = $find->fetchColumn();
    $created = !is_string($id);

    if ($created) {
        $id = substr(bin2hex(random_bytes(9)), 0, 17);
        $insert->execute([
            'id' => $id,
            'userName' => $account['userName'],
            'type' => 'admin',
            'password' => password_hash($account['password'], PASSWORD_BCRYPT),
            'firstName' => $account['firstName'],
            'lastName' => 'Administrator',
            'deleteId' => '0',
            'tenantId' => $tenant->tenantId,
        ]);
    } else {
        $update->execute([
            'id' => $id,
            'type' => 'admin',
            'password' => password_hash($account['password'], PASSWORD_BCRYPT),
            'firstName' => $account['firstName'],
            'lastName' => 'Administrator',
            'tenantId' => $tenant->tenantId,
        ]);
    }

    $otherAccount = $accounts[$index === 0 ? 1 : 0];
    $deactivateOtherDemoAccount->execute([
        'tenantId' => $tenant->tenantId,
        'otherUserName' => $otherAccount['userName'],
    ]);

    $action = $created ? 'created' : 'updated';
    fwrite(STDOUT, "{$action}: {$account['host']} / {$account['userName']} / {$tenant->tenantId}\n");
}
