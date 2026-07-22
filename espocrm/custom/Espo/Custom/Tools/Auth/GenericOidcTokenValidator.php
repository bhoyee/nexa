<?php

namespace Espo\Custom\Tools\Auth;

use Espo\Core\Authentication\Jwt\DefaultKeyFactory;
use Espo\Core\Authentication\Jwt\SignatureVerifiers\Rsa;
use Espo\Core\Authentication\Jwt\Token;
use Espo\Core\Authentication\Jwt\Validator;
use RuntimeException;
use stdClass;

/** Validates tenant OIDC tokens against an explicitly owned issuer and JWKS URL. */
final class GenericOidcTokenValidator
{
    public function __construct(private Validator $timeValidator) {}

    /** @param array<string, mixed> $provider @return array{subject:string,email:string,firstName:string,lastName:string,picture:string} */
    public function validate(Token $token, array $provider, string $nonceHash): array
    {
        $claims = $token->getPayload();
        $issuer = rtrim((string) $provider['issuer'], '/');
        if ($token->getHeader()->getAlg() !== 'RS256' ||
            !hash_equals($issuer, rtrim((string) $claims->getIss(), '/')) ||
            !in_array((string) $provider['client_id'], $claims->getAud(), true) ||
            !hash_equals($nonceHash, hash('sha256', (string) $claims->getNonce()))) {
            throw new RuntimeException('OIDC identity validation failed.');
        }

        $this->timeValidator->validate($token);
        if (!(new Rsa('RS256', $this->loadKeys((string) $provider['jwks_endpoint'])))->verify($token)) {
            throw new RuntimeException('OIDC signature was not verified.');
        }
        if ((bool) $provider['require_mfa']) {
            $methods = $claims->get('amr');
            $methods = is_array($methods) ? array_map('strtolower', array_map('strval', $methods)) : [];
            if (array_intersect($methods, ['mfa', 'otp', 'hwk', 'swk']) === []) {
                throw new RuntimeException('OIDC provider did not prove a multi-factor authentication method.');
            }
        }

        $mapping = (array) $provider['attribute_mapping'];
        $emailClaim = $mapping['email'] ?? 'email';
        $email = strtolower(trim((string) $claims->get($emailClaim)));
        $subject = trim((string) $claims->getSub());
        if ($subject === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new RuntimeException('OIDC provider did not return a usable identity.');
        }

        return [
            'subject' => $subject,
            'email' => $email,
            'firstName' => trim((string) $claims->get($mapping['firstName'] ?? 'given_name')),
            'lastName' => trim((string) $claims->get($mapping['lastName'] ?? 'family_name')),
            'picture' => trim((string) $claims->get($mapping['picture'] ?? 'picture')),
        ];
    }

    /** @return list<\Espo\Core\Authentication\Jwt\Key> */
    private function loadKeys(string $endpoint): array
    {
        if (!str_starts_with($endpoint, 'https://')) {
            throw new RuntimeException('OIDC JWKS endpoint must use HTTPS.');
        }
        $curl = curl_init($endpoint);
        curl_setopt_array($curl, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 10,
            CURLOPT_PROTOCOLS => CURLPROTO_HTTPS,
            CURLOPT_FOLLOWLOCATION => false,
        ]);
        $response = curl_exec($curl);
        $status = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        $error = curl_error($curl);
        curl_close($curl);
        $decoded = is_string($response) ? json_decode($response) : null;
        if ($error !== '' || $status !== 200 || !$decoded instanceof stdClass || !is_array($decoded->keys ?? null)) {
            throw new RuntimeException('OIDC signing keys are unavailable.');
        }

        $factory = new DefaultKeyFactory();
        $keys = [];
        foreach ($decoded->keys as $raw) {
            if ($raw instanceof stdClass && ($raw->kty ?? null) === 'RSA') {
                $keys[] = $factory->create($raw);
            }
        }
        if ($keys === []) {
            throw new RuntimeException('OIDC provider published no supported signing key.');
        }

        return $keys;
    }
}
