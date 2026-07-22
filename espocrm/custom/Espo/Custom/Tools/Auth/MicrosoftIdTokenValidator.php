<?php

namespace Espo\Custom\Tools\Auth;

use Espo\Core\Authentication\Jwt\DefaultKeyFactory;
use Espo\Core\Authentication\Jwt\SignatureVerifiers\Rsa;
use Espo\Core\Authentication\Jwt\Token;
use Espo\Core\Authentication\Jwt\Validator;
use RuntimeException;
use stdClass;

/** Validates Microsoft v2 ID tokens against Microsoft's signed JWKS. */
final class MicrosoftIdTokenValidator
{
    public function __construct(private Validator $timeValidator)
    {}

    /** @return array{subject:string,email:string,firstName:string,lastName:string,picture:string} */
    public function validate(Token $token, string $clientId, string $tenant, string $nonceHash): array
    {
        $claims = $token->getPayload();
        $tenantId = strtolower(trim((string) $claims->get('tid')));
        $issuer = 'https://login.microsoftonline.com/' . $tenantId . '/v2.0';

        if ($token->getHeader()->getAlg() !== 'RS256' || $tenantId === '' ||
            !hash_equals($issuer, (string) $claims->getIss()) ||
            !in_array($clientId, $claims->getAud(), true) ||
            !hash_equals($nonceHash, hash('sha256', (string) $claims->getNonce()))) {
            throw new RuntimeException('Microsoft identity validation failed.');
        }

        $tenant = strtolower(trim($tenant));
        if (!in_array($tenant, ['common', 'organizations'], true) && !hash_equals($tenant, $tenantId)) {
            throw new RuntimeException('Microsoft tenant is not allowed.');
        }

        $this->timeValidator->validate($token);
        $keys = $this->loadKeys($tenant === 'common' ? 'common' : $tenantId);
        if (!(new Rsa('RS256', $keys))->verify($token)) {
            throw new RuntimeException('Microsoft token signature was not verified.');
        }

        $email = strtolower(trim((string) ($claims->get('email') ?: $claims->get('preferred_username'))));
        $subject = trim((string) $claims->getSub());
        if ($subject === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new RuntimeException('Microsoft did not return a usable email identity.');
        }

        return [
            'subject' => $subject,
            'email' => $email,
            'firstName' => trim((string) $claims->get('given_name')),
            'lastName' => trim((string) $claims->get('family_name')),
            'picture' => '',
        ];
    }

    /** @return list<\Espo\Core\Authentication\Jwt\Key> */
    private function loadKeys(string $tenant): array
    {
        if (!preg_match('/^[a-z0-9.-]+$/', $tenant)) {
            throw new RuntimeException('Invalid Microsoft tenant configuration.');
        }

        $curl = curl_init('https://login.microsoftonline.com/' . $tenant . '/discovery/v2.0/keys');
        curl_setopt_array($curl, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 10,
            CURLOPT_PROTOCOLS => CURLPROTO_HTTPS,
        ]);
        $response = curl_exec($curl);
        $status = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        $error = curl_error($curl);
        curl_close($curl);
        $decoded = is_string($response) ? json_decode($response) : null;
        if ($error !== '' || $status !== 200 || !$decoded instanceof stdClass || !is_array($decoded->keys ?? null)) {
            throw new RuntimeException('Microsoft signing keys are unavailable.');
        }

        $factory = new DefaultKeyFactory();
        $keys = [];
        foreach ($decoded->keys as $raw) {
            if ($raw instanceof stdClass && ($raw->kty ?? null) === 'RSA') {
                $keys[] = $factory->create($raw);
            }
        }
        return $keys;
    }
}