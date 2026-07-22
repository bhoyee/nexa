<?php

namespace Espo\Custom\Tools\Auth;

use Espo\Core\Utils\Config;

/**
 * Publishes only providers whose switch and required credentials are present.
 */
final class AuthProviderRegistry
{
    private const PROVIDERS = [
        'google' => ['label' => 'Google', 'icon' => 'google'],
        'microsoft' => ['label' => 'Microsoft', 'icon' => 'microsoft'],
    ];

    public function __construct(private Config $config)
    {}

    /** @return list<array{key:string,label:string,icon:string,startUrl:string}> */
    public function getPublicProviders(): array
    {
        $configured = (array) $this->config->get('nexaPublicAuthProviders', []);
        foreach (['google', 'microsoft'] as $provider) {
            $environmentKey = 'NEXA_AUTH_' . strtoupper($provider) . '_ENABLED';
            if (getenv($environmentKey) !== false) {
                $configured[$provider] = filter_var(getenv($environmentKey), FILTER_VALIDATE_BOOL) === true;
            }
        }

        $googleClientId = trim((string) (getenv('NEXA_AUTH_GOOGLE_CLIENT_ID') ?: $this->config->get('oidcClientId', '')));
        $googleSecret = trim((string) (getenv('NEXA_AUTH_GOOGLE_CLIENT_SECRET') ?: $this->config->get('oidcClientSecret', '')));
        $configured['google'] = ($configured['google'] ?? false) === true && $googleClientId !== '' && $googleSecret !== '';
        // Microsoft is published only when its own callback implementation lands.
        $configured['microsoft'] = false;

        return self::normalize($configured);
    }

    /**
     * @param array<string, mixed> $configured
     * @return list<array{key:string,label:string,icon:string,startUrl:string}>
     */
    public static function normalize(array $configured): array
    {
        $result = [];

        foreach (self::PROVIDERS as $key => $definition) {
            if (($configured[$key] ?? false) !== true) {
                continue;
            }

            $result[] = [
                'key' => $key,
                'label' => $definition['label'],
                'icon' => $definition['icon'],
                'startUrl' => '/api/v1/Nexa/auth/provider/' . $key . '/start',
            ];
        }

        return $result;
    }
}
