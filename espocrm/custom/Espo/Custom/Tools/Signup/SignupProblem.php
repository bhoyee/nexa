<?php

namespace Espo\Custom\Tools\Signup;

use RuntimeException;

final class SignupProblem extends RuntimeException
{
    /** @param array<string, string> $fields */
    public function __construct(
        public readonly int $status,
        public readonly string $error,
        string $message,
        public readonly array $fields = [],
    ) {
        parent::__construct($message);
    }
}
