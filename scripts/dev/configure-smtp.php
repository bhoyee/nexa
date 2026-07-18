<?php

use Espo\Core\Application;
use Espo\Core\Utils\Config\ConfigWriter;
use Espo\Custom\Tools\Signup\SmtpEnvironment;

$root = dirname(__DIR__, 2);
$environmentPath = $root . DIRECTORY_SEPARATOR . '.env';

foreach (array_slice($argv, 1) as $argument) {
    if (str_starts_with($argument, '--env=')) {
        $value = substr($argument, strlen('--env='));
        $environmentPath = selfAbsolutePath($value, $root);
    }
}

chdir($root . DIRECTORY_SEPARATOR . 'espocrm');
require_once 'bootstrap.php';

try {
    $settings = SmtpEnvironment::load($environmentPath);
    if ($settings === null) {
        fwrite(STDOUT, "SMTP_HOST is empty; system SMTP configuration was not changed.\n");
        exit(0);
    }

    $application = new Application();
    $writer = $application->getContainer()->getByClass(ConfigWriter::class);
    $writer->setMultiple($settings);
    $writer->save();

    fwrite(
        STDOUT,
        "System SMTP configured for {$settings['outboundEmailFromAddress']} " .
        "through {$settings['smtpServer']}:{$settings['smtpPort']}.\n"
    );
} catch (Throwable $e) {
    fwrite(STDERR, "SMTP configuration failed: {$e->getMessage()}\n");
    exit(1);
}

function selfAbsolutePath(string $path, string $root): string
{
    if (preg_match('/^[A-Za-z]:[\\\\\/]/', $path) || str_starts_with($path, DIRECTORY_SEPARATOR)) {
        return $path;
    }

    return $root . DIRECTORY_SEPARATOR . $path;
}
