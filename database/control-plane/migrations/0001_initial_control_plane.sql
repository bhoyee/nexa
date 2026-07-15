-- Shared SaaS control plane. Never store tenant CRM records here.

CREATE TABLE tenant (
    id CHAR(36) NOT NULL,
    slug VARCHAR(63) NOT NULL,
    display_name VARCHAR(190) NOT NULL,
    status VARCHAR(32) NOT NULL,
    region VARCHAR(32) NOT NULL DEFAULT 'eu-west',
    timezone VARCHAR(64) NOT NULL DEFAULT 'UTC',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_tenant_slug (slug),
    KEY ix_tenant_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE cell (
    id CHAR(36) NOT NULL,
    cell_key VARCHAR(64) NOT NULL,
    region VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'active',
    capacity_weight INT UNSIGNED NOT NULL DEFAULT 100,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_cell_key (cell_key),
    KEY ix_cell_region_status (region, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE database_cluster (
    id CHAR(36) NOT NULL,
    cell_id CHAR(36) NOT NULL,
    cluster_key VARCHAR(64) NOT NULL,
    writer_host VARCHAR(253) NOT NULL,
    writer_port SMALLINT UNSIGNED NOT NULL DEFAULT 3306,
    platform VARCHAR(32) NOT NULL DEFAULT 'mariadb',
    status VARCHAR(32) NOT NULL DEFAULT 'active',
    administrator_secret_ref VARCHAR(255) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_database_cluster_key (cluster_key),
    KEY ix_database_cluster_cell_status (cell_id, status),
    CONSTRAINT fk_database_cluster_cell FOREIGN KEY (cell_id) REFERENCES cell (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tenant_placement (
    tenant_id CHAR(36) NOT NULL,
    cell_id CHAR(36) NOT NULL,
    database_cluster_id CHAR(36) NOT NULL,
    database_name VARCHAR(128) NOT NULL,
    credential_secret_ref VARCHAR(255) NOT NULL,
    schema_version VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'provisioning',
    last_migrated_at DATETIME(6) NULL,
    last_backup_at DATETIME(6) NULL,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (tenant_id),
    UNIQUE KEY uq_tenant_placement_database (database_cluster_id, database_name),
    KEY ix_tenant_placement_cell_status (cell_id, status),
    CONSTRAINT fk_tenant_placement_tenant FOREIGN KEY (tenant_id) REFERENCES tenant (id),
    CONSTRAINT fk_tenant_placement_cell FOREIGN KEY (cell_id) REFERENCES cell (id),
    CONSTRAINT fk_tenant_placement_cluster FOREIGN KEY (database_cluster_id) REFERENCES database_cluster (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tenant_domain (
    id CHAR(36) NOT NULL,
    tenant_id CHAR(36) NOT NULL,
    hostname VARCHAR(253) NOT NULL,
    domain_type VARCHAR(32) NOT NULL,
    verification_status VARCHAR(32) NOT NULL DEFAULT 'pending',
    is_primary TINYINT(1) NOT NULL DEFAULT 0,
    verified_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_tenant_domain_hostname (hostname),
    KEY ix_tenant_domain_tenant (tenant_id),
    CONSTRAINT fk_tenant_domain_tenant FOREIGN KEY (tenant_id) REFERENCES tenant (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE plan_definition (
    id CHAR(36) NOT NULL,
    plan_key VARCHAR(64) NOT NULL,
    display_name VARCHAR(128) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'active',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_plan_definition_key (plan_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE feature_definition (
    id CHAR(36) NOT NULL,
    feature_key VARCHAR(128) NOT NULL,
    description VARCHAR(255) NOT NULL,
    measurement_unit VARCHAR(32) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_feature_definition_key (feature_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE plan_entitlement (
    plan_id CHAR(36) NOT NULL,
    feature_id CHAR(36) NOT NULL,
    is_enabled TINYINT(1) NOT NULL DEFAULT 0,
    soft_limit BIGINT UNSIGNED NULL,
    hard_limit BIGINT UNSIGNED NULL,
    configuration_json JSON NULL,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (plan_id, feature_id),
    CONSTRAINT fk_entitlement_plan FOREIGN KEY (plan_id) REFERENCES plan_definition (id),
    CONSTRAINT fk_entitlement_feature FOREIGN KEY (feature_id) REFERENCES feature_definition (id),
    CONSTRAINT ck_entitlement_limits CHECK (hard_limit IS NULL OR soft_limit IS NULL OR hard_limit >= soft_limit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tenant_subscription (
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
    UNIQUE KEY uq_subscription_tenant (tenant_id),
    UNIQUE KEY uq_subscription_provider_ref (provider, provider_subscription_ref),
    CONSTRAINT fk_subscription_tenant FOREIGN KEY (tenant_id) REFERENCES tenant (id),
    CONSTRAINT fk_subscription_plan FOREIGN KEY (plan_id) REFERENCES plan_definition (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE usage_counter (
    tenant_id CHAR(36) NOT NULL,
    feature_id CHAR(36) NOT NULL,
    period_key VARCHAR(32) NOT NULL,
    quantity BIGINT UNSIGNED NOT NULL DEFAULT 0,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (tenant_id, feature_id, period_key),
    CONSTRAINT fk_usage_tenant FOREIGN KEY (tenant_id) REFERENCES tenant (id),
    CONSTRAINT fk_usage_feature FOREIGN KEY (feature_id) REFERENCES feature_definition (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE provisioning_operation (
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
    UNIQUE KEY uq_provisioning_idempotency (idempotency_key),
    KEY ix_provisioning_tenant_status (tenant_id, status),
    CONSTRAINT fk_provisioning_tenant FOREIGN KEY (tenant_id) REFERENCES tenant (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
