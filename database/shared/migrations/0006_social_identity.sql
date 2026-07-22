CREATE TABLE IF NOT EXISTS nexa_social_auth_attempt (
    id CHAR(36) NOT NULL,
    provider VARCHAR(32) NOT NULL,
    intent VARCHAR(16) NOT NULL,
    state_hash CHAR(64) NOT NULL,
    nonce_hash CHAR(64) NOT NULL,
    payload_json JSON NOT NULL,
    expires_at DATETIME(6) NOT NULL,
    consumed_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_nexa_social_auth_state (state_hash),
    KEY idx_nexa_social_auth_expiry (expires_at, consumed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS nexa_external_identity (
    id CHAR(36) NOT NULL,
    tenant_id CHAR(36) NOT NULL,
    user_id VARCHAR(24) NOT NULL,
    provider VARCHAR(32) NOT NULL,
    provider_subject VARCHAR(191) NOT NULL,
    normalized_email VARCHAR(190) NOT NULL,
    profile_json JSON NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    last_login_at DATETIME(6) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_nexa_external_provider_subject (provider, provider_subject),
    UNIQUE KEY uq_nexa_external_user_provider (tenant_id, user_id, provider),
    KEY idx_nexa_external_tenant (tenant_id),
    CONSTRAINT fk_nexa_external_identity_tenant FOREIGN KEY (tenant_id) REFERENCES nexa_tenant (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
