<?php

namespace Espo\Custom\Tools\Auth;

use RuntimeException;

final class AuthProblem extends RuntimeException
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
