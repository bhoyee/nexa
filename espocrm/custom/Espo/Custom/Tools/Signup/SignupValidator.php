<?php

namespace Espo\Custom\Tools\Signup;

use DateTimeZone;
use stdClass;

/** Normalizes each progressive-onboarding step before persistence. */
final class SignupValidator
{
    private const PLAN_KEYS = ['launch', 'growth', 'scale'];

    /** @return array{email:string,plan:?string} */
    public function validateStart(stdClass $input): array
    {
        $email = strtolower(trim((string) ($input->email ?? '')));
        $plan = $this->plan((string) ($input->plan ?? ''), false);
        if (strlen($email) > 190 || filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            throw new SignupProblem(422, 'validation_failed', 'Enter a valid work email address.', ['email' => 'Enter a valid work email address.']);
        }
        return ['email' => $email, 'plan' => $plan];
    }

    /** @param array{firstName?:string,lastName?:string} $defaults @return array<string,mixed> */
    public function validateCompletion(stdClass $input, string $method, array $defaults = []): array
    {
        $fields = [];
        $plan = $this->plan((string) ($input->plan ?? ''), true, $fields);
        $company = trim((string) ($input->company ?? ''));
        $firstName = trim((string) ($input->firstName ?? ($defaults['firstName'] ?? '')));
        $lastName = trim((string) ($input->lastName ?? ($defaults['lastName'] ?? '')));
        $timezone = trim((string) ($input->timezone ?? 'UTC')) ?: 'UTC';
        $password = (string) ($input->password ?? '');
        $confirmation = (string) ($input->confirmPassword ?? '');

        if (mb_strlen($company) < 2 || mb_strlen($company) > 120) $fields['company'] = 'Company name must contain 2 to 120 characters.';
        if (mb_strlen($firstName) < 2 || mb_strlen($firstName) > 100) $fields['firstName'] = 'First name must contain 2 to 100 characters.';
        if (mb_strlen($lastName) < 2 || mb_strlen($lastName) > 100) $fields['lastName'] = 'Last name must contain 2 to 100 characters.';
        if ($method === 'email' && !$this->isStrongPassword($password)) $fields['password'] = 'Use at least 12 characters with uppercase, lowercase and a number.';
        if ($method === 'email' && !hash_equals($password, $confirmation)) $fields['confirmPassword'] = 'Passwords do not match.';
        if (($input->terms ?? false) !== true) $fields['terms'] = 'Accept the terms to create a workspace.';
        if (($input->website ?? '') !== '') throw new SignupProblem(400, 'invalid_request', 'The request could not be accepted.');
        if (!in_array($timezone, DateTimeZone::listIdentifiers(), true)) $timezone = 'UTC';
        if ($fields !== []) throw new SignupProblem(422, 'validation_failed', 'Check the highlighted details.', $fields);

        return compact('plan', 'company', 'firstName', 'lastName', 'password', 'timezone');
    }

    /** @param array<string,string> $fields */
    private function plan(string $value, bool $required, array &$fields = []): ?string
    {
        $plan = strtolower(trim($value));
        if ($plan === '' && !$required) return null;
        if (!in_array($plan, self::PLAN_KEYS, true)) {
            $fields['plan'] = 'Select a valid plan.';
            if ($required) return '';
            throw new SignupProblem(422, 'validation_failed', 'Select a valid plan.', $fields);
        }
        return $plan;
    }

    private function isStrongPassword(string $password): bool
    {
        return strlen($password) >= 12 && strlen($password) <= 128
            && preg_match('/[a-z]/', $password) === 1
            && preg_match('/[A-Z]/', $password) === 1
            && preg_match('/[0-9]/', $password) === 1;
    }
}