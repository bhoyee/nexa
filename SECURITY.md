# Security Policy

## Supported Version

The project is in pre-release development. Security fixes are applied to the `main` branch. No production support commitment exists until a versioned release is published.

## Reporting a Vulnerability

Do not open a public issue containing vulnerability details, credentials or customer data.

Use GitHub's private vulnerability reporting feature in the repository Security tab. Include:

- Affected version or commit.
- Reproduction steps.
- Expected and observed behavior.
- Potential tenant-isolation or data impact.
- Suggested mitigation, if known.

The maintainers will acknowledge a complete report, assess severity and coordinate disclosure. Never test against systems or data you do not own or have explicit authorization to access.

## Credentials

If a secret is committed, consider it compromised. Revoke and rotate it immediately, then remove it from current files and Git history using a coordinated repository rewrite.
