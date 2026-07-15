-- Synthetic, stable local-development reference data.
INSERT INTO plan_definition (id, plan_key, display_name, status) VALUES
    ('10000000-0000-4000-8000-000000000001', 'launch', 'Launch', 'active'),
    ('10000000-0000-4000-8000-000000000002', 'growth', 'Growth', 'active'),
    ('10000000-0000-4000-8000-000000000003', 'scale', 'Scale', 'active')
ON DUPLICATE KEY UPDATE display_name = VALUES(display_name), status = VALUES(status);

INSERT INTO feature_definition (id, feature_key, description, measurement_unit) VALUES
    ('20000000-0000-4000-8000-000000000001', 'crm.users', 'Active CRM users', 'users'),
    ('20000000-0000-4000-8000-000000000002', 'marketing.contacts', 'Billable marketing contacts', 'contacts'),
    ('20000000-0000-4000-8000-000000000003', 'marketing.email_sends', 'Marketing email sends per period', 'sends'),
    ('20000000-0000-4000-8000-000000000004', 'automation.workflows', 'Active automation workflows', 'workflows'),
    ('20000000-0000-4000-8000-000000000005', 'storage.bytes', 'Tenant-managed file storage', 'bytes')
ON DUPLICATE KEY UPDATE description = VALUES(description), measurement_unit = VALUES(measurement_unit);
