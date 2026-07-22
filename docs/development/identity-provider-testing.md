# Identity Provider Testing

Nexa supports global Google and Microsoft social OIDC plus tenant-owned enterprise OIDC and SAML 2.0 providers. Provider configuration belongs to the tenant; deployment operators own the encryption key and runtime secrets.

## Local prerequisites

1. Run all shared-schema migrations, including `0008_identity_security.sql`.
2. Set `NEXA_AUTH_SECRET_KEY` in the ignored `.env` to a base64-encoded 32-byte random key.
3. Run `php scripts/dev/configure-auth-experience.php` so the key is copied into ignored internal runtime configuration.
4. Keep private keys, client secrets and production certificates outside Git.

## OIDC test provider

Use a dedicated test tenant in Keycloak, Okta, Entra ID or another standards-compliant provider. Register this callback:

`http://nexa.local/api/v1/Nexa/auth/sso/PROVIDER_ID/oidc/callback`

Configure the tenant provider:

```powershell
php espocrm/bin/configure-identity-provider.php `
  --tenant=isolation-alpha --protocol=oidc --key=local-oidc `
  --name="Local OIDC" --issuer=https://idp.example.test/realms/nexa `
  --domains=example.test --client-id=nexa-local --client-secret=LOCAL_SECRET `
  --authorization-endpoint=https://idp.example.test/realms/nexa/protocol/openid-connect/auth `
  --token-endpoint=https://idp.example.test/realms/nexa/protocol/openid-connect/token `
  --jwks-endpoint=https://idp.example.test/realms/nexa/protocol/openid-connect/certs
```

The provider must issue RS256 ID tokens containing `iss`, `aud`, `sub`, `exp`, `nonce` and the configured email claim.
A company email domain can belong to only one tenant provider; configuration fails safely if another tenant already owns it.

## SAML test provider

Create a SAML 2.0 service-provider integration with:

- Entity ID: `http://nexa.local/saml/metadata/PROVIDER_ID`
- ACS: `http://nexa.local/api/v1/Nexa/auth/sso/PROVIDER_ID/saml/acs`
- Binding: HTTP-POST for the response
- Signed assertions: required
- NameID: stable user identity; email is supplied as a mapped attribute

Export only the IdP public X.509 certificate, then run:

```powershell
php espocrm/bin/configure-identity-provider.php `
  --tenant=isolation-alpha --protocol=saml --key=local-saml `
  --name="Local SAML" --issuer=https://idp.example.test/saml/metadata `
  --domains=example.test --sso-url=https://idp.example.test/saml/sso `
  --certificate-file=C:\keys\idp-public.crt --email-claim=email
```

When `--require-mfa=true`, OIDC must return an `amr` value such as `mfa` or `otp`. SAML must return the requested authentication context. Override its default TOTP context with `--mfa-context=URI` when the tenant IdP uses a different MFA context URI. Enable a tenant-wide MFA policy only after its users have enrolled, otherwise password login is intentionally denied.

## Acceptance checks

- Discovery returns the same provider choices for any address in an allowed domain.
- A callback with the wrong state, request ID, issuer, audience, destination, nonce, signature or expired assertion fails.
- Replaying a valid callback fails because its state is already consumed.
- A matching email never links an unknown provider subject to an existing user.
- TOTP accepts a current authenticator code; each recovery code works only once.
- Repeated password or MFA failures trigger Espo's configured lockout.
- Success, challenge, failure and recovery-code use create tenant-scoped audit events.

Run `powershell -File scripts/dev/verify.ps1 -Ci` before opening a pull request.
