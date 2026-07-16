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
