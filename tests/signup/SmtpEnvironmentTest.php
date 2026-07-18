<?php

use Espo\Custom\Tools\Signup\SmtpEnvironment;

require dirname(__DIR__, 2) . '/espocrm/vendor/autoload.php';

function expect(bool $condition, string $message): void
{
    if (!$condition) {
        throw new RuntimeException($message);
    }
}

function environmentFile(string $contents): string
{
    $path = tempnam(sys_get_temp_dir(), 'nexa-smtp-');
    if ($path === false) {
        throw new RuntimeException('Unable to create SMTP test file.');
    }
    file_put_contents($path, $contents);
    return $path;
}

$blank = environmentFile("SMTP_HOST=\n");
expect(SmtpEnvironment::load($blank) === null, 'Blank SMTP host must disable configuration.');
unlink($blank);

$valid = environmentFile(<<<'ENV'
SMTP_HOST=smtp.example.test
SMTP_PORT=587
SMTP_SECURITY=TLS
SMTP_AUTH=true
SMTP_USERNAME=test-user
SMTP_PASSWORD="a-password-with-#-symbol"
SMTP_FROM_EMAIL=hello@example.test
SMTP_FROM_NAME=Nexa CRM
ENV);
$config = SmtpEnvironment::load($valid);
expect($config !== null, 'A complete SMTP environment must load.');
expect($config['smtpServer'] === 'smtp.example.test', 'SMTP host was not mapped.');
expect($config['smtpPassword'] === 'a-password-with-#-symbol', 'Quoted password was not preserved.');
expect($config['outboundEmailFromAddress'] === 'hello@example.test', 'Sender was not mapped.');
unlink($valid);

$invalid = environmentFile("SMTP_HOST=smtp.example.test\nSMTP_AUTH=true\nSMTP_FROM_EMAIL=bad\n");
try {
    SmtpEnvironment::load($invalid);
    throw new RuntimeException('Invalid SMTP configuration was accepted.');
} catch (RuntimeException $e) {
    expect(
        str_contains($e->getMessage(), 'SMTP_USERNAME'),
        'SMTP authentication validation did not run.'
    );
}
unlink($invalid);

echo "SMTP environment tests passed.\n";
