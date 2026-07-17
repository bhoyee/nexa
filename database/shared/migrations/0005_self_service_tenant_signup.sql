-- Self-service tenant registration and globally unique owner identities.

ALTER TABLE `user`
    MODIFY COLUMN user_name VARCHAR(190) NOT NULL;

-- Tenant users remain tenant-scoped, but a self-service owner email is a
-- platform identity. The normalized_email unique key guarantees that one
-- address cannot own two tenants even under concurrent signup requests.
CREATE TABLE nexa_tenant_owner_identity (
    id CHAR(36) NOT NULL,
    tenant_id CHAR(36) NOT NULL,
    owner_user_id VARCHAR(17) NOT NULL,
    email VARCHAR(190) NOT NULL,
    normalized_email VARCHAR(190) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'pending_verification',
    verification_token_hash CHAR(64) NULL,
    verification_expires_at DATETIME(6) NULL,
    verified_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_nexa_owner_tenant (tenant_id),
    UNIQUE KEY uq_nexa_owner_user (owner_user_id),
    UNIQUE KEY uq_nexa_owner_email (normalized_email),
    UNIQUE KEY uq_nexa_owner_verification_token (verification_token_hash),
    CONSTRAINT fk_nexa_owner_tenant FOREIGN KEY (tenant_id) REFERENCES nexa_tenant (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Public endpoint throttling must be shared by every PHP worker. Only a keyed
-- request fingerprint is stored; raw IP addresses and user agents are not.
CREATE TABLE nexa_signup_rate_limit (
    fingerprint_hash CHAR(64) NOT NULL,
    action_key VARCHAR(32) NOT NULL,
    window_started_at DATETIME(6) NOT NULL,
    attempt_count INT UNSIGNED NOT NULL DEFAULT 0,
    blocked_until DATETIME(6) NULL,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (fingerprint_hash, action_key),
    KEY ix_nexa_signup_rate_blocked (blocked_until)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX ix_nexa_owner_status_expiry
    ON nexa_tenant_owner_identity (status, verification_expires_at);
