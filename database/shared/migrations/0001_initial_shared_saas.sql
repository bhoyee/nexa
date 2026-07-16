-- Nexa shared-schema SaaS foundation.
-- Apply this migration to the same logical database that contains EspoCRM.

CREATE TABLE nexa_schema_migration (
    migration_id VARCHAR(190) NOT NULL,
    checksum_sha256 CHAR(64) NOT NULL,
    applied_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    execution_ms INT UNSIGNED NULL,
    applied_by VARCHAR(128) NOT NULL DEFAULT 'repository',
    PRIMARY KEY (migration_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE nexa_tenant (
    id CHAR(36) NOT NULL,
    slug VARCHAR(63) NOT NULL,
    display_name VARCHAR(190) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'provisioning',
    region VARCHAR(32) NOT NULL DEFAULT 'eu-west',
    timezone VARCHAR(64) NOT NULL DEFAULT 'UTC',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_nexa_tenant_slug (slug),
    KEY ix_nexa_tenant_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE nexa_tenant_domain (
    id CHAR(36) NOT NULL,
    tenant_id CHAR(36) NOT NULL,
    hostname VARCHAR(253) NOT NULL,
    domain_type VARCHAR(32) NOT NULL DEFAULT 'subdomain',
    verification_status VARCHAR(32) NOT NULL DEFAULT 'pending',
    is_primary TINYINT(1) NOT NULL DEFAULT 0,
    verified_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_nexa_tenant_domain_hostname (hostname),
    KEY ix_nexa_tenant_domain_tenant (tenant_id),
    CONSTRAINT fk_nexa_tenant_domain_tenant FOREIGN KEY (tenant_id) REFERENCES nexa_tenant (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE nexa_service_definition (
    id CHAR(36) NOT NULL,
    service_key VARCHAR(128) NOT NULL,
    display_name VARCHAR(128) NOT NULL,
    description VARCHAR(255) NOT NULL,
    measurement_unit VARCHAR(32) NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'active',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_nexa_service_key (service_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE nexa_plan_definition (
    id CHAR(36) NOT NULL,
    plan_key VARCHAR(64) NOT NULL,
    display_name VARCHAR(128) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'active',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_nexa_plan_key (plan_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE nexa_plan_service (
    plan_id CHAR(36) NOT NULL,
    service_id CHAR(36) NOT NULL,
    is_enabled TINYINT(1) NOT NULL DEFAULT 0,
    soft_limit BIGINT UNSIGNED NULL,
    hard_limit BIGINT UNSIGNED NULL,
    configuration_json JSON NULL,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (plan_id, service_id),
    CONSTRAINT fk_nexa_plan_service_plan FOREIGN KEY (plan_id) REFERENCES nexa_plan_definition (id),
    CONSTRAINT fk_nexa_plan_service_service FOREIGN KEY (service_id) REFERENCES nexa_service_definition (id),
    CONSTRAINT ck_nexa_plan_service_limits CHECK (hard_limit IS NULL OR soft_limit IS NULL OR hard_limit >= soft_limit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE nexa_tenant_subscription (
    id CHAR(36) NOT NULL,
    tenant_id CHAR(36) NOT NULL,
    plan_id CHAR(36) NOT NULL,
    status VARCHAR(32) NOT NULL,
    provider VARCHAR(32) NULL,
    provider_customer_ref VARCHAR(190) NULL,
    provider_subscription_ref VARCHAR(190) NULL,
    period_starts_at DATETIME(6) NULL,
    period_ends_at DATETIME(6) NULL,
    trial_ends_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_nexa_subscription_tenant (tenant_id),
    UNIQUE KEY uq_nexa_subscription_provider_ref (provider, provider_subscription_ref),
    CONSTRAINT fk_nexa_subscription_tenant FOREIGN KEY (tenant_id) REFERENCES nexa_tenant (id),
    CONSTRAINT fk_nexa_subscription_plan FOREIGN KEY (plan_id) REFERENCES nexa_plan_definition (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE nexa_tenant_service (
    tenant_id CHAR(36) NOT NULL,
    service_id CHAR(36) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'active',
    soft_limit_override BIGINT UNSIGNED NULL,
    hard_limit_override BIGINT UNSIGNED NULL,
    configuration_json JSON NULL,
    starts_at DATETIME(6) NULL,
    ends_at DATETIME(6) NULL,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (tenant_id, service_id),
    KEY ix_nexa_tenant_service_status (tenant_id, status),
    CONSTRAINT fk_nexa_tenant_service_tenant FOREIGN KEY (tenant_id) REFERENCES nexa_tenant (id),
    CONSTRAINT fk_nexa_tenant_service_service FOREIGN KEY (service_id) REFERENCES nexa_service_definition (id),
    CONSTRAINT ck_nexa_tenant_service_limits CHECK (hard_limit_override IS NULL OR soft_limit_override IS NULL OR hard_limit_override >= soft_limit_override)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE nexa_usage_counter (
    tenant_id CHAR(36) NOT NULL,
    service_id CHAR(36) NOT NULL,
    period_key VARCHAR(32) NOT NULL,
    quantity BIGINT UNSIGNED NOT NULL DEFAULT 0,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (tenant_id, service_id, period_key),
    CONSTRAINT fk_nexa_usage_tenant FOREIGN KEY (tenant_id) REFERENCES nexa_tenant (id),
    CONSTRAINT fk_nexa_usage_service FOREIGN KEY (service_id) REFERENCES nexa_service_definition (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE nexa_provisioning_operation (
    id CHAR(36) NOT NULL,
    tenant_id CHAR(36) NOT NULL,
    operation_type VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL,
    idempotency_key VARCHAR(128) NOT NULL,
    attempt_count INT UNSIGNED NOT NULL DEFAULT 0,
    last_error_code VARCHAR(64) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    completed_at DATETIME(6) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_nexa_provisioning_idempotency (idempotency_key),
    KEY ix_nexa_provisioning_tenant_status (tenant_id, status),
    CONSTRAINT fk_nexa_provisioning_tenant FOREIGN KEY (tenant_id) REFERENCES nexa_tenant (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE nexa_audit_event (
    id CHAR(36) NOT NULL,
    tenant_id CHAR(36) NOT NULL,
    service_id CHAR(36) NULL,
    actor_type VARCHAR(32) NOT NULL,
    actor_user_id CHAR(36) NULL,
    action VARCHAR(128) NOT NULL,
    subject_type VARCHAR(128) NULL,
    subject_id CHAR(36) NULL,
    request_id CHAR(36) NULL,
    correlation_id CHAR(36) NULL,
    source VARCHAR(64) NOT NULL,
    metadata_json JSON NULL,
    occurred_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY ix_nexa_audit_tenant_time (tenant_id, occurred_at),
    KEY ix_nexa_audit_subject (tenant_id, subject_type, subject_id),
    CONSTRAINT fk_nexa_audit_tenant FOREIGN KEY (tenant_id) REFERENCES nexa_tenant (id),
    CONSTRAINT fk_nexa_audit_service FOREIGN KEY (service_id) REFERENCES nexa_service_definition (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE nexa_outbox_event (
    id CHAR(36) NOT NULL,
    tenant_id CHAR(36) NOT NULL,
    service_id CHAR(36) NULL,
    event_type VARCHAR(128) NOT NULL,
    aggregate_type VARCHAR(128) NULL,
    aggregate_id CHAR(36) NULL,
    payload_version SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    payload_json JSON NOT NULL,
    correlation_id CHAR(36) NULL,
    occurred_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    available_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    published_at DATETIME(6) NULL,
    attempt_count INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    KEY ix_nexa_outbox_publish (published_at, available_at),
    KEY ix_nexa_outbox_tenant_time (tenant_id, occurred_at),
    CONSTRAINT fk_nexa_outbox_tenant FOREIGN KEY (tenant_id) REFERENCES nexa_tenant (id),
    CONSTRAINT fk_nexa_outbox_service FOREIGN KEY (service_id) REFERENCES nexa_service_definition (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
