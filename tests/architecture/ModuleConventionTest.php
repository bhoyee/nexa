<?php

declare(strict_types=1);

$root = dirname(__DIR__, 2);
$contract = file_get_contents($root . '/docs/architecture/module-conventions.md');

if (!is_string($contract)) {
    throw new RuntimeException('Module convention contract is missing.');
}

foreach (['Api/', 'Application/', 'Domain/', 'Infrastructure/', 'TenantContext', 'audit', 'vertical slice'] as $required) {
    if (stripos($contract, $required) === false) {
        throw new RuntimeException("Module convention is missing {$required}.");
    }
}

$referenceSlice = [
    'espocrm/custom/Espo/Custom/Tools/Signup/Api/PostSignup.php',
    'espocrm/custom/Espo/Custom/Tools/Signup/SignupService.php',
    'espocrm/custom/Espo/Custom/Tools/Signup/SignupValidator.php',
    'tests/signup/SignupValidatorTest.php',
];

foreach ($referenceSlice as $relative) {
    if (!is_file($root . '/' . $relative)) {
        throw new RuntimeException("Reference vertical slice file is missing: {$relative}");
    }
}

echo "Module convention tests passed.\n";
