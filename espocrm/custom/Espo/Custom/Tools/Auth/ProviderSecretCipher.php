<?php

namespace Espo\Custom\Tools\Auth;

use Espo\Core\Utils\Config;
use RuntimeException;

/** Encrypts tenant provider credentials with the deployment-owned master key. */
final class ProviderSecretCipher
{
    public function __construct(private Config $config) {}

    public function encrypt(string $secret): string
    {
        $nonce = random_bytes(12);
        $tag = '';
        $ciphertext = openssl_encrypt(
            $secret,
            'aes-256-gcm',
            $this->key(),
            OPENSSL_RAW_DATA,
            $nonce,
            $tag,
        );
        if ($ciphertext === false) {
            throw new RuntimeException('Identity-provider secret could not be encrypted.');
        }

        return base64_encode($nonce . $tag . $ciphertext);
    }

    public function decrypt(?string $encrypted): string
    {
        if ($encrypted === null || $encrypted === '') {
            return '';
        }

        $payload = base64_decode($encrypted, true);
        if ($payload === false || strlen($payload) <= 28) {
            throw new RuntimeException('Identity-provider secret is malformed.');
        }

        $plain = openssl_decrypt(
            substr($payload, 28),
            'aes-256-gcm',
            $this->key(),
            OPENSSL_RAW_DATA,
            substr($payload, 0, 12),
            substr($payload, 12, 16),
        );
        if ($plain === false) {
            throw new RuntimeException('Identity-provider secret could not be decrypted.');
        }

        return $plain;
    }

    private function key(): string
    {
        $encoded = trim((string) (getenv('NEXA_AUTH_SECRET_KEY') ?: $this->config->get('nexaAuthSecretKey', '')));
        $key = base64_decode($encoded, true);
        if ($key === false || strlen($key) !== 32) {
            throw new RuntimeException('NEXA_AUTH_SECRET_KEY must be a base64-encoded 32-byte key.');
        }

        return $key;
    }
}
