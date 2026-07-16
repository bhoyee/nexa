-- Expand EspoCRM 9.1.9 for shared-schema tenancy.
-- This migration adds columns, backfills the current installation and qualifies tenant-local unique indexes.
-- tenant_id remains nullable until TenantContext and automatic ORM scope are deployed and verified.
-- A temporary legacy-local default keeps current single-tenant code scoped during the transition.
-- AUTO_INCREMENT sequence indexes remain global because MariaDB requires the sequence column to lead its key.

INSERT INTO nexa_tenant (id, slug, display_name, status) VALUES
    ('00000000-0000-4000-8000-000000000001', 'legacy-local', 'Legacy Local Tenant', 'active')
ON DUPLICATE KEY UPDATE display_name = VALUES(display_name), status = VALUES(status);

-- Platform-global allowlist: address_country, extension, system_data.
-- Every other Espo physical table is explicitly altered below.

ALTER TABLE `account`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `account` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `account_contact`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `account_contact` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `account_document`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `account_document` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `account_portal_user`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `account_portal_user` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `account_target_list`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `account_target_list` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `action_history_record`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `action_history_record` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `app_log_record`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `app_log_record` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `app_secret`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `app_secret` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `array_value`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `array_value` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `attachment`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `attachment` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `authentication_provider`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `authentication_provider` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `auth_log_record`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `auth_log_record` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `auth_token`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `auth_token` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `autofollow`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `autofollow` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `call`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `call` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `call_contact`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `call_contact` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `call_lead`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `call_lead` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `call_user`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `call_user` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `campaign`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `campaign` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `campaign_log_record`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `campaign_log_record` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `campaign_target_list`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `campaign_target_list` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `campaign_target_list_excluding`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `campaign_target_list_excluding` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `campaign_tracking_url`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `campaign_tracking_url` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `case`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `case` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `case_contact`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `case_contact` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `case_knowledge_base_article`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `case_knowledge_base_article` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `contact`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `contact` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `contact_document`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `contact_document` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `contact_meeting`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `contact_meeting` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `contact_opportunity`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `contact_opportunity` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `contact_target_list`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `contact_target_list` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `currency`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `currency` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `dashboard_template`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `dashboard_template` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `document`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `document` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `document_folder`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `document_folder` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `document_folder_path`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `document_folder_path` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `document_lead`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `document_lead` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `document_opportunity`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `document_opportunity` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `email`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `email` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `email_account`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `email_account` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `email_address`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `email_address` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `email_email_account`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `email_email_account` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `email_email_address`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `email_email_address` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `email_filter`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `email_filter` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `email_folder`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `email_folder` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `email_inbound_email`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `email_inbound_email` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `email_queue_item`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `email_queue_item` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `email_template`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `email_template` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `email_template_category`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `email_template_category` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `email_template_category_path`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `email_template_category_path` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `email_user`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `email_user` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `entity_email_address`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `entity_email_address` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `entity_phone_number`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `entity_phone_number` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `entity_team`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `entity_team` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `entity_user`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `entity_user` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `export`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `export` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `external_account`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `external_account` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `group_email_folder`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `group_email_folder` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `group_email_folder_team`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `group_email_folder_team` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `import`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `import` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `import_entity`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `import_entity` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `import_error`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `import_error` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `inbound_email`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `inbound_email` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `inbound_email_team`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `inbound_email_team` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `integration`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `integration` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `job`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `job` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `kanban_order`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `kanban_order` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `knowledge_base_article`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `knowledge_base_article` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `knowledge_base_article_knowledge_base_category`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `knowledge_base_article_knowledge_base_category` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `knowledge_base_article_portal`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `knowledge_base_article_portal` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `knowledge_base_category`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `knowledge_base_category` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `knowledge_base_category_path`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `knowledge_base_category_path` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `layout_record`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `layout_record` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `layout_set`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `layout_set` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `lead`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `lead` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `lead_capture`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `lead_capture` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `lead_capture_log_record`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `lead_capture_log_record` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `lead_meeting`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `lead_meeting` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `lead_target_list`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `lead_target_list` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `mass_action`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `mass_action` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `mass_email`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `mass_email` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `mass_email_target_list`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `mass_email_target_list` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `mass_email_target_list_excluding`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `mass_email_target_list_excluding` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `meeting`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `meeting` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `meeting_user`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `meeting_user` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `next_number`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `next_number` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `note`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `note` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `note_portal`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `note_portal` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `note_team`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `note_team` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `note_user`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `note_user` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `notification`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `notification` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `opportunity`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `opportunity` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `o_auth_account`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `o_auth_account` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `o_auth_provider`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `o_auth_provider` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `password_change_request`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `password_change_request` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `phone_number`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `phone_number` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `portal`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `portal` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `portal_portal_role`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `portal_portal_role` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `portal_role`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `portal_role` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `portal_role_user`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `portal_role_user` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `portal_user`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `portal_user` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `preferences`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `preferences` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `reminder`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `reminder` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `role`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `role` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `role_team`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `role_team` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `role_user`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `role_user` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `scheduled_job`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `scheduled_job` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `scheduled_job_log_record`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `scheduled_job_log_record` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `sms`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `sms` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `sms_phone_number`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `sms_phone_number` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `star_subscription`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `star_subscription` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `stream_subscription`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `stream_subscription` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `target`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `target` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `target_list`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `target_list` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `target_list_category`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `target_list_category` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `target_list_category_path`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `target_list_category_path` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `target_list_user`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `target_list_user` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `task`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `task` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `team`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `team` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `team_user`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `team_user` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `template`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `template` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `two_factor_code`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `two_factor_code` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `unique_id`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `unique_id` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `user`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `user` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `user_data`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `user_data` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `user_reaction`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `user_reaction` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `user_working_time_range`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `user_working_time_range` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `webhook`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `webhook` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `webhook_event_queue_item`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `webhook_event_queue_item` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `webhook_queue_item`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `webhook_queue_item` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `working_time_calendar`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `working_time_calendar` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `working_time_calendar_working_time_range`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `working_time_calendar_working_time_range` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

ALTER TABLE `working_time_range`
    ADD COLUMN `tenant_id` CHAR(36) NULL DEFAULT '00000000-0000-4000-8000-000000000001',
    ADD COLUMN `service_id` CHAR(36) NULL,
    ADD KEY `ix_nexa_tenant_service` (`tenant_id`, `service_id`);
UPDATE `working_time_range` SET `tenant_id` = '00000000-0000-4000-8000-000000000001' WHERE `tenant_id` IS NULL;

-- Tenant-qualify non-primary unique indexes except required global AUTO_INCREMENT sequences.
ALTER TABLE `account`
    DROP INDEX `UNIQ_CREATED_AT_ID`,
    ADD UNIQUE KEY `UNIQ_CREATED_AT_ID` (`tenant_id`, `created_at`, `id`);

ALTER TABLE `account_contact`
    DROP INDEX `UNIQ_ACCOUNT_ID_CONTACT_ID`,
    ADD UNIQUE KEY `UNIQ_ACCOUNT_ID_CONTACT_ID` (`tenant_id`, `account_id`, `contact_id`);

ALTER TABLE `account_document`
    DROP INDEX `UNIQ_ACCOUNT_ID_DOCUMENT_ID`,
    ADD UNIQUE KEY `UNIQ_ACCOUNT_ID_DOCUMENT_ID` (`tenant_id`, `account_id`, `document_id`);

ALTER TABLE `account_portal_user`
    DROP INDEX `UNIQ_USER_ID_ACCOUNT_ID`,
    ADD UNIQUE KEY `UNIQ_USER_ID_ACCOUNT_ID` (`tenant_id`, `user_id`, `account_id`);

ALTER TABLE `account_target_list`
    DROP INDEX `UNIQ_ACCOUNT_ID_TARGET_LIST_ID`,
    ADD UNIQUE KEY `UNIQ_ACCOUNT_ID_TARGET_LIST_ID` (`tenant_id`, `account_id`, `target_list_id`);

ALTER TABLE `app_secret`
    DROP INDEX `UNIQ_NAME_DELETE_ID`,
    ADD UNIQUE KEY `UNIQ_NAME_DELETE_ID` (`tenant_id`, `name`, `delete_id`);

ALTER TABLE `call_contact`
    DROP INDEX `UNIQ_CALL_ID_CONTACT_ID`,
    ADD UNIQUE KEY `UNIQ_CALL_ID_CONTACT_ID` (`tenant_id`, `call_id`, `contact_id`);

ALTER TABLE `call_lead`
    DROP INDEX `UNIQ_CALL_ID_LEAD_ID`,
    ADD UNIQUE KEY `UNIQ_CALL_ID_LEAD_ID` (`tenant_id`, `call_id`, `lead_id`);

ALTER TABLE `call_user`
    DROP INDEX `UNIQ_USER_ID_CALL_ID`,
    ADD UNIQUE KEY `UNIQ_USER_ID_CALL_ID` (`tenant_id`, `user_id`, `call_id`);

ALTER TABLE `campaign_target_list`
    DROP INDEX `UNIQ_CAMPAIGN_ID_TARGET_LIST_ID`,
    ADD UNIQUE KEY `UNIQ_CAMPAIGN_ID_TARGET_LIST_ID` (`tenant_id`, `campaign_id`, `target_list_id`);

ALTER TABLE `campaign_target_list_excluding`
    DROP INDEX `UNIQ_CAMPAIGN_ID_TARGET_LIST_ID`,
    ADD UNIQUE KEY `UNIQ_CAMPAIGN_ID_TARGET_LIST_ID` (`tenant_id`, `campaign_id`, `target_list_id`);

ALTER TABLE `case_contact`
    DROP INDEX `UNIQ_CASE_ID_CONTACT_ID`,
    ADD UNIQUE KEY `UNIQ_CASE_ID_CONTACT_ID` (`tenant_id`, `case_id`, `contact_id`);

ALTER TABLE `case_knowledge_base_article`
    DROP INDEX `UNIQ_CASE_ID_KNOWLEDGE_BASE_ARTICLE_ID`,
    ADD UNIQUE KEY `UNIQ_CASE_ID_KNOWLEDGE_BASE_ARTICLE_ID` (`tenant_id`, `case_id`, `knowledge_base_article_id`);

ALTER TABLE `contact`
    DROP INDEX `UNIQ_CREATED_AT_ID`,
    ADD UNIQUE KEY `UNIQ_CREATED_AT_ID` (`tenant_id`, `created_at`, `id`);

ALTER TABLE `contact_document`
    DROP INDEX `UNIQ_CONTACT_ID_DOCUMENT_ID`,
    ADD UNIQUE KEY `UNIQ_CONTACT_ID_DOCUMENT_ID` (`tenant_id`, `contact_id`, `document_id`);

ALTER TABLE `contact_meeting`
    DROP INDEX `UNIQ_CONTACT_ID_MEETING_ID`,
    ADD UNIQUE KEY `UNIQ_CONTACT_ID_MEETING_ID` (`tenant_id`, `contact_id`, `meeting_id`);

ALTER TABLE `contact_opportunity`
    DROP INDEX `UNIQ_CONTACT_ID_OPPORTUNITY_ID`,
    ADD UNIQUE KEY `UNIQ_CONTACT_ID_OPPORTUNITY_ID` (`tenant_id`, `contact_id`, `opportunity_id`);

ALTER TABLE `contact_target_list`
    DROP INDEX `UNIQ_CONTACT_ID_TARGET_LIST_ID`,
    ADD UNIQUE KEY `UNIQ_CONTACT_ID_TARGET_LIST_ID` (`tenant_id`, `contact_id`, `target_list_id`);

ALTER TABLE `document_lead`
    DROP INDEX `UNIQ_DOCUMENT_ID_LEAD_ID`,
    ADD UNIQUE KEY `UNIQ_DOCUMENT_ID_LEAD_ID` (`tenant_id`, `document_id`, `lead_id`);

ALTER TABLE `document_opportunity`
    DROP INDEX `UNIQ_DOCUMENT_ID_OPPORTUNITY_ID`,
    ADD UNIQUE KEY `UNIQ_DOCUMENT_ID_OPPORTUNITY_ID` (`tenant_id`, `document_id`, `opportunity_id`);

ALTER TABLE `email_email_account`
    DROP INDEX `UNIQ_EMAIL_ID_EMAIL_ACCOUNT_ID`,
    ADD UNIQUE KEY `UNIQ_EMAIL_ID_EMAIL_ACCOUNT_ID` (`tenant_id`, `email_id`, `email_account_id`);

ALTER TABLE `email_email_address`
    DROP INDEX `UNIQ_EMAIL_ID_EMAIL_ADDRESS_ID_ADDRESS_TYPE`,
    ADD UNIQUE KEY `UNIQ_EMAIL_ID_EMAIL_ADDRESS_ID_ADDRESS_TYPE` (`tenant_id`, `email_id`, `email_address_id`, `address_type`);

ALTER TABLE `email_inbound_email`
    DROP INDEX `UNIQ_EMAIL_ID_INBOUND_EMAIL_ID`,
    ADD UNIQUE KEY `UNIQ_EMAIL_ID_INBOUND_EMAIL_ID` (`tenant_id`, `email_id`, `inbound_email_id`);

ALTER TABLE `email_user`
    DROP INDEX `UNIQ_EMAIL_ID_USER_ID`,
    ADD UNIQUE KEY `UNIQ_EMAIL_ID_USER_ID` (`tenant_id`, `email_id`, `user_id`);

ALTER TABLE `entity_email_address`
    DROP INDEX `UNIQ_ENTITY_ID_EMAIL_ADDRESS_ID_ENTITY_TYPE`,
    ADD UNIQUE KEY `UNIQ_ENTITY_ID_EMAIL_ADDRESS_ID_ENTITY_TYPE` (`tenant_id`, `entity_id`, `email_address_id`, `entity_type`);

ALTER TABLE `entity_phone_number`
    DROP INDEX `UNIQ_ENTITY_ID_PHONE_NUMBER_ID_ENTITY_TYPE`,
    ADD UNIQUE KEY `UNIQ_ENTITY_ID_PHONE_NUMBER_ID_ENTITY_TYPE` (`tenant_id`, `entity_id`, `phone_number_id`, `entity_type`);

ALTER TABLE `entity_team`
    DROP INDEX `UNIQ_ENTITY_ID_TEAM_ID_ENTITY_TYPE`,
    ADD UNIQUE KEY `UNIQ_ENTITY_ID_TEAM_ID_ENTITY_TYPE` (`tenant_id`, `entity_id`, `team_id`, `entity_type`);

ALTER TABLE `entity_user`
    DROP INDEX `UNIQ_ENTITY_ID_USER_ID_ENTITY_TYPE`,
    ADD UNIQUE KEY `UNIQ_ENTITY_ID_USER_ID_ENTITY_TYPE` (`tenant_id`, `entity_id`, `user_id`, `entity_type`);

ALTER TABLE `group_email_folder_team`
    DROP INDEX `UNIQ_GROUP_EMAIL_FOLDER_ID_TEAM_ID`,
    ADD UNIQUE KEY `UNIQ_GROUP_EMAIL_FOLDER_ID_TEAM_ID` (`tenant_id`, `group_email_folder_id`, `team_id`);

ALTER TABLE `inbound_email_team`
    DROP INDEX `UNIQ_INBOUND_EMAIL_ID_TEAM_ID`,
    ADD UNIQUE KEY `UNIQ_INBOUND_EMAIL_ID_TEAM_ID` (`tenant_id`, `inbound_email_id`, `team_id`);

ALTER TABLE `knowledge_base_article_knowledge_base_category`
    DROP INDEX `UNIQ_KNOWLEDGE_BASE_ARTICLE_ID_KNOWLEDGE_BASE_CATEGORY_ID`,
    ADD UNIQUE KEY `UNIQ_KNOWLEDGE_BASE_ARTICLE_ID_KNOWLEDGE_BASE_CATEGORY_ID` (`tenant_id`, `knowledge_base_article_id`, `knowledge_base_category_id`);

ALTER TABLE `knowledge_base_article_portal`
    DROP INDEX `UNIQ_PORTAL_ID_KNOWLEDGE_BASE_ARTICLE_ID`,
    ADD UNIQUE KEY `UNIQ_PORTAL_ID_KNOWLEDGE_BASE_ARTICLE_ID` (`tenant_id`, `portal_id`, `knowledge_base_article_id`);

ALTER TABLE `lead`
    DROP INDEX `UNIQ_CREATED_AT_ID`,
    ADD UNIQUE KEY `UNIQ_CREATED_AT_ID` (`tenant_id`, `created_at`, `id`);

ALTER TABLE `lead_meeting`
    DROP INDEX `UNIQ_LEAD_ID_MEETING_ID`,
    ADD UNIQUE KEY `UNIQ_LEAD_ID_MEETING_ID` (`tenant_id`, `lead_id`, `meeting_id`);

ALTER TABLE `lead_target_list`
    DROP INDEX `UNIQ_LEAD_ID_TARGET_LIST_ID`,
    ADD UNIQUE KEY `UNIQ_LEAD_ID_TARGET_LIST_ID` (`tenant_id`, `lead_id`, `target_list_id`);

ALTER TABLE `mass_email_target_list`
    DROP INDEX `UNIQ_MASS_EMAIL_ID_TARGET_LIST_ID`,
    ADD UNIQUE KEY `UNIQ_MASS_EMAIL_ID_TARGET_LIST_ID` (`tenant_id`, `mass_email_id`, `target_list_id`);

ALTER TABLE `mass_email_target_list_excluding`
    DROP INDEX `UNIQ_MASS_EMAIL_ID_TARGET_LIST_ID`,
    ADD UNIQUE KEY `UNIQ_MASS_EMAIL_ID_TARGET_LIST_ID` (`tenant_id`, `mass_email_id`, `target_list_id`);

ALTER TABLE `meeting_user`
    DROP INDEX `UNIQ_USER_ID_MEETING_ID`,
    ADD UNIQUE KEY `UNIQ_USER_ID_MEETING_ID` (`tenant_id`, `user_id`, `meeting_id`);

ALTER TABLE `note_portal`
    DROP INDEX `UNIQ_NOTE_ID_PORTAL_ID`,
    ADD UNIQUE KEY `UNIQ_NOTE_ID_PORTAL_ID` (`tenant_id`, `note_id`, `portal_id`);

ALTER TABLE `note_team`
    DROP INDEX `UNIQ_NOTE_ID_TEAM_ID`,
    ADD UNIQUE KEY `UNIQ_NOTE_ID_TEAM_ID` (`tenant_id`, `note_id`, `team_id`);

ALTER TABLE `note_user`
    DROP INDEX `UNIQ_NOTE_ID_USER_ID`,
    ADD UNIQUE KEY `UNIQ_NOTE_ID_USER_ID` (`tenant_id`, `note_id`, `user_id`);

ALTER TABLE `opportunity`
    DROP INDEX `UNIQ_CREATED_AT_ID`,
    ADD UNIQUE KEY `UNIQ_CREATED_AT_ID` (`tenant_id`, `created_at`, `id`);

ALTER TABLE `portal_portal_role`
    DROP INDEX `UNIQ_PORTAL_ID_PORTAL_ROLE_ID`,
    ADD UNIQUE KEY `UNIQ_PORTAL_ID_PORTAL_ROLE_ID` (`tenant_id`, `portal_id`, `portal_role_id`);

ALTER TABLE `portal_role_user`
    DROP INDEX `UNIQ_PORTAL_ROLE_ID_USER_ID`,
    ADD UNIQUE KEY `UNIQ_PORTAL_ROLE_ID_USER_ID` (`tenant_id`, `portal_role_id`, `user_id`);

ALTER TABLE `portal_user`
    DROP INDEX `UNIQ_PORTAL_ID_USER_ID`,
    ADD UNIQUE KEY `UNIQ_PORTAL_ID_USER_ID` (`tenant_id`, `portal_id`, `user_id`);

ALTER TABLE `role_team`
    DROP INDEX `UNIQ_ROLE_ID_TEAM_ID`,
    ADD UNIQUE KEY `UNIQ_ROLE_ID_TEAM_ID` (`tenant_id`, `role_id`, `team_id`);

ALTER TABLE `role_user`
    DROP INDEX `UNIQ_ROLE_ID_USER_ID`,
    ADD UNIQUE KEY `UNIQ_ROLE_ID_USER_ID` (`tenant_id`, `role_id`, `user_id`);

ALTER TABLE `sms_phone_number`
    DROP INDEX `UNIQ_SMS_ID_PHONE_NUMBER_ID_ADDRESS_TYPE`,
    ADD UNIQUE KEY `UNIQ_SMS_ID_PHONE_NUMBER_ID_ADDRESS_TYPE` (`tenant_id`, `sms_id`, `phone_number_id`, `address_type`);

ALTER TABLE `star_subscription`
    DROP INDEX `UNIQ_USER_ENTITY`,
    ADD UNIQUE KEY `UNIQ_USER_ENTITY` (`tenant_id`, `user_id`, `entity_id`, `entity_type`);

ALTER TABLE `target_list_user`
    DROP INDEX `UNIQ_USER_ID_TARGET_LIST_ID`,
    ADD UNIQUE KEY `UNIQ_USER_ID_TARGET_LIST_ID` (`tenant_id`, `user_id`, `target_list_id`);

ALTER TABLE `team_user`
    DROP INDEX `UNIQ_TEAM_ID_USER_ID`,
    ADD UNIQUE KEY `UNIQ_TEAM_ID_USER_ID` (`tenant_id`, `team_id`, `user_id`);

ALTER TABLE `user`
    DROP INDEX `UNIQ_USER_NAME_DELETE_ID`,
    ADD UNIQUE KEY `UNIQ_USER_NAME_DELETE_ID` (`tenant_id`, `user_name`, `delete_id`);

ALTER TABLE `user_reaction`
    DROP INDEX `UNIQ_PARENT_USER_TYPE`,
    ADD UNIQUE KEY `UNIQ_PARENT_USER_TYPE` (`tenant_id`, `parent_id`, `parent_type`, `user_id`, `type`);

ALTER TABLE `user_working_time_range`
    DROP INDEX `UNIQ_USER_ID_WORKING_TIME_RANGE_ID`,
    ADD UNIQUE KEY `UNIQ_USER_ID_WORKING_TIME_RANGE_ID` (`tenant_id`, `user_id`, `working_time_range_id`);

ALTER TABLE `working_time_calendar_working_time_range`
    DROP INDEX `UNIQ_WORKING_TIME_CALENDAR_ID_WORKING_TIME_RANGE_ID`,
    ADD UNIQUE KEY `UNIQ_WORKING_TIME_CALENDAR_ID_WORKING_TIME_RANGE_ID` (`tenant_id`, `working_time_calendar_id`, `working_time_range_id`);

