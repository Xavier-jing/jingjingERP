CREATE TABLE IF NOT EXISTS jsh_factory_sales_config (
 tenant_id BIGINT PRIMARY KEY, reviewer_id BIGINT NOT NULL, updated_at DATETIME NOT NULL);
CREATE TABLE IF NOT EXISTS jsh_factory_sales_order (
 head_id BIGINT PRIMARY KEY, tenant_id BIGINT NOT NULL, delivery_date VARCHAR(10) NOT NULL,
 requirements TEXT NOT NULL, workflow_status VARCHAR(16) NOT NULL DEFAULT 'draft',
 version INT NOT NULL DEFAULT 1, lines_json MEDIUMTEXT NOT NULL,
 created_by BIGINT NOT NULL, updated_at DATETIME NOT NULL, INDEX(tenant_id,workflow_status));
CREATE TABLE IF NOT EXISTS jsh_factory_sales_history (
 id BIGINT PRIMARY KEY AUTO_INCREMENT, tenant_id BIGINT NOT NULL, head_id BIGINT NOT NULL,
 action VARCHAR(30) NOT NULL, actor_id BIGINT NOT NULL, actor_name VARCHAR(100) NOT NULL,
 comment TEXT NOT NULL, created_at DATETIME NOT NULL, INDEX(tenant_id,head_id));
UPDATE jsh_function SET component='/factory/SalesOrderList' WHERE url='/bill/sale_order';
