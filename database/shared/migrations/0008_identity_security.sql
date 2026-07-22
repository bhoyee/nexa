CREATE TABLE IF NOT EXISTS nexa_identity_provider (
    id CHAR(36) NOT NULL,
    tenant_id CHAR(36) NOT NULL,
    provider_key VARCHAR(64) NOT NULL,
    protocol VARCHAR(16) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    issuer VARCHAR(512) NOT NULL,
    client_id VARCHAR(255) NULL,
    encrypted_client_secret TEXT NULL,
    secret_key_version SMALLINT UNSIGNED NULL,
    authorization_endpoint VARCHAR(512) NULL,
    token_endpoint VARCHAR(512) NULL,
    userinfo_endpoint VARCHAR(512) NULL,
    jwks_endpoint VARCHAR(512) NULL,
    saml_sso_url VARCHAR(512) NULL,
    saml_x509_certificate TEXT NULL,
    allowed_email_domains JSON NOT NULL,
    attribute_mapping JSON NOT NULL,
    is_enabled TINYINT(1) NOT NULL DEFAULT 0,
    allow_signup TINYINT(1) NOT NULL DEFAULT 0,
    require_mfa TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_nexa_identity_provider_key (tenant_id, provider_key),
    UNIQUE KEY uq_nexa_identity_provider_tenant (id, tenant_id),
    KEY idx_nexa_identity_provider_discovery (tenant_id, is_enabled, protocol),
    CONSTRAINT fk_nexa_identity_provider_tenant FOREIGN KEY (tenant_id) REFERENCES nexa_tenant (id) ON DELETE CASCADE,
    CONSTRAINT chk_nexa_identity_provider_protocol CHECK (protocol IN ('oidc', 'saml'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS nexa_tenant_auth_policy (
    tenant_id CHAR(36) NOT NULL,
    allow_password_login TINYINT(1) NOT NULL DEFAULT 1,
    require_mfa TINYINT(1) NOT NULL DEFAULT 0,
    allow_self_service_linking TINYINT(1) NOT NULL DEFAULT 0,
    discovery_mode VARCHAR(16) NOT NULL DEFAULT 'email',
    default_provider_id CHAR(36) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (tenant_id),
    CONSTRAINT fk_nexa_tenant_auth_policy_tenant FOREIGN KEY (tenant_id) REFERENCES nexa_tenant (id) ON DELETE CASCADE,
    CONSTRAINT fk_nexa_tenant_auth_policy_provider FOREIGN KEY (default_provider_id) REFERENCES nexa_identity_provider (id) ON DELETE SET NULL,
    CONSTRAINT chk_nexa_tenant_auth_discovery CHECK (discovery_mode IN ('email', 'button', 'forced'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS nexa_identity_provider_domain (
    domain_name VARCHAR(190) NOT NULL,
    tenant_id CHAR(36) NOT NULL,
    provider_id CHAR(36) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (domain_name),
    UNIQUE KEY uq_nexa_identity_provider_domain (provider_id, domain_name),
    KEY idx_nexa_identity_domain_tenant (tenant_id, provider_id),
    CONSTRAINT fk_nexa_identity_domain_tenant FOREIGN KEY (tenant_id) REFERENCES nexa_tenant (id) ON DELETE CASCADE,
    CONSTRAINT fk_nexa_identity_domain_provider FOREIGN KEY (provider_id, tenant_id) REFERENCES nexa_identity_provider (id, tenant_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS nexa_identity_link_request (
    id CHAR(36) NOT NULL,
    tenant_id CHAR(36) NOT NULL,
    user_id VARCHAR(24) NOT NULL,
    provider_id CHAR(36) NOT NULL,
    provider_subject VARCHAR(191) NOT NULL,
    normalized_email VARCHAR(190) NOT NULL,
    approval_token_hash CHAR(64) NOT NULL,
    expires_at DATETIME(6) NOT NULL,
    approved_at DATETIME(6) NULL,
    consumed_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_nexa_identity_link_token (approval_token_hash),
    UNIQUE KEY uq_nexa_identity_link_subject (provider_id, provider_subject),
    KEY idx_nexa_identity_link_tenant_user (tenant_id, user_id, expires_at),
    CONSTRAINT fk_nexa_identity_link_tenant FOREIGN KEY (tenant_id) REFERENCES nexa_tenant (id) ON DELETE CASCADE,
    CONSTRAINT fk_nexa_identity_link_provider FOREIGN KEY (provider_id) REFERENCES nexa_identity_provider (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS nexa_mfa_recovery_code (
    id CHAR(36) NOT NULL,
    tenant_id CHAR(36) NOT NULL,
    user_id VARCHAR(24) NOT NULL,
    code_hash VARCHAR(255) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    consumed_at DATETIME(6) NULL,
    PRIMARY KEY (id),
    KEY idx_nexa_mfa_recovery_user (tenant_id, user_id, consumed_at),
    CONSTRAINT fk_nexa_mfa_recovery_tenant FOREIGN KEY (tenant_id) REFERENCES nexa_tenant (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE nexa_social_auth_attempt MODIFY provider VARCHAR(64) NOT NULL;
ALTER TABLE nexa_external_identity MODIFY provider VARCHAR(64) NOT NULL;
ALTER TABLE nexa_signup_attempt MODIFY provider VARCHAR(64) NULL;
