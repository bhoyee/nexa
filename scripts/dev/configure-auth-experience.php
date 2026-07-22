<?php

use Espo\Core\Application;
use Espo\Core\InjectableFactory;
use Espo\Core\Utils\Config\ConfigWriter;

$root = dirname(__DIR__, 2);
$environmentPath = $root . DIRECTORY_SEPARATOR . '.env';

foreach (array_slice($argv, 1) as $argument) {
    if (str_starts_with($argument, '--env=')) {
        $value = substr($argument, strlen('--env='));
        $isAbsolute = str_starts_with($value, DIRECTORY_SEPARATOR) ||
            (strlen($value) > 2 && ctype_alpha($value[0]) && $value[1] === ':');
        $environmentPath = $isAbsolute ? $value : $root . DIRECTORY_SEPARATOR . $value;
    }
}

if (!is_file($environmentPath)) {
    fwrite(STDERR, 'Environment file not found: ' . $environmentPath . PHP_EOL);
    exit(1);
}

$environment = [];
foreach (file($environmentPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $line) {
    $line = trim($line);
    if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) {
        continue;
    }
    [$key, $value] = explode('=', $line, 2);
    $environment[trim($key)] = trim($value);
}

chdir($root . DIRECTORY_SEPARATOR . 'espocrm');
require_once 'bootstrap.php';

$enabled = static fn (string $key): bool =>
    filter_var($environment[$key] ?? false, FILTER_VALIDATE_BOOL) === true;

// Provider secrets and callbacks belong to M04. This writes only the public
// switches consumed by the M02 authentication screens.
$application = new Application();
$factory = $application->getContainer()->getByClass(InjectableFactory::class);
$writer = $factory->create(ConfigWriter::class);
$writer->setMultiple([
    // Apply product branding to existing installations as well as clean setups.
    'applicationName' => ($environment['CRM_NAME'] ?? '') ?: 'Nexa CRM',
    'passwordRecoveryNoExposure' => true,
    'nexaSignupExposeVerificationCode' => $enabled('NEXA_SIGNUP_EXPOSE_VERIFICATION_CODE'),
    'nexaPublicAuthProviders' => [
        'google' => $enabled('NEXA_AUTH_GOOGLE_ENABLED'),
        'microsoft' => $enabled('NEXA_AUTH_MICROSOFT_ENABLED'),
    ],
]);
$writer->save();

fwrite(STDOUT, 'Authentication experience configuration applied.' . PHP_EOL);
