<?php

namespace Espo\Custom\Tools\Signup;

use DateTimeZone;
use stdClass;

/**
 * Normalizes untrusted browser input into the narrow contract consumed by
 * SignupService. Database and provisioning code never reads the raw payload.
 */
final class SignupValidator
{
    private const PLAN_KEYS = ['launch', 'growth', 'scale'];

    /** @return array{plan:string,company:string,firstName:string,lastName:string,email:string,password:string,timezone:string} */
    public function validate(stdClass $input): array
    {
        $fields = [];
        $plan = strtolower(trim((string) ($input->plan ?? '')));
        $company = trim((string) ($input->company ?? ''));
        $firstName = trim((string) ($input->firstName ?? ''));
        $lastName = trim((string) ($input->lastName ?? ''));
        // Email is normalized once because it is used as both the login name
        // and the platform-wide uniqueness key.
        $email = strtolower(trim((string) ($input->email ?? '')));
        $password = (string) ($input->password ?? '');
        $confirmation = (string) ($input->confirmPassword ?? '');
        $timezone = trim((string) ($input->timezone ?? 'UTC')) ?: 'UTC';

        if (!in_array($plan, self::PLAN_KEYS, true)) {
            $fields['plan'] = 'Select a valid plan.';
        }
        if (mb_strlen($company) < 2 || mb_strlen($company) > 120) {
            $fields['company'] = 'Company name must contain 2 to 120 characters.';
        }
        if (mb_strlen($firstName) < 2 || mb_strlen($firstName) > 100) {
            $fields['firstName'] = 'First name must contain 2 to 100 characters.';
        }
        if (mb_strlen($lastName) < 2 || mb_strlen($lastName) > 100) {
            $fields['lastName'] = 'Last name must contain 2 to 100 characters.';
        }
        if (strlen($email) > 190 || filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            $fields['email'] = 'Enter a valid work email address.';
        }
        if (!$this->isStrongPassword($password)) {
            $fields['password'] = 'Use at least 12 characters with uppercase, lowercase and a number.';
        }
        if (!hash_equals($password, $confirmation)) {
            $fields['confirmPassword'] = 'Passwords do not match.';
        }
        if (($input->terms ?? false) !== true) {
            $fields['terms'] = 'Accept the terms to create a workspace.';
        }
        // Real users never see this field. A value indicates a basic form bot
        // and is rejected without disclosing which protection fired.
        if (($input->website ?? '') !== '') {
            throw new SignupProblem(400, 'invalid_request', 'The request could not be accepted.');
        }
        if (!in_array($timezone, DateTimeZone::listIdentifiers(), true)) {
            $timezone = 'UTC';
        }

        if ($fields !== []) {
            throw new SignupProblem(422, 'validation_failed', 'Check the highlighted details.', $fields);
        }

        return compact('plan', 'company', 'firstName', 'lastName', 'email', 'password', 'timezone');
    }

    private function isStrongPassword(string $password): bool
    {
        return strlen($password) >= 12 && strlen($password) <= 128
            && preg_match('/[a-z]/', $password) === 1
            && preg_match('/[A-Z]/', $password) === 1
            && preg_match('/[0-9]/', $password) === 1;
    }
}
