<?php

declare(strict_types=1);

$root = dirname(__DIR__, 2);
$configPath = $root . '/espocrm/data/config-internal.php';

if (!is_file($configPath)) {
    fwrite(STDERR, "Application configuration is missing. Run setup-native-windows.ps1.\n");
    exit(1);
}

$config = include $configPath;
if (($config['isInstalled'] ?? false) !== true || !is_array($config['database'] ?? null)) {
    fwrite(STDERR, "Native application installation is incomplete.\n");
    exit(1);
}

$database = $config['database'];
$pdo = new PDO(
    sprintf(
        'mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
        $database['host'],
        $database['port'] ?? 3306,
        $database['dbname'],
    ),
    $database['user'],
    $database['password'] ?? '',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION],
);

$files = glob($root . '/database/shared/seeds/*.sql') ?: [];
sort($files, SORT_STRING);

foreach ($files as $file) {
    $sql = file_get_contents($file);
    if (!is_string($sql)) {
        throw new RuntimeException("Unable to read seed file {$file}.");
    }

    $pdo->exec($sql);
    echo '[SEED] ' . basename($file) . "\n";
}

echo "Development seed data is current.\n";
