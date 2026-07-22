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
$start = $validator->validateStart((object) [
    'email' => '  OWNER@EXAMPLE.TEST ',
    'plan' => 'Growth',
]);
expectSignup($start['email'] === 'owner@example.test', 'Email should be globally comparable.');
expectSignup($start['plan'] === 'growth', 'Plan should be normalized at signup start.');

$emailCompletion = (object) [
    'plan' => 'Growth',
    'company' => 'Acme Revenue Ltd',
    'firstName' => 'Ada',
    'lastName' => 'Lovelace',
    'password' => 'A-strong-password-2026',
    'confirmPassword' => 'A-strong-password-2026',
    'timezone' => 'Europe/London',
    'terms' => true,
    'website' => '',
];
$data = $validator->validateCompletion($emailCompletion, 'email');
expectSignup($data['plan'] === 'growth', 'Completion plan should be normalized.');
expectSignup($data['timezone'] === 'Europe/London', 'Valid timezone should be retained.');

$socialCompletion = (object) [
    'plan' => 'launch',
    'company' => 'Analytical Engines Ltd',
    'timezone' => 'Invalid/Timezone',
    'terms' => true,
];
$social = $validator->validateCompletion($socialCompletion, 'social', [
    'firstName' => 'Ada',
    'lastName' => 'Lovelace',
]);
expectSignup($social['firstName'] === 'Ada', 'Social identity names should supply completion defaults.');
expectSignup($social['timezone'] === 'UTC', 'Invalid timezone should fall back to UTC.');

try {
    $validator->validateStart((object) ['email' => 'not-an-email']);
    throw new RuntimeException('Invalid signup start should fail.');
} catch (SignupProblem $e) {
    expectSignup($e->status === 422, 'Invalid signup start should return 422.');
    expectSignup(isset($e->fields['email']), 'Email error is missing.');
}

$invalid = clone $emailCompletion;
$invalid->password = 'weak';
$invalid->confirmPassword = 'different';
$invalid->terms = false;
try {
    $validator->validateCompletion($invalid, 'email');
    throw new RuntimeException('Invalid signup completion should fail.');
} catch (SignupProblem $e) {
    expectSignup(isset($e->fields['password']), 'Password error is missing.');
    expectSignup(isset($e->fields['confirmPassword']), 'Confirmation error is missing.');
    expectSignup(isset($e->fields['terms']), 'Terms error is missing.');
}

echo "Signup validator tests passed.\n";