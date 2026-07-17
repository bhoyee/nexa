<?php

declare(strict_types=1);

require dirname(__DIR__, 2) . '/espocrm/custom/Espo/Custom/Tools/Signup/SignupProblem.php';
require dirname(__DIR__, 2) . '/espocrm/custom/Espo/Custom/Tools/Signup/SignupValidator.php';

use Espo\Custom\Tools\Signup\SignupProblem;
use Espo\Custom\Tools\Signup\SignupValidator;

function expectSignup(bool $condition, string $message): void
{
    if (!$condition) {
        throw new RuntimeException($message);
    }
}

$validator = new SignupValidator();
$valid = (object) [
    'plan' => 'Growth',
    'company' => 'Acme Revenue Ltd',
    'firstName' => 'Ada',
    'lastName' => 'Lovelace',
    'email' => '  OWNER@EXAMPLE.TEST ',
    'password' => 'A-strong-password-2026',
    'confirmPassword' => 'A-strong-password-2026',
    'timezone' => 'Europe/London',
    'terms' => true,
    'website' => '',
];

$data = $validator->validate($valid);
expectSignup($data['plan'] === 'growth', 'Plan should be normalized.');
expectSignup($data['email'] === 'owner@example.test', 'Email should be globally comparable.');
expectSignup($data['timezone'] === 'Europe/London', 'Valid timezone should be retained.');

$invalid = clone $valid;
$invalid->email = 'not-an-email';
$invalid->password = 'weak';
$invalid->confirmPassword = 'different';
$invalid->terms = false;

try {
    $validator->validate($invalid);
    throw new RuntimeException('Invalid signup should fail.');
} catch (SignupProblem $e) {
    expectSignup($e->status === 422, 'Invalid signup should return 422.');
    expectSignup(isset($e->fields['email']), 'Email error is missing.');
    expectSignup(isset($e->fields['password']), 'Password error is missing.');
    expectSignup(isset($e->fields['confirmPassword']), 'Confirmation error is missing.');
    expectSignup(isset($e->fields['terms']), 'Terms error is missing.');
}

$timezoneFallback = clone $valid;
$timezoneFallback->timezone = 'Invalid/Timezone';
expectSignup($validator->validate($timezoneFallback)['timezone'] === 'UTC', 'Invalid timezone should fall back to UTC.');

echo "Signup validator tests passed.\n";
