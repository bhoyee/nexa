-- Allow the same login identity to exist independently in multiple tenants.
ALTER TABLE `user`
    DROP INDEX `UNIQ_USER_NAME_DELETE_ID`,
    ADD UNIQUE INDEX `UNIQ_USER_TENANT_NAME_DELETE_ID` (`tenant_id`, `user_name`, `delete_id`);