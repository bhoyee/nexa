-- Synthetic, stable local-development reference data.
INSERT INTO nexa_plan_definition (id, plan_key, display_name, status) VALUES
    ('10000000-0000-4000-8000-000000000001', 'launch', 'Launch', 'active'),
    ('10000000-0000-4000-8000-000000000002', 'growth', 'Growth', 'active'),
    ('10000000-0000-4000-8000-000000000003', 'scale', 'Scale', 'active')
ON DUPLICATE KEY UPDATE display_name = VALUES(display_name), status = VALUES(status);

INSERT INTO nexa_service_definition (id, service_key, display_name, description, measurement_unit, status) VALUES
    ('20000000-0000-4000-8000-000000000001', 'crm', 'CRM', 'Customer relationship and sales records', 'users', 'active'),
    ('20000000-0000-4000-8000-000000000002', 'marketing.contacts', 'Marketing Contacts', 'Billable marketing contacts', 'contacts', 'active'),
    ('20000000-0000-4000-8000-000000000003', 'marketing.email', 'Marketing Email', 'Marketing email delivery', 'sends', 'active'),
    ('20000000-0000-4000-8000-000000000004', 'automation', 'Automation', 'Workflow automation execution', 'workflows', 'active'),
    ('20000000-0000-4000-8000-000000000005', 'storage', 'Storage', 'Tenant-managed file storage', 'bytes', 'active')
ON DUPLICATE KEY UPDATE display_name = VALUES(display_name), description = VALUES(description), measurement_unit = VALUES(measurement_unit), status = VALUES(status);

-- Signup copies these catalog limits into nexa_tenant_service. Stable IDs make
-- the seed idempotent across Docker, XAMPP, WampServer and CI databases.
INSERT INTO nexa_plan_service
    (plan_id, service_id, is_enabled, soft_limit, hard_limit, configuration_json)
VALUES
    ('10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 1, 4, 5, JSON_OBJECT()),
    ('10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000002', 1, 800, 1000, JSON_OBJECT()),
    ('10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000003', 1, 8000, 10000, JSON_OBJECT('period', 'month')),
    ('10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000004', 1, 20, 25, JSON_OBJECT()),
    ('10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000005', 1, 4294967296, 5368709120, JSON_OBJECT()),
    ('10000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000001', 1, 20, 25, JSON_OBJECT()),
    ('10000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000002', 1, 8000, 10000, JSON_OBJECT()),
    ('10000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000003', 1, 80000, 100000, JSON_OBJECT('period', 'month')),
    ('10000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000004', 1, 250, 300, JSON_OBJECT()),
    ('10000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000005', 1, 21474836480, 26843545600, JSON_OBJECT()),
    ('10000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000001', 1, 80, 100, JSON_OBJECT()),
    ('10000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000002', 1, 40000, 50000, JSON_OBJECT()),
    ('10000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000003', 1, 800000, 1000000, JSON_OBJECT('period', 'month')),
    ('10000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000004', 1, 800, 1000, JSON_OBJECT()),
    ('10000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000005', 1, 85899345920, 107374182400, JSON_OBJECT())
ON DUPLICATE KEY UPDATE
    is_enabled = VALUES(is_enabled),
    soft_limit = VALUES(soft_limit),
    hard_limit = VALUES(hard_limit),
    configuration_json = VALUES(configuration_json);
